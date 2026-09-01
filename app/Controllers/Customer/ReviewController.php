<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\ReviewModel;
use App\Models\OrderModel;
use App\Models\RestaurantModel;
use App\Models\DeliveryPartnerModel;

class ReviewController extends BaseController
{
    /**
     * Customer submits a rating (1-5) for the restaurant, and optionally
     * a separate rating for the delivery partner who delivered the order
     * (if one was assigned). One review row per order. After saving, both
     * the restaurant's and the partner's aggregate rating/rating_count are
     * recomputed from all their reviews.
     */
    public function store()
    {
        $userId = session()->get('user_id');
        $orderId = $this->request->getPost('order_id');
        $rating = (int) $this->request->getPost('rating');
        $partnerRating = $this->request->getPost('partner_rating');
        $partnerRating = $partnerRating !== null && $partnerRating !== '' ? (int) $partnerRating : null;
        $comment = trim((string) $this->request->getPost('comment'));

        if ($rating < 1 || $rating > 5) {
            return redirect()->back()->with('error', 'Please select a restaurant rating between 1 and 5.');
        }
        if ($partnerRating !== null && ($partnerRating < 1 || $partnerRating > 5)) {
            return redirect()->back()->with('error', 'Please select a delivery partner rating between 1 and 5.');
        }

        $orderModel = new OrderModel();
        $order = $orderModel->find($orderId);

        if (! $order || $order['user_id'] != $userId) {
            return redirect()->to('/orders')->with('error', 'Order not found.');
        }
        if ($order['order_status'] !== 'delivered') {
            return redirect()->to('/orders')->with('error', 'You can only rate orders after they have been delivered.');
        }

        $reviewModel = new ReviewModel();
        $existing = $reviewModel->where('order_id', $orderId)->first();
        if ($existing) {
            return redirect()->to('/orders')->with('error', 'You already rated this order.');
        }

        $reviewModel->insert([
            'user_id'             => $userId,
            'restaurant_id'       => $order['restaurant_id'],
            'delivery_partner_id' => $order['delivery_partner_id'],
            'order_id'            => $orderId,
            'rating'              => $rating,
            'partner_rating'      => $order['delivery_partner_id'] ? $partnerRating : null,
            'comment'             => $comment !== '' ? $comment : null,
        ]);

        $this->recomputeRestaurantRating($order['restaurant_id']);
        if ($order['delivery_partner_id'] && $partnerRating !== null) {
            $this->recomputePartnerRating($order['delivery_partner_id']);
        }

        return redirect()->to('/orders')->with('success', 'Thanks for rating your order!');
    }

    protected function recomputeRestaurantRating(int $restaurantId): void
    {
        $reviewModel = new ReviewModel();
        $result = $reviewModel->selectAvg('rating', 'avg_rating')
                               ->selectCount('id', 'total')
                               ->where('restaurant_id', $restaurantId)
                               ->get()->getRowArray();

        (new RestaurantModel())->update($restaurantId, [
            'rating'       => round((float) ($result['avg_rating'] ?? 0), 1),
            'rating_count' => (int) ($result['total'] ?? 0),
        ]);
    }

    protected function recomputePartnerRating(int $partnerId): void
    {
        $reviewModel = new ReviewModel();
        $result = $reviewModel->selectAvg('partner_rating', 'avg_rating')
                               ->selectCount('id', 'total')
                               ->where('delivery_partner_id', $partnerId)
                               ->where('partner_rating IS NOT NULL', null, false)
                               ->get()->getRowArray();

        (new DeliveryPartnerModel())->update($partnerId, [
            'rating'       => round((float) ($result['avg_rating'] ?? 0), 1),
            'rating_count' => (int) ($result['total'] ?? 0),
        ]);
    }
}
