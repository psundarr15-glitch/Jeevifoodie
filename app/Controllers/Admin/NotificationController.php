<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Libraries\PushNotificationService;
use App\Models\SentNotificationModel;

class NotificationController extends BaseController
{
    public function index()
    {
        return view('admin/notifications/index');
    }

    public function send()
    {
        $title = trim((string) $this->request->getPost('title'));
        $body  = trim((string) $this->request->getPost('body'));

        if (! $title || ! $body) {
            return redirect()->to('/admin/notifications')->with('error', 'Title and message are both required.');
        }

        $imageUrl = null;
        $file = $this->request->getFile('image');
        if ($file && $file->isValid() && ! $file->hasMoved()) {
            $newName = $file->getRandomName();
            $file->move(FCPATH . 'assets/uploads/notifications', $newName);
            $imageUrl = base_url('assets/uploads/notifications/' . $newName);

            // FCM silently drops the notification.image field (falls back
            // to a plain text notification, with no error) unless the URL
            // is HTTPS. base_url() follows whatever scheme app.baseURL is
            // set to in .env, which on some hosts is still left as
            // http:// even though the site itself is reachable over
            // https - so force it here rather than depend on .env being
            // right. This does NOT help if app.baseURL points somewhere
            // that isn't publicly reachable at all (e.g. left as the
            // default http://localhost:8080/); check the confirmation
            // message below for the exact URL FCM was sent if the image
            // still doesn't show.
            $imageUrl = preg_replace('#^http://#i', 'https://', $imageUrl);
        }

        $result = (new PushNotificationService())->sendToTopicDebug('promotions', $title, $body, [], $imageUrl);

        if (! $result['success']) {
            return redirect()->to('/admin/notifications')->with(
                'error',
                'Could not send (HTTP ' . $result['httpCode'] . '): ' . $result['response']
            );
        }

        // Logged so the customer app's notification bell can show real
        // history instead of a stub. Never blocks/fails the send above.
        (new SentNotificationModel())->insert([
            'title'     => $title,
            'body'      => $body,
            'image_url' => $imageUrl,
        ]);

        $confirmation = 'Notification sent to all customers.';
        if ($imageUrl) {
            $confirmation .= ' Banner image URL sent to FCM: ' . $imageUrl
                . ' - open this link directly in a browser to confirm it loads (must be publicly reachable over HTTPS, or the banner will silently be dropped and only title/body will show).';
        }

        return redirect()->to('/admin/notifications')->with('success', $confirmation);
    }

    /**
     * Walks through every step of the Firebase setup and reports exactly
     * where it breaks, instead of the generic "could not send" message.
     * Visit /admin/notifications/diagnose while logged in as admin.
     */
    public function diagnose()
    {
        $report = [];

        $projectId = env('firebase.projectId', '');
        $report['1. firebase.projectId in .env'] = $projectId !== ''
            ? "OK - set to \"{$projectId}\""
            : 'MISSING - add firebase.projectId = your-project-id to .env';

        $path = env('firebase.credentialsPath', '');
        if ($path === '') {
            $report['2. firebase.credentialsPath in .env'] = 'MISSING - add firebase.credentialsPath = /absolute/path/to/file.json to .env';
        } else {
            $report['2. firebase.credentialsPath in .env'] = "set to \"{$path}\"";

            if (! is_file($path)) {
                $report['3. File exists at that path'] = 'FAILED - no file found there. Check for typos (.json not .josn), and that the path is absolute (starts with / ), not relative.';
            } else {
                $report['3. File exists at that path'] = 'OK';

                if (! is_readable($path)) {
                    $report['4. File is readable by PHP'] = 'FAILED - fix file permissions (e.g. chmod 644) so the web server user can read it.';
                } else {
                    $report['4. File is readable by PHP'] = 'OK';

                    $contents = file_get_contents($path);
                    $json = json_decode($contents, true);
                    if (! $json) {
                        $report['5. File is valid JSON'] = 'FAILED - the file content is not valid JSON. Re-download it fresh from Firebase Console (Project Settings -> Service Accounts -> Generate new private key) without editing it.';
                    } else {
                        $report['5. File is valid JSON'] = 'OK';

                        $hasKey = ! empty($json['private_key']);
                        $hasEmail = ! empty($json['client_email']);
                        $report['6. Has private_key + client_email fields'] = ($hasKey && $hasEmail)
                            ? 'OK'
                            : 'FAILED - this doesn\'t look like a Firebase service-account file (missing private_key/client_email). Re-download the correct file.';

                        if ($hasKey && $hasEmail) {
                            try {
                                $ref = new \ReflectionClass(PushNotificationService::class);
                                $method = $ref->getMethod('getAccessToken');
                                $method->setAccessible(true);
                                $token = $method->invoke(new PushNotificationService());
                                $report['7. Google accepts the credentials (OAuth2 token)'] = $token
                                    ? 'OK - credentials are valid'
                                    : 'FAILED - Google rejected the request. Check writable/logs/log-' . date('Y-m-d') . '.php for the exact error from Google (search for "Failed to get Firebase access token").';

                                if ($token) {
                                    $result = (new PushNotificationService())->sendToTopicDebug(
                                        'promotions',
                                        'Test notification',
                                        'This is a test from /admin/notifications/diagnose - safe to ignore.'
                                    );
                                    $report['8. Actual test send to FCM (real API call)'] = $result['success']
                                        ? 'OK - Google accepted the message (HTTP ' . $result['httpCode'] . '). If no device received it, no one has opened the app with this build yet to subscribe to the "promotions" topic - that\'s expected until customers update.'
                                        : 'FAILED (HTTP ' . $result['httpCode'] . ') - Google says: ' . $result['response'];
                                }
                            } catch (\Throwable $e) {
                                $report['7. Google accepts the credentials (OAuth2 token)'] = 'FAILED - ' . $e->getMessage();
                            }
                        }
                    }
                }
            }
        }

        return view('admin/notifications/diagnose', ['report' => $report]);
    }
}
