<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\OrderModel;
use App\Models\OrderTrackingModel;
use App\Models\DeliveryPartnerModel;
use App\Libraries\PushNotificationService;

class OrderController extends BaseController
{
    /**
     * Pushes an order-status update to the customer's phone via FCM.
     * Never throws - a notification failure must not block the actual
     * status update the admin/manager just made.
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
    protected function isManager(): bool
    {
        return session()->get('admin_role') === 'restaurant_manager';
    }

    protected function myRestaurantId()
    {
        return session()->get('admin_restaurant_id');
    }

    public function index()
    {
        $model = new OrderModel();
        $query = $model->select('orders.*, users.name as customer_name, restaurants.name as restaurant_name')
                        ->join('users', 'users.id = orders.user_id')
                        ->join('restaurants', 'restaurants.id = orders.restaurant_id');

        if ($this->isManager()) {
            $query->where('orders.restaurant_id', $this->myRestaurantId());
        }

        $orders = $query->orderBy('orders.id', 'DESC')->findAll();

        return view('admin/orders/index', ['orders' => $orders]);
    }

    public function view($id)
    {
        $orderModel = new OrderModel();
        $trackingModel = new OrderTrackingModel();
        $partnerModel = new DeliveryPartnerModel();

        $order = $orderModel->find($id);
        if (! $order) {
            return redirect()->to('/admin/orders')->with('error', 'Order not found.');
        }
        if ($this->isManager() && $order['restaurant_id'] != $this->myRestaurantId()) {
            return redirect()->to('/admin/orders')->with('error', 'You can only manage orders from your own restaurant.');
        }

        return view('admin/orders/view', [
            'order'    => $order,
            'items'    => (new \App\Models\OrderItemModel())->where('order_id', $id)->findAll(),
            'history'  => $trackingModel->historyFor($id),
            'partners' => $partnerModel->findAll(),
        ]);
    }

    /**
     * Updates order status and/or delivery partner live location.
     * Every change is logged into order_tracking, which is what the
     * customer's live tracking page polls via the Api\TrackingApiController.
     */
    public function updateStatus($id)
    {
        $orderModel = new OrderModel();
        $trackingModel = new OrderTrackingModel();
        $partnerModel = new DeliveryPartnerModel();

        $order = $orderModel->find($id);
        if (! $order) {
            return redirect()->to('/admin/orders')->with('error', 'Order not found.');
        }
        if ($this->isManager() && $order['restaurant_id'] != $this->myRestaurantId()) {
            return redirect()->to('/admin/orders')->with('error', 'You can only manage orders from your own restaurant.');
        }

        $status = $this->request->getPost('order_status');
        $lat = $this->request->getPost('lat');
        $lng = $this->request->getPost('lng');
        $note = $this->request->getPost('note');
        $partnerId = $this->request->getPost('delivery_partner_id');

        $updateData = ['order_status' => $status];
        if ($status === 'delivered') {
            $updateData['delivered_at'] = date('Y-m-d H:i:s');
        }
        if ($partnerId) {
            $updateData['delivery_partner_id'] = $partnerId;
        }
        $orderModel->update($id, $updateData);

        if ($lat && $lng && $partnerId) {
            $partnerModel->update($partnerId, ['current_lat' => $lat, 'current_lng' => $lng]);
        }

        $trackingModel->insert([
            'order_id' => $id,
            'status'   => $status,
            'lat'      => $lat ?: null,
            'lng'      => $lng ?: null,
            'note'     => $note ?: ucfirst(str_replace('_', ' ', $status)),
        ]);

        $this->notifyCustomer($order, $status);

        return redirect()->to('/admin/orders/' . $id)->with('success', 'Order updated. Customer tracking refreshed.');
    }
}
