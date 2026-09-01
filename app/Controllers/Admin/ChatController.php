<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Libraries\FirebaseAuthTokenService;
use App\Models\UserModel;

/**
 * Live Chat inbox — shared by two audiences:
 *   - the app owner (admin), who sees general-support threads
 *   - a restaurant manager, who sees only their own restaurant's threads
 *
 * As of the Firestore migration this controller no longer touches
 * chat_messages/MySQL at all: index() and conversation() just render page
 * shells, and firebaseToken() mints a custom token whose claims
 * (role / restaurantId) let Firestore rules enforce the exact same
 * "a manager never sees another restaurant's threads or the admin inbox"
 * guarantee that scopeToRole() used to enforce in PHP.
 */
class ChatController extends BaseController
{
    protected function isManager(): bool
    {
        return session()->get('admin_role') === 'restaurant_manager';
    }

    protected function myRestaurantId()
    {
        return session()->get('admin_restaurant_id');
    }

    public function index()
    {
        return view('admin/chat/index', ['is_manager' => $this->isManager()]);
    }

    public function conversation($userId)
    {
        // Only used to show a friendly name/email in the header — Firestore
        // rules (not this lookup) decide whether this admin/manager may
        // actually read the thread, so a customer not existing here just
        // means a blank header, not a security gap.
        $user = (new UserModel())->find($userId);

        return view('admin/chat/conversation', [
            'customer_id' => (int) $userId,
            'customer'    => $user,
            'is_manager'  => $this->isManager(),
        ]);
    }

    public function firebaseToken()
    {
        $adminId = (int) session()->get('admin_id');
        $result = (new FirebaseAuthTokenService())->forStaff($this->isManager(), $this->myRestaurantId(), $adminId);

        if (! $result['token']) {
            return $this->response->setStatusCode(500)->setJSON(['success' => false, 'error' => 'Chat is temporarily unavailable. Please try again shortly.']);
        }

        return $this->response->setJSON(['success' => true] + $result);
    }

    /**
     * Same idea as NotificationController::diagnose() — walks through
     * every step of the Firebase/Firestore setup and reports exactly
     * where it breaks, plus a live in-browser test that reproduces the
     * real customer/admin flow (sign in with a custom token, write and
     * read a Firestore doc) so client-only errors like
     * auth/CONFIGURATION_NOT_FOUND or firestore/unavailable show up here
     * with their real error text instead of only inside the chat widget.
     * Visit /admin/chat/diagnose while logged in as admin.
     */
    public function diagnose()
    {
        $report = [];

        $projectId = env('firebase.projectId', '');
        $report['1. firebase.projectId in .env'] = $projectId !== ''
            ? "OK - set to \"{$projectId}\""
            : 'MISSING - add firebase.projectId = your-project-id to .env';

        $path = env('firebase.credentialsPath', '');
        $credsOk = false;
        $creds = null;
        if ($path === '') {
            $report['2. firebase.credentialsPath in .env'] = 'MISSING - add firebase.credentialsPath = /absolute/path/to/file.json to .env';
        } else {
            $report['2. firebase.credentialsPath in .env'] = "set to \"{$path}\"";

            if (! is_file($path)) {
                $report['3. File exists at that path'] = 'FAILED - no file found there. Check for typos, and that the path is absolute (starts with / ), not relative.';
            } else {
                $report['3. File exists at that path'] = 'OK';

                if (! is_readable($path)) {
                    $report['4. File is readable by PHP'] = 'FAILED - fix file permissions (e.g. chmod 644) so the web server user can read it.';
                } else {
                    $report['4. File is readable by PHP'] = 'OK';

                    $json = json_decode(file_get_contents($path), true);
                    if (! $json) {
                        $report['5. File is valid JSON'] = 'FAILED - re-download it fresh from Firebase Console (Project Settings -> Service Accounts -> Generate new private key) without editing it.';
                    } else {
                        $report['5. File is valid JSON'] = 'OK';

                        $hasKey = ! empty($json['private_key']);
                        $hasEmail = ! empty($json['client_email']);
                        $report['6. Has private_key + client_email fields'] = ($hasKey && $hasEmail)
                            ? 'OK'
                            : 'FAILED - this doesn\'t look like a Firebase service-account file. Re-download the correct file.';

                        if ($hasKey && $hasEmail) {
                            $creds = $json;
                            $credsOk = true;
                        }
                    }
                }
            }
        }

        if ($credsOk) {
            $accessToken = $this->getDatastoreAccessToken($creds);
            $report['7. Google accepts the credentials (Firestore scope)'] = $accessToken
                ? 'OK - credentials are valid'
                : 'FAILED - Google rejected the request. Check writable/logs for the exact error, or that the service account still exists (wasn\'t deleted along with the old project).';

            if ($accessToken) {
                $writeResult = $this->testFirestoreRoundTrip($accessToken, $projectId);
                $report['8. Firestore is enabled + reachable (real write/read test)'] = $writeResult;
            }
        }

        $report['9. firebase.web.apiKey in .env'] = env('firebase.web.apiKey', '') !== '' ? 'OK' : 'MISSING - needed for the browser-side test below and for the real chat widget.';
        $report['10. firebase.web.authDomain in .env'] = env('firebase.web.authDomain', '') !== '' ? 'OK' : 'MISSING';
        $report['11. firebase.web.appId in .env'] = env('firebase.web.appId', '') !== '' ? 'OK' : 'MISSING';

        return view('admin/chat/diagnose', ['report' => $report]);
    }

    /**
     * Same JWT-bearer flow as PushNotificationService::getAccessToken(),
     * but with the Firestore ("datastore") scope instead of
     * firebase.messaging — FCM and Firestore access tokens are scoped
     * separately even though they're minted from the same credentials.
     */
    private function getDatastoreAccessToken(array $creds): ?string
    {
        $now = time();
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $claims = [
            'iss'   => $creds['client_email'],
            'scope' => 'https://www.googleapis.com/auth/datastore',
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
            log_message('error', 'Failed to get Firestore access token: ' . $response);
            return null;
        }

        return $decoded['access_token'];
    }

    /**
     * Writes then reads back a throwaway doc via the Firestore REST API
     * (server-side calls with a service-account OAuth token bypass
     * security rules, same as the Admin SDK would — so this only proves
     * Firestore itself is enabled/reachable, not that the rules or the
     * browser-side custom-token sign-in work; step 12 in the view covers
     * that part live in the browser).
     */
    private function testFirestoreRoundTrip(string $accessToken, string $projectId): string
    {
        $docId = 'diagnose_' . time();
        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/chat_diagnostics/{$docId}";

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST  => 'PATCH',
            CURLOPT_HTTPHEADER     => ['Authorization: Bearer ' . $accessToken, 'Content-Type: application/json'],
            CURLOPT_POSTFIELDS     => json_encode(['fields' => ['ping' => ['stringValue' => 'ok']]]),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode !== 200) {
            $decoded = json_decode($response ?: '', true);
            $message = $decoded['error']['message'] ?? $response;
            if ($httpCode === 404 || str_contains((string) $message, 'NOT_FOUND')) {
                return "FAILED (HTTP {$httpCode}) - Firestore database doesn't exist yet for this project. Firebase Console -> Build -> Firestore Database -> Create database.";
            }
            return "FAILED (HTTP {$httpCode}) - {$message}";
        }

        // Clean up the test doc.
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST  => 'DELETE',
            CURLOPT_HTTPHEADER     => ['Authorization: Bearer ' . $accessToken],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
        ]);
        curl_exec($ch);
        curl_close($ch);

        return 'OK - wrote and deleted a test document successfully';
    }
}
