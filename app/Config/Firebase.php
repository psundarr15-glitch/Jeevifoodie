<?php

namespace Config;

use CodeIgniter\Config\BaseConfig;

/**
 * Firebase *web app* config values (Firebase Console → Project Settings →
 * General → Your apps → Web app). Safe to ship to the browser — Firestore
 * access is actually gated by the custom-token claims + firestore.rules,
 * not by keeping this object secret.
 *
 * projectId reuses the same firebase.projectId key already set for push
 * notifications (PushNotificationService) — same project, no duplication.
 * The rest are new, web-app-specific values, added under the same
 * dot-notation .env style:
 *   firebase.web.apiKey
 *   firebase.web.authDomain
 *   firebase.web.storageBucket
 *   firebase.web.senderId
 *   firebase.web.appId
 */
class Firebase extends BaseConfig
{
    public string $apiKey            = '';
    public string $authDomain        = '';
    public string $projectId         = '';
    public string $storageBucket     = '';
    public string $messagingSenderId = '';
    public string $appId             = '';

    public function __construct()
    {
        parent::__construct();
        $this->apiKey            = env('firebase.web.apiKey', '');
        $this->authDomain        = env('firebase.web.authDomain', '');
        $this->projectId         = env('firebase.projectId', '');
        $this->storageBucket     = env('firebase.web.storageBucket', '');
        $this->messagingSenderId = env('firebase.web.senderId', '');
        $this->appId             = env('firebase.web.appId', '');
    }

    /** JSON-safe array for embedding straight into a <script> tag. */
    public function toJsConfig(): array
    {
        return [
            'apiKey'            => $this->apiKey,
            'authDomain'        => $this->authDomain,
            'projectId'         => $this->projectId,
            'storageBucket'     => $this->storageBucket,
            'messagingSenderId' => $this->messagingSenderId,
            'appId'             => $this->appId,
        ];
    }
}
