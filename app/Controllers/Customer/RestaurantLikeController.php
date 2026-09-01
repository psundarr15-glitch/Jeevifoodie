<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\RestaurantLikeModel;

class RestaurantLikeController extends BaseController
{
    /**
     * AJAX toggle: like if not already liked, unlike if already liked.
     * Returns the new liked state and the restaurant's total like count.
     */
    public function toggle($restaurantId)
    {
        $userId = session()->get('user_id');
        $likeModel = new RestaurantLikeModel();

        $existing = $likeModel->where('user_id', $userId)->where('restaurant_id', $restaurantId)->first();

        if ($existing) {
            $likeModel->delete($existing['id']);
            $liked = false;
        } else {
            $likeModel->insert(['user_id' => $userId, 'restaurant_id' => $restaurantId]);
            $liked = true;
        }

        $count = $likeModel->where('restaurant_id', $restaurantId)->countAllResults();

        return $this->response->setJSON(['success' => true, 'liked' => $liked, 'like_count' => $count]);
    }
}
