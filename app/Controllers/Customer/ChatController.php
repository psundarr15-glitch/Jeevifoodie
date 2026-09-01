<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Libraries\FirebaseAuthTokenService;

/**
 * Live Chat widget — now backed by Firestore for true real-time delivery
 * instead of short-polling. This controller no longer stores or serves
 * messages itself; it only mints a Firebase custom auth token (with the
 * customer's identity baked into the claims) so the browser can sign in
 * to Firestore and read/write the thread directly, guarded by
 * firestore/firestore.rules.
 */
class ChatController extends BaseController
{
    public function firebaseToken()
    {
        $userId = session()->get('user_id');
        if (! $userId) {
            return $this->response->setStatusCode(401)->setJSON(['error' => 'Please login to chat with us.']);
        }

        $restaurantId = $this->request->getGet('restaurant_id');
        $result = (new FirebaseAuthTokenService())->forCustomer((int) $userId, $restaurantId ? (int) $restaurantId : null);

        if (! $result['token']) {
            return $this->response->setStatusCode(500)->setJSON(['error' => 'Chat is temporarily unavailable. Please try again shortly.']);
        }

        return $this->response->setJSON(['success' => true] + $result);
    }
}
