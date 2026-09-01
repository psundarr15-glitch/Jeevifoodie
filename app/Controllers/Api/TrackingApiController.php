<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\OrderModel;
use App\Models\OrderTrackingModel;
use App\Models\DeliveryPartnerModel;

/**
 * Polled by the customer's live tracking page every few seconds
 * to refresh order status, delivery partner position, and the
 * status timeline without a full page reload.
 */
class TrackingApiController extends BaseController
{
    public function status(string $orderCode)
    {
        $orderModel = new OrderModel();
        $trackingModel = new OrderTrackingModel();
        $partnerModel = new DeliveryPartnerModel();

        $order = $orderModel->findByCode($orderCode);

        if (! $order || $order['user_id'] != session()->get('user_id')) {
            return $this->response->setStatusCode(404)->setJSON(['success' => false, 'message' => 'Order not found']);
        }

        $latest = $trackingModel->latestFor($order['id']);
        $history = $trackingModel->historyFor($order['id']);

        // Same rule as the initial page load: don't reveal who the delivery
        // partner is until they've actually accepted the order.
        $partnerRevealed = $order['delivery_partner_id'] && $order['order_status'] !== 'placed';
        $partner = $partnerRevealed ? $partnerModel->find($order['delivery_partner_id']) : null;

        return $this->response->setJSON([
            'success'      => true,
            'order_status' => $order['order_status'],
            'lat'          => $partnerRevealed ? ($latest['lat'] ?? ($partner['current_lat'] ?? null)) : null,
            'lng'          => $partnerRevealed ? ($latest['lng'] ?? ($partner['current_lng'] ?? null)) : null,
            'eta_min'      => $order['estimated_delivery_min'],
            'history'      => array_map(function ($h) {
                return [
                    'status'     => $h['status'],
                    'note'       => $h['note'],
                    'created_at' => $h['created_at'],
                ];
            }, $history),
            'partner_name' => $partner['name'] ?? null,
            'partner_phone'=> $partner['phone'] ?? null,
        ]);
    }
}
