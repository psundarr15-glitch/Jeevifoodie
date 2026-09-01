<?php

namespace App\Models;

use CodeIgniter\Model;

class CouponModel extends Model
{
    protected $table         = 'coupons';
    protected $primaryKey    = 'id';
    protected $allowedFields = [
        'code', 'description', 'discount_type', 'discount_value',
        'min_order_value', 'max_discount', 'valid_from', 'valid_to', 'is_active',
    ];
    protected $useTimestamps = false;

    public function findValidByCode(string $code)
    {
        return $this->where('code', strtoupper($code))
                    ->where('is_active', 1)
                    ->first();
    }

    /**
     * Server-side source of truth for "is this coupon usable right now,
     * for this order total". Used by both the AJAX apply-coupon endpoint
     * AND at actual order-placement time — never trust a discount amount
     * that came back from the client between those two calls.
     */
    public function validateForOrder(string $code, float $subtotal): ?array
    {
        $coupon = $this->findValidByCode($code);
        if (! $coupon) {
            return null;
        }

        $today = date('Y-m-d');
        if (! empty($coupon['valid_from']) && $coupon['valid_from'] > $today) {
            return null;
        }
        if (! empty($coupon['valid_to']) && $coupon['valid_to'] < $today) {
            return null;
        }
        if ($subtotal < (float) $coupon['min_order_value']) {
            return null;
        }

        return $coupon;
    }

    /**
     * Same math the AJAX endpoint uses, kept in one place so order-placement
     * can recompute it independently of whatever the client submits.
     */
    public function calculateDiscount(array $coupon, float $subtotal): float
    {
        $discount = $coupon['discount_type'] === 'percent'
            ? round($subtotal * ($coupon['discount_value'] / 100), 2)
            : (float) $coupon['discount_value'];

        if ($coupon['max_discount'] && $discount > $coupon['max_discount']) {
            $discount = (float) $coupon['max_discount'];
        }

        return $discount;
    }
}
