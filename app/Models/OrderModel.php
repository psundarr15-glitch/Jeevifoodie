<?php

namespace App\Models;

use CodeIgniter\Model;

class OrderModel extends Model
{
    protected $table         = 'orders';
    protected $primaryKey    = 'id';
    protected $allowedFields = [
        'order_code', 'user_id', 'restaurant_id', 'address_id', 'delivery_partner_id', 'coupon_id',
        'subtotal', 'discount', 'delivery_fee', 'total', 'payment_method', 'payment_status',
        'razorpay_order_id', 'razorpay_payment_id',
        'order_status', 'estimated_delivery_min', 'placed_at', 'delivered_at',
    ];
    protected $useTimestamps = false;

    public static $STATUS_FLOW = ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'];

    public function generateOrderCode(): string
    {
        return 'JEEVI' . strtoupper(substr(uniqid(), -6));
    }

    public function findByCode(string $code)
    {
        return $this->where('order_code', $code)->first();
    }

    public function forUser($userId)
    {
        return $this->where('user_id', $userId)->orderBy('id', 'DESC');
    }
}
