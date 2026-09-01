<?php

namespace App\Controllers\Api;

use App\Models\OrderModel;
use App\Models\OrderItemModel;
use App\Models\OrderTrackingModel;
use App\Models\DeliveryPartnerModel;
use App\Models\RestaurantModel;

class OrderApiController extends BaseApiController
{
    public function myOrders()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        return $this->ok(['orders' => (new OrderModel())->forUser($user['id'])->findAll()]);
    }

    public function track(string $orderCode)
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $orderModel = new OrderModel();
        $order = $orderModel->findByCode($orderCode);
        if (! $order || $order['user_id'] != $user['id']) {
            return $this->fail('Order not found.', 404);
        }

        $trackingModel = new OrderTrackingModel();
        $partner = $order['delivery_partner_id'] ? (new DeliveryPartnerModel())->find($order['delivery_partner_id']) : null;
        $restaurant = (new RestaurantModel())->find($order['restaurant_id']);
        $latest = $trackingModel->latestFor($order['id']);

        return $this->ok([
            'order_status'    => $order['order_status'],
            'eta_min'         => $order['estimated_delivery_min'],
            'lat'             => $latest['lat'] ?? ($partner['current_lat'] ?? null),
            'lng'             => $latest['lng'] ?? ($partner['current_lng'] ?? null),
            'restaurant_lat'  => $restaurant['lat'] ?? null,
            'restaurant_lng'  => $restaurant['lng'] ?? null,
            'restaurant_id'   => $order['restaurant_id'],
            'restaurant_name' => $restaurant['name'] ?? null,
            'partner_name'    => $partner['name'] ?? null,
            'partner_phone'   => $partner['phone'] ?? null,
            'items'           => (new OrderItemModel())->where('order_id', $order['id'])->findAll(),
            'history'         => $trackingModel->historyFor($order['id']),
            'order'           => $order,
        ]);
    }
}
