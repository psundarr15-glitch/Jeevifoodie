<?php

namespace App\Controllers\Delivery;

use App\Controllers\BaseController;
use App\Models\OrderModel;
use App\Models\OrderTrackingModel;
use App\Models\DeliveryPartnerModel;
use App\Models\OrderDeclineModel;
use App\Models\OrderItemModel;
use App\Models\AddressModel;
use App\Models\RestaurantModel;
use App\Libraries\PushNotificationService;

class DashboardController extends BaseController
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
    public function index()
    {
        $partnerId = session()->get('partner_id');
        $orderModel = new OrderModel();
        $partnerModel = new DeliveryPartnerModel();
        $declineModel = new OrderDeclineModel();

        $partner = $partnerModel->find($partnerId);

        $baseQuery = 'orders.*, users.name as customer_name, users.phone as customer_phone,
                       restaurants.name as restaurant_name, restaurants.lat as restaurant_lat,
                       restaurants.lng as restaurant_lng';

        // Orders this partner has already declined shouldn't be shown to them again
        $declinedIds = $declineModel->where('delivery_partner_id', $partnerId)->findColumn('order_id');
        $declinedIds = $declinedIds ?: [0];

        // New orders that haven't been accepted by anyone yet — broadcast to
        // every available partner (minus ones this partner already declined).
        $pendingOrders = $orderModel->select($baseQuery)
                                     ->join('users', 'users.id = orders.user_id')
                                     ->join('restaurants', 'restaurants.id = orders.restaurant_id')
                                     ->where('orders.order_status', 'placed')
                                     ->where('orders.delivery_partner_id', null)
                                     ->whereNotIn('orders.id', $declinedIds)
                                     ->orderBy('orders.id', 'ASC')
                                     ->findAll();

        // Attach distance (partner's current location -> restaurant) to each pending order
        foreach ($pendingOrders as &$po) {
            $po['distance_km'] = distance_km(
                $partner['current_lat'] ?? null,
                $partner['current_lng'] ?? null,
                $po['restaurant_lat'] ?? null,
                $po['restaurant_lng'] ?? null
            );
        }
        unset($po);

        // Orders already accepted (confirmed or further along) and not yet finished
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

        // Weekly stats (current calendar week, Mon-Sun)
        $weekRow = $orderModel->selectSum('total', 'earnings')
                               ->selectCount('id', 'order_count')
                               ->where('delivery_partner_id', $partnerId)
                               ->where('order_status', 'delivered')
                               ->where('YEARWEEK(delivered_at, 1) = YEARWEEK(NOW(), 1)', null, false)
                               ->get()->getRowArray();

        // Monthly stats (current calendar month)
        $monthRow = $orderModel->selectSum('total', 'earnings')
                                ->selectCount('id', 'order_count')
                                ->where('delivery_partner_id', $partnerId)
                                ->where('order_status', 'delivered')
                                ->where('MONTH(delivered_at) = MONTH(NOW()) AND YEAR(delivered_at) = YEAR(NOW())', null, false)
                                ->get()->getRowArray();

        return view('delivery/dashboard', [
            'pendingOrders'   => $pendingOrders,
            'orders'          => $activeOrders,
            'completed_today' => $completedToday,
            'weekly_orders'   => (int) ($weekRow['order_count'] ?? 0),
            'weekly_earnings' => (float) ($weekRow['earnings'] ?? 0),
            'monthly_orders'  => (int) ($monthRow['order_count'] ?? 0),
            'monthly_earnings'=> (float) ($monthRow['earnings'] ?? 0),
        ]);
    }

    /**
     * Full order details page (Store details, Customer details, items,
     * bill breakdown) — reached by tapping an order card on the dashboard.
     */
    public function viewOrder($orderId)
    {
        $partnerId = session()->get('partner_id');
        $orderModel = new OrderModel();
        $orderItemModel = new OrderItemModel();
        $restaurantModel = new RestaurantModel();
        $addressModel = new AddressModel();
        $partnerModel = new DeliveryPartnerModel();

        $order = $orderModel->select('orders.*, users.name as customer_name, users.phone as customer_phone')
                             ->join('users', 'users.id = orders.user_id')
                             ->where('orders.id', $orderId)
                             ->first();

        $isMine = $order && $order['delivery_partner_id'] == $partnerId;
        $isPendingBroadcast = $order && $order['delivery_partner_id'] === null && $order['order_status'] === 'placed';

        if (! $order || (! $isMine && ! $isPendingBroadcast)) {
            return redirect()->to('/delivery/dashboard')->with('error', 'Order not found.');
        }

        $restaurant = $restaurantModel->find($order['restaurant_id']);
        $address = $order['address_id'] ? $addressModel->find($order['address_id']) : null;
        $partner = $partnerModel->find($partnerId);

        $distanceKm = distance_km(
            $partner['current_lat'] ?? null,
            $partner['current_lng'] ?? null,
            $restaurant['lat'] ?? null,
            $restaurant['lng'] ?? null
        );

        return view('delivery/order_details', [
            'order'      => $order,
            'items'      => $orderItemModel->where('order_id', $orderId)->findAll(),
            'restaurant' => $restaurant,
            'address'    => $address,
            'distance_km'=> $distanceKm,
        ]);
    }

    /**
     * The delivery partner taps "Accept Order" in the popup. The order was
     * broadcast unassigned (delivery_partner_id IS NULL) to every partner,
     * so this claims it — atomically, so if two partners tap Accept at
     * nearly the same moment, only the first one actually gets it.
     */
    public function acceptOrder($orderId)
    {
        $partnerId = session()->get('partner_id');
        $orderModel = new OrderModel();
        $trackingModel = new OrderTrackingModel();

        $order = $orderModel->find($orderId);
        if (! $order || $order['order_status'] !== 'placed') {
            return redirect()->to('/delivery/dashboard')->with('error', 'This order is no longer available.');
        }

        if ($order['delivery_partner_id'] !== null && $order['delivery_partner_id'] != $partnerId) {
            return redirect()->to('/delivery/dashboard')->with('error', 'Another partner already accepted this order.');
        }

        $db = \Config\Database::connect();
        $db->table('orders')
           ->where('id', $orderId)
           ->where('delivery_partner_id', null)
           ->update(['delivery_partner_id' => $partnerId, 'order_status' => 'confirmed']);

        if ($db->affectedRows() === 0) {
            return redirect()->to('/delivery/dashboard')->with('error', 'Another partner already accepted this order.');
        }

        $trackingModel->insert([
            'order_id' => $orderId,
            'status'   => 'confirmed',
            'note'     => 'Order accepted by delivery partner.',
        ]);

        $this->notifyCustomer($order, 'confirmed');

        return redirect()->to('/delivery/dashboard')->with('success', 'Order accepted!');
    }

    /**
     * The delivery partner taps "Reject" in the popup. The order stays
     * unassigned and broadcast to every other available partner — we just
     * remember that THIS partner passed on it, so it won't be shown to
     * them again.
     */
    public function rejectOrder($orderId)
    {
        $partnerId = session()->get('partner_id');
        $orderModel = new OrderModel();
        $declineModel = new OrderDeclineModel();

        $order = $orderModel->find($orderId);
        if (! $order) {
            return redirect()->to('/delivery/dashboard')->with('error', 'Order not found.');
        }

        $alreadyDeclined = $declineModel->where('order_id', $orderId)
                                         ->where('delivery_partner_id', $partnerId)
                                         ->first();
        if (! $alreadyDeclined) {
            $declineModel->insert([
                'order_id'            => $orderId,
                'delivery_partner_id' => $partnerId,
            ]);
        }

        return redirect()->to('/delivery/dashboard')->with('success', 'Order declined.');
    }

    /**
     * Called from the dashboard when the partner taps "Update Status" on an order.
     */
    public function updateStatus($orderId)
    {
        $partnerId = session()->get('partner_id');
        $orderModel = new OrderModel();
        $trackingModel = new OrderTrackingModel();

        $order = $orderModel->find($orderId);
        if (! $order || $order['delivery_partner_id'] != $partnerId) {
            return redirect()->to('/delivery/dashboard')->with('error', 'Order not found.');
        }

        $status = $this->request->getPost('order_status');

        $updateData = ['order_status' => $status];
        if ($status === 'delivered') {
            $updateData['delivered_at'] = date('Y-m-d H:i:s');
        }
        $orderModel->update($orderId, $updateData);

        $trackingModel->insert([
            'order_id' => $orderId,
            'status'   => $status,
            'note'     => ucfirst(str_replace('_', ' ', $status)) . ' by delivery partner.',
        ]);

        $this->notifyCustomer($order, $status);

        return redirect()->to('/delivery/dashboard')->with('success', 'Order status updated.');
    }

    /**
     * AJAX endpoint polled by the dashboard's geolocation watcher.
     * Updates the partner's live position and logs it against every
     * order currently assigned to them that's out for delivery, so the
     * customer's live tracking map moves in near-real-time.
     */
    public function updateLocation()
    {
        $partnerId = session()->get('partner_id');
        $lat = $this->request->getPost('lat');
        $lng = $this->request->getPost('lng');

        if (! $lat || ! $lng) {
            return $this->response->setJSON(['success' => false, 'message' => 'Missing coordinates']);
        }

        $partnerModel = new DeliveryPartnerModel();
        $partnerModel->update($partnerId, ['current_lat' => $lat, 'current_lng' => $lng]);

        $orderModel = new OrderModel();
        $trackingModel = new OrderTrackingModel();

        $activeOrders = $orderModel->where('delivery_partner_id', $partnerId)
                                    ->where('order_status', 'out_for_delivery')
                                    ->findAll();

        foreach ($activeOrders as $order) {
            $trackingModel->insert([
                'order_id' => $order['id'],
                'status'   => 'out_for_delivery',
                'lat'      => $lat,
                'lng'      => $lng,
                'note'     => 'Live location update',
            ]);
        }

        return $this->response->setJSON(['success' => true, 'orders_updated' => count($activeOrders)]);
    }
}
