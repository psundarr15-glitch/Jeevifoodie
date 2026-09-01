<?php

namespace App\Controllers\Api;

use App\Models\OrderModel;
use App\Models\OrderTrackingModel;
use App\Models\DeliveryPartnerModel;
use App\Models\OrderDeclineModel;
use App\Libraries\PushNotificationService;
use App\Models\OrderItemModel;
use App\Models\AddressModel;
use App\Models\RestaurantModel;

class DeliveryApiController extends BaseApiController
{
    /**
     * Pushes an order-status update to the customer's phone via FCM.
     * Never throws - a notification failure must not block the actual
     * status update the delivery partner just made.
     */
    private function notifyCustomer(array $order, string $status): void
    {
        $messages = [
            'confirmed'         => 'Your order has been confirmed and is being prepared.',
            'preparing'         => 'The restaurant is preparing your order.',
            'out_for_delivery'  => 'Your order is out for delivery!',
            'delivered'         => 'Your order has been delivered. Enjoy your meal!',
            'cancelled'         => 'Your order was cancelled.',
        ];
        $body = $messages[$status] ?? ('Order status updated: ' . $status);

        try {
            (new PushNotificationService())->sendToUser(
                (int) $order['user_id'],
                'Order #' . $order['order_code'],
                $body,
                ['order_code' => $order['order_code'], 'order_status' => $status]
            );
        } catch (\Throwable $e) {
            log_message('error', 'Push notification failed: ' . $e->getMessage());
        }
    }
    public function dashboard()
    {
        $partner = $this->authPartner();
        if (! $partner) return $this->response;

        $partnerId = $partner['id'];
        $orderModel = new OrderModel();
        $declineModel = new OrderDeclineModel();

        $baseQuery = 'orders.*, users.name as customer_name, users.phone as customer_phone,
                       restaurants.name as restaurant_name, restaurants.lat as restaurant_lat,
                       restaurants.lng as restaurant_lng';

        $declinedIds = $declineModel->where('delivery_partner_id', $partnerId)->findColumn('order_id');
        $declinedIds = $declinedIds ?: [0];

        $pendingOrders = $orderModel->select($baseQuery)
                                     ->join('users', 'users.id = orders.user_id')
                                     ->join('restaurants', 'restaurants.id = orders.restaurant_id')
                                     ->where('orders.order_status', 'placed')
                                     ->where('orders.delivery_partner_id', null)
                                     ->whereNotIn('orders.id', $declinedIds)
                                     ->orderBy('orders.id', 'ASC')
                                     ->findAll();

        foreach ($pendingOrders as &$po) {
            $po['distance_km'] = distance_km(
                $partner['current_lat'] ?? null,
                $partner['current_lng'] ?? null,
                $po['restaurant_lat'] ?? null,
                $po['restaurant_lng'] ?? null
            );
        }
        unset($po);

        $activeOrders = $orderModel->select($baseQuery)
                                    ->join('users', 'users.id = orders.user_id')
                                    ->join('restaurants', 'restaurants.id = orders.restaurant_id')
                                    ->where('orders.delivery_partner_id', $partnerId)
                                    ->whereNotIn('orders.order_status', ['placed', 'delivered', 'cancelled'])
                                    ->orderBy('orders.id', 'DESC')
                                    ->findAll();

        $completedToday = $orderModel->where('delivery_partner_id', $partnerId)
                                      ->where('order_status', 'delivered')
                                      ->where('DATE(delivered_at)', date('Y-m-d'))
                                      ->countAllResults();

        $weekRow = $orderModel->selectSum('total', 'earnings')->selectCount('id', 'order_count')
                               ->where('delivery_partner_id', $partnerId)->where('order_status', 'delivered')
                               ->where('YEARWEEK(delivered_at, 1) = YEARWEEK(NOW(), 1)', null, false)
                               ->get()->getRowArray();

        $monthRow = $orderModel->selectSum('total', 'earnings')->selectCount('id', 'order_count')
                                ->where('delivery_partner_id', $partnerId)->where('order_status', 'delivered')
                                ->where('MONTH(delivered_at) = MONTH(NOW()) AND YEAR(delivered_at) = YEAR(NOW())', null, false)
                                ->get()->getRowArray();

        return $this->ok([
            'pending_orders'   => $pendingOrders,
            'active_orders'    => $activeOrders,
            'completed_today'  => $completedToday,
            'weekly_orders'    => (int) ($weekRow['order_count'] ?? 0),
            'weekly_earnings'  => (float) ($weekRow['earnings'] ?? 0),
            'monthly_orders'   => (int) ($monthRow['order_count'] ?? 0),
            'monthly_earnings' => (float) ($monthRow['earnings'] ?? 0),
        ]);
    }

    public function orderDetails($orderId)
    {
        $partner = $this->authPartner();
        if (! $partner) return $this->response;

        $orderModel = new OrderModel();
        $order = $orderModel->select('orders.*, users.name as customer_name, users.phone as customer_phone')
                             ->join('users', 'users.id = orders.user_id')
                             ->where('orders.id', $orderId)
                             ->first();

        $isMine = $order && $order['delivery_partner_id'] == $partner['id'];
        $isPendingBroadcast = $order && $order['delivery_partner_id'] === null && $order['order_status'] === 'placed';

        if (! $order || (! $isMine && ! $isPendingBroadcast)) {
            return $this->fail('Order not found.', 404);
        }

        $restaurant = (new RestaurantModel())->find($order['restaurant_id']);
        $address = $order['address_id'] ? (new AddressModel())->find($order['address_id']) : null;

        $distanceKm = distance_km(
            $partner['current_lat'] ?? null,
            $partner['current_lng'] ?? null,
            $restaurant['lat'] ?? null,
            $restaurant['lng'] ?? null
        );

        return $this->ok([
            'order'       => $order,
            'items'       => (new OrderItemModel())->where('order_id', $orderId)->findAll(),
            'restaurant'  => $restaurant,
            'address'     => $address,
            'distance_km' => $distanceKm,
        ]);
    }

    public function acceptOrder($orderId)
    {
        $partner = $this->authPartner();
        if (! $partner) return $this->response;

        $orderModel = new OrderModel();
        $order = $orderModel->find($orderId);
        if (! $order || $order['order_status'] !== 'placed') {
            return $this->fail('This order is no longer available.');
        }
        if ($order['delivery_partner_id'] !== null && $order['delivery_partner_id'] != $partner['id']) {
            return $this->fail('Another partner already accepted this order.');
        }

        $db = \Config\Database::connect();
        $db->table('orders')->where('id', $orderId)->where('delivery_partner_id', null)
           ->update(['delivery_partner_id' => $partner['id'], 'order_status' => 'confirmed']);

        if ($db->affectedRows() === 0) {
            return $this->fail('Another partner already accepted this order.');
        }

        (new OrderTrackingModel())->insert([
            'order_id' => $orderId, 'status' => 'confirmed', 'note' => 'Order accepted by delivery partner.',
        ]);

        $this->notifyCustomer($order, 'confirmed');

        return $this->ok();
    }

    public function rejectOrder($orderId)
    {
        $partner = $this->authPartner();
        if (! $partner) return $this->response;

        $declineModel = new OrderDeclineModel();
        $exists = $declineModel->where('order_id', $orderId)->where('delivery_partner_id', $partner['id'])->first();
        if (! $exists) {
            $declineModel->insert(['order_id' => $orderId, 'delivery_partner_id' => $partner['id']]);
        }

        return $this->ok();
    }

    public function updateStatus($orderId)
    {
        $partner = $this->authPartner();
        if (! $partner) return $this->response;

        $orderModel = new OrderModel();
        $order = $orderModel->find($orderId);
        if (! $order || $order['delivery_partner_id'] != $partner['id']) {
            return $this->fail('Order not found.', 404);
        }

        $status = $this->request->getPost('order_status');
        $updateData = ['order_status' => $status];
        if ($status === 'delivered') {
            $updateData['delivered_at'] = date('Y-m-d H:i:s');
        }
        $orderModel->update($orderId, $updateData);

        (new OrderTrackingModel())->insert([
            'order_id' => $orderId,
            'status'   => $status,
            'note'     => ucfirst(str_replace('_', ' ', $status)) . ' by delivery partner.',
        ]);

        $this->notifyCustomer($order, $status);

        return $this->ok();
    }

    public function updateLocation()
    {
        $partner = $this->authPartner();
        if (! $partner) return $this->response;

        $lat = $this->request->getPost('lat');
        $lng = $this->request->getPost('lng');
        if (! $lat || ! $lng) {
            return $this->fail('Missing coordinates.');
        }

        (new DeliveryPartnerModel())->update($partner['id'], ['current_lat' => $lat, 'current_lng' => $lng]);

        $orderModel = new OrderModel();
        $trackingModel = new OrderTrackingModel();
        $activeOrders = $orderModel->where('delivery_partner_id', $partner['id'])
                                    ->where('order_status', 'out_for_delivery')->findAll();

        foreach ($activeOrders as $order) {
            $trackingModel->insert([
                'order_id' => $order['id'], 'status' => 'out_for_delivery',
                'lat' => $lat, 'lng' => $lng, 'note' => 'Live location update',
            ]);
        }

        return $this->ok(['orders_updated' => count($activeOrders)]);
    }
}
