<?php

namespace App\Libraries;

use App\Models\DeviceTokenModel;
use CodeIgniter\Config\Services;

/**
 * Sends push notifications via FCM's HTTP v1 API.
 *
 * Requires a Firebase service-account JSON key file. FCM's older
 * "legacy" server-key API (a single static key, no OAuth) was retired
 * by Google, so HTTP v1 - which needs a short-lived OAuth2 access
 * token minted from the service account - is the only option now.
 *
 * Config (.env):
 *   firebase.projectId           = your-firebase-project-id
 *   firebase.credentialsPath     = /absolute/path/to/service-account.json
 *
 * Get the service-account JSON from:
 *   Firebase Console -> Project Settings -> Service Accounts -> Generate new private key
 */
class PushNotificationService
{
    private ?string $accessToken = null;

    private function projectId(): string
    {
        return env('firebase.projectId', '');
    }

    private function credentialsPath(): string
    {
        return env('firebase.credentialsPath', '');
    }

    /**
     * Mints a short-lived OAuth2 access token from the service-account
     * JSON using the standard JWT bearer flow (RFC 7523) - no extra
     * composer package required, just curl + openssl (both are PHP
     * core / near-universal extensions).
     */
    private function getAccessToken(): ?string
    {
        if ($this->accessToken) {
            return $this->accessToken;
        }

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

        $now = time();
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $claims = [
            'iss'   => $creds['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud'   => 'https://oauth2.googleapis.com/token',
            'iat'   => $now,
            'exp'   => $now + 3600,
        ];

        $b64 = fn ($data) => rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
        $segments = $b64(json_encode($header)) . '.' . $b64(json_encode($claims));

        openssl_sign($segments, $signature, $creds['private_key'], 'SHA256');
        $jwt = $segments . '.' . $b64($signature);

        $ch = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
        ]);
        $response = curl_exec($ch);
        curl_close($ch);

        $decoded = json_decode($response ?: '', true);
        if (empty($decoded['access_token'])) {
            log_message('error', 'Failed to get Firebase access token: ' . $response);
            return null;
        }

        $this->accessToken = $decoded['access_token'];
        return $this->accessToken;
    }

    /**
     * Sends a notification to every device subscribed to the given FCM
     * topic - used for broadcast/promotional pushes ("50% off today!")
     * rather than order-status updates. The app subscribes every
     * logged-in customer's device to the "promotions" topic, so one
     * call here reaches everyone without looping over device_tokens.
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = [], ?string $imageUrl = null): bool
    {
        return $this->sendToTopicDebug($topic, $title, $body, $data, $imageUrl)['success'];
    }

    /**
     * Same as sendToTopic() but returns the full HTTP status + response
     * body instead of a plain bool, so the diagnose page can show
     * Google's exact rejection reason instead of a generic failure.
     */
    public function sendToTopicDebug(string $topic, string $title, string $body, array $data = [], ?string $imageUrl = null): array
    {
        $accessToken = $this->getAccessToken();
        $projectId = $this->projectId();
        if (! $accessToken || ! $projectId) {
            return ['success' => false, 'httpCode' => 0, 'response' => 'Firebase not configured (missing access token or project id).'];
        }

        $notification = ['title' => $title, 'body' => $body];
        if ($imageUrl) {
            // Shown as a big banner image both in the system tray
            // (background/terminated - handled automatically by
            // Android) and in-app (foreground - the app downloads and
            // renders it itself via flutter_local_notifications).
            $notification['image'] = $imageUrl;
        }

        $android = ['priority' => 'high'];
        if ($imageUrl) {
            $android['notification'] = ['image' => $imageUrl];
        }

        $payload = [
            'message' => [
                'topic'        => $topic,
                'notification' => $notification,
                // An empty PHP array json_encodes to `[]`, but FCM requires
                // `data` to be a JSON object (`{}`) even when empty -
                // force that with stdClass, same fix as the menu-items
                // empty-array bug in CustomerApiController.
                'data'         => empty($data) ? new \stdClass() : array_map('strval', $data),
                'android'      => $android,
            ],
        ];

        $ch = curl_init("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send");
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_HTTPHEADER     => [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($httpCode >= 400) {
            log_message('error', "FCM topic send failed ({$httpCode}): {$response}");
            return ['success' => false, 'httpCode' => $httpCode, 'response' => $response ?: $curlError];
        }
        if ($curlError) {
            return ['success' => false, 'httpCode' => 0, 'response' => 'curl error: ' . $curlError];
        }
        return ['success' => true, 'httpCode' => $httpCode, 'response' => $response];
    }

    /**
     * Sends a notification to every registered device for a user.
     * Silently no-ops (logs only) if Firebase isn't configured yet or
     * the user has no registered devices - this must never block or
     * fail the calling order-status-update request.
     */
    public function sendToUser(int $userId, string $title, string $body, array $data = []): void
    {
        $tokens = (new DeviceTokenModel())->tokensFor($userId);
        if (empty($tokens)) {
            return;
        }

        foreach ($tokens as $token) {
            $this->send($token, $title, $body, $data);
        }
    }

    private function send(string $token, string $title, string $body, array $data = []): void
    {
        $accessToken = $this->getAccessToken();
        $projectId = $this->projectId();
        if (! $accessToken || ! $projectId) {
            log_message('warning', 'Firebase not configured - skipping push notification.');
            return;
        }

        $payload = [
            'message' => [
                'token'        => $token,
                'notification' => ['title' => $title, 'body' => $body],
                'data'         => empty($data) ? new \stdClass() : array_map('strval', $data),
                'android'      => ['priority' => 'high'],
            ],
        ];

        $ch = curl_init("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send");
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_HTTPHEADER     => [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode >= 400) {
            log_message('error', "FCM send failed ({$httpCode}): {$response}");
        }
    }
}
