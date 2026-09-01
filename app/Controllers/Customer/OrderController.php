<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\OrderModel;
use App\Models\OrderItemModel;
use App\Models\OrderTrackingModel;
use App\Models\DeliveryPartnerModel;
use App\Models\RestaurantModel;
use App\Models\ReviewModel;

class OrderController extends BaseController
{
    public function myOrders()
    {
        $userId = session()->get('user_id');
        $orderModel = new OrderModel();
        $orders = $orderModel->forUser($userId)->findAll();

        $reviewedOrderIds = (new ReviewModel())->where('user_id', $userId)->findColumn('order_id') ?: [];

        return view('customer/my_orders', [
            'orders'           => $orders,
            'reviewedOrderIds' => $reviewedOrderIds,
        ]);
    }

    public function track(string $orderCode)
    {
        $orderModel = new OrderModel();
        $orderItemModel = new OrderItemModel();
        $trackingModel = new OrderTrackingModel();
        $partnerModel = new DeliveryPartnerModel();
        $restaurantModel = new RestaurantModel();

        $order = $orderModel->findByCode($orderCode);
        if (! $order || $order['user_id'] != session()->get('user_id')) {
            return redirect()->to('/orders')->with('error', 'Order not found.');
        }

        // Partner identity (name/phone) is only revealed to the customer once
        // the delivery partner has accepted the order — see acceptOrder()
        // in Delivery\DashboardController.
        $partner = ($order['delivery_partner_id'] && $order['order_status'] !== 'placed')
            ? $partnerModel->find($order['delivery_partner_id'])
            : null;
        $restaurant = $restaurantModel->find($order['restaurant_id']);

        return view('customer/order_tracking', [
            'order'      => $order,
            'items'      => $orderItemModel->where('order_id', $order['id'])->findAll(),
            'history'    => $trackingModel->historyFor($order['id']),
            'partner'    => $partner,
            'restaurant' => $restaurant,
        ]);
    }
}
