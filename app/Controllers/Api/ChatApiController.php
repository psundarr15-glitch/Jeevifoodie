<?php

namespace App\Controllers\Api;

use App\Libraries\FirebaseAuthTokenService;

/**
 * Mobile-app counterpart of Customer\ChatController — same Firestore
 * custom-token approach, just authenticated via the API bearer token
 * instead of a session.
 */
class ChatApiController extends BaseApiController
{
    public function firebaseToken()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $restaurantId = $this->request->getGet('restaurant_id');
        $result = (new FirebaseAuthTokenService())->forCustomer((int) $user['id'], $restaurantId ? (int) $restaurantId : null);

        if (! $result['token']) {
            return $this->fail('Chat is temporarily unavailable. Please try again shortly.', 500);
        }

        return $this->ok($result);
    }
}
