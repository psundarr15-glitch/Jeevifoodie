<?php

namespace App\Libraries;

use App\Models\OrderModel;
use App\Models\UserModel;

/**
 * Mints Firebase custom auth tokens so the customer app / admin panel can
 * sign in to Firestore directly and chat in real time (no more PHP
 * short-polling). This is the ONLY place chat authorization is decided —
 * Firestore rules just trust whatever claims land in the token here, so
 * every check that used to live in ChatController::scopeToRole() /
 * resolveRestaurantId() must be re-verified here before minting.
 *
 * Reuses the exact same service-account credentials already set up for
 * push notifications (see PushNotificationService) — same .env keys,
 * same "just curl + openssl, no extra composer package" approach:
 *   firebase.projectId       = your-firebase-project-id
 *   firebase.credentialsPath = /absolute/path/to/service-account.json
 *
 * A Firebase custom token is just a JWT signed with the service account's
 * private key, per Google's documented format:
 * https://firebase.google.com/docs/auth/admin/create-custom-tokens#create_custom_tokens_using_a_third-party_jwt_library
 */
class FirebaseAuthTokenService
{
    private function credentialsPath(): string
    {
        return env('firebase.credentialsPath', '');
    }

    private function loadCredentials(): ?array
    {
        $path = $this->credentialsPath();
        if (! $path || ! is_file($path)) {
            log_message('error', 'Firebase credentials file not found at: ' . $path);
            return null;
        }

        $creds = json_decode(file_get_contents($path), true);
        if (! $creds || empty($creds['private_key']) || empty($creds['client_email'])) {
            log_message('error', 'Firebase credentials file is malformed.');
            return null;
        }

        return $creds;
    }

    /**
     * Signs a Firebase custom auth token for $uid carrying $claims.
     * Returns null (and logs) if the credentials file is missing/bad,
     * same failure style as PushNotificationService::getAccessToken().
     */
    private function mint(string $uid, array $claims): ?string
    {
        $creds = $this->loadCredentials();
        if (! $creds) {
            return null;
        }

        $now = time();
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $payload = [
            'iss'    => $creds['client_email'],
            'sub'    => $creds['client_email'],
            'aud'    => 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
            'iat'    => $now,
            'exp'    => $now + 3600,
            'uid'    => $uid,
            'claims' => $claims,
        ];

        $b64 = fn ($data) => rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
        $segments = $b64(json_encode($header)) . '.' . $b64(json_encode($payload));

        openssl_sign($segments, $signature, $creds['private_key'], 'SHA256');

        return $segments . '.' . $b64($signature);
    }

    /**
     * Token for a logged-in customer (web session OR mobile API user).
     * $restaurantId, if given, is only honored (mirrors the old
     * resolveRestaurantId()) when the customer actually has an order from
     * that restaurant — otherwise they fall back to the general admin
     * thread. Also returns the deterministic threadId the client should
     * read/write, so Flutter/web JS never has to compute it themselves.
     */
    public function forCustomer(int $userId, ?int $restaurantId = null): array
    {
        $restaurantId = $this->resolveRestaurantId($userId, $restaurantId);

        $token = $this->mint((string) $userId, [
            'role'      => 'customer',
            'appUserId' => $userId,
        ]);

        $threadId = $restaurantId
            ? "restaurant_{$restaurantId}_user_{$userId}"
            : "admin_{$userId}";

        // Sent along so the client can denormalize name/email onto the
        // chat_threads doc when it creates it — the admin/manager inbox
        // list reads straight off that doc (no per-thread lookup), so
        // without this it just shows "Unknown customer" with no email.
        $user = (new UserModel())->find($userId);

        return [
            'token'          => $token,
            'thread_id'      => $threadId,
            'restaurant_id'  => $restaurantId,
            'customer_name'  => $user['name'] ?? null,
            'customer_email' => $user['email'] ?? null,
        ];
    }

    /**
     * Token for the admin/manager panel. UID is namespaced per role so an
     * admin's and a manager's Firebase users never collide.
     */
    public function forStaff(bool $isManager, ?int $restaurantId, int $adminId): array
    {
        if ($isManager) {
            $claims = [
                'role'         => 'manager',
                'restaurantId' => $restaurantId,
            ];
            $uid = "manager_{$restaurantId}_{$adminId}";
        } else {
            $claims = ['role' => 'admin'];
            $uid = "admin_{$adminId}";
        }

        return [
            'token'         => $this->mint($uid, $claims),
            'is_manager'    => $isManager,
            'restaurant_id' => $isManager ? $restaurantId : null,
        ];
    }

    private function resolveRestaurantId(int $userId, ?int $restaurantId): ?int
    {
        if (! $restaurantId) {
            return null;
        }
        $hasOrder = (new OrderModel())->where('user_id', $userId)->where('restaurant_id', $restaurantId)->first();
        return $hasOrder ? $restaurantId : null;
    }
}
