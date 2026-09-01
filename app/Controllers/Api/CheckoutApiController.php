<?php

namespace App\Controllers\Api;

use App\Models\CartModel;
use App\Models\CartItemModel;
use App\Models\CouponModel;
use App\Models\OrderModel;
use App\Models\OrderItemModel;
use App\Models\OrderTrackingModel;
use App\Models\AddressModel;
use App\Models\WalletTransactionModel;

class CheckoutApiController extends BaseApiController
{
    public function applyCoupon()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $code = $this->request->getPost('code');
        $subtotal = (float) $this->request->getPost('subtotal');

        $couponModel = new CouponModel();
        $coupon = $couponModel->validateForOrder((string) $code, $subtotal);
        if (! $coupon) {
            return $this->fail('Invalid, expired, or not-yet-eligible coupon.');
        }

        $discount = $couponModel->calculateDiscount($coupon, $subtotal);

        return $this->ok(['discount' => $discount, 'coupon_id' => $coupon['id']]);
    }

    public function placeOrder()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $cartModel = new CartModel();
        $cartItemModel = new CartItemModel();
        $orderModel = new OrderModel();
        $orderItemModel = new OrderItemModel();
        $trackingModel = new OrderTrackingModel();

        $cart = $cartModel->where('user_id', $user['id'])->first();
        if (! $cart) {
            return $this->fail('Your cart is empty.');
        }

        $items = $cartItemModel->itemsWithDetails($cart['id']);
        if (empty($items)) {
            return $this->fail('Your cart is empty.');
        }

        // Same idea as the web checkout: an item sitting in the cart could
        // have gone out-of-stock since it was added — re-check right here.
        $outOfStock = array_filter($items, static fn ($it) => ! $it['is_available']);
        if ($outOfStock) {
            $names = implode(', ', array_column($outOfStock, 'name'));
            return $this->fail("$names is out of stock. Please remove it from your cart to continue.");
        }

        $subtotal = 0;
        foreach ($items as $it) {
            $subtotal += $it['price'] * $it['quantity'];
        }

        // Never trust a client-sent discount amount — re-validate the
        // coupon and re-price it server-side at order time.
        $discount = 0.0;
        $couponId = $this->request->getPost('coupon_id') ?: null;
        if ($couponId) {
            $couponModel = new CouponModel();
            $coupon = $couponModel->find($couponId);
            if ($coupon && $couponModel->validateForOrder($coupon['code'], $subtotal)) {
                $discount = $couponModel->calculateDiscount($coupon, $subtotal);
            } else {
                $couponId = null;
            }
        }
        $deliveryFee = $subtotal >= 199 ? 0 : 30;
        $total = max($subtotal - $discount + $deliveryFee, 0);
        $paymentMethod = $this->request->getPost('payment_method') ?? 'cod';

        // Wallet payments must actually be debited here - storing the
        // method alone (without moving money) would silently let orders
        // through as "paid" with no balance ever deducted.
        if ($paymentMethod === 'wallet') {
            if ((float) ($user['wallet_balance'] ?? 0) < $total) {
                return $this->fail('Insufficient wallet balance.');
            }
        }

        $orderId = $orderModel->insert([
            'order_code'             => $orderModel->generateOrderCode(),
            'user_id'                => $user['id'],
            'restaurant_id'          => $cart['restaurant_id'],
            'address_id'             => $this->request->getPost('address_id'),
            'delivery_partner_id'    => null,
            'coupon_id'              => $couponId,
            'subtotal'               => $subtotal,
            'discount'               => $discount,
            'delivery_fee'           => $deliveryFee,
            'total'                  => $total,
            'payment_method'         => $paymentMethod,
            'payment_status'         => $paymentMethod === 'wallet' ? 'paid' : 'pending',
            'order_status'           => 'placed',
            'estimated_delivery_min' => 30,
            'placed_at'              => date('Y-m-d H:i:s'),
        ]);

        if ($paymentMethod === 'wallet') {
            (new WalletTransactionModel())->debit($user['id'], $total, 'Order payment', $orderId);
        }

        foreach ($items as $it) {
            $orderItemModel->insert([
                'order_id'  => $orderId,
                'item_name' => $it['name'],
                'price'     => $it['price'],
                'quantity'  => $it['quantity'],
                'is_veg'    => $it['is_veg'],
            ]);
        }

        $trackingModel->insert([
            'order_id' => $orderId,
            'status'   => 'placed',
            'note'     => 'Your order has been placed successfully.',
        ]);

        $cartItemModel->where('cart_id', $cart['id'])->delete();
        $cartModel->delete($cart['id']);

        $order = $orderModel->find($orderId);
        return $this->ok(['order' => $order]);
    }
}
