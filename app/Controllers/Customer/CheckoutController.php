<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\CartModel;
use App\Models\CartItemModel;
use App\Models\AddressModel;
use App\Models\CouponModel;
use App\Models\OrderModel;
use App\Models\OrderItemModel;
use App\Models\OrderTrackingModel;
use App\Models\RestaurantModel;
use App\Libraries\RazorpayClient;

class CheckoutController extends BaseController
{
    public function index()
    {
        $userId = session()->get('user_id');
        $cartModel = new CartModel();
        $cartItemModel = new CartItemModel();
        $addressModel = new AddressModel();

        $cart = $cartModel->where('user_id', $userId)->first();
        if (! $cart) {
            return redirect()->to('/cart')->with('error', 'Your cart is empty.');
        }

        $addresses = $addressModel->where('user_id', $userId)
                                   ->where('lat IS NOT NULL', null, false)
                                   ->where('lng IS NOT NULL', null, false)
                                   ->findAll();

        // No point letting them into checkout at all without a delivery
        // location — send them to save one first.
        if (empty($addresses)) {
            return redirect()->to('/profile')->with('error', 'Please save a delivery location on the map before placing an order.');
        }

        // The restaurant may have closed since the items were added to the
        // cart — check again here so the customer finds out before filling
        // in address/payment details, not after.
        $restaurant = (new RestaurantModel())->find($cart['restaurant_id']);
        if (! $restaurant || ! RestaurantModel::isOpenNow($restaurant)) {
            return redirect()->to('/cart')->with('error', ($restaurant['name'] ?? 'This restaurant') . ' is currently closed. Please check back when it reopens.');
        }

        $items = $cartItemModel->itemsWithDetails($cart['id']);
        $subtotal = 0;
        foreach ($items as $it) {
            $subtotal += $it['price'] * $it['quantity'];
        }

        return view('customer/checkout', [
            'items'     => $items,
            'subtotal'  => $subtotal,
            'addresses' => $addresses,
        ]);
    }

    public function applyCoupon()
    {
        $code = $this->request->getPost('code');
        $subtotal = (float) $this->request->getPost('subtotal');

        $couponModel = new CouponModel();
        $coupon = $couponModel->validateForOrder((string) $code, $subtotal);

        if (! $coupon) {
            return $this->response->setJSON(['success' => false, 'message' => 'Invalid, expired, or not-yet-eligible coupon.']);
        }

        $discount = $couponModel->calculateDiscount($coupon, $subtotal);

        return $this->response->setJSON([
            'success'  => true,
            'discount' => $discount,
            'coupon_id' => $coupon['id'],
            'message'  => 'Coupon applied! You saved ₹' . $discount,
        ]);
    }

    /**
     * Validates the cart and either:
     * - COD: creates the order immediately (unchanged behavior), or
     * - UPI/Card: does NOT create any order yet. It stashes everything
     *   needed to create the order in the session and sends the customer
     *   to the Razorpay payment page. The order is only actually written
     *   to the database once PaymentController::verify() confirms the
     *   payment really succeeded — so an abandoned/cancelled/failed
     *   payment never leaves behind a fake "placed" order.
     */
    public function placeOrder()
    {
        $userId = session()->get('user_id');
        $cartModel = new CartModel();
        $cartItemModel = new CartItemModel();
        $addressModel = new AddressModel();

        $cart = $cartModel->where('user_id', $userId)->first();
        if (! $cart) {
            return redirect()->to('/cart')->with('error', 'Your cart is empty.');
        }

        $items = $cartItemModel->itemsWithDetails($cart['id']);
        if (empty($items)) {
            return redirect()->to('/cart')->with('error', 'Your cart is empty.');
        }

        // A delivery location is mandatory — never trust the client to have
        // actually picked one, even if the checkout form normally requires it.
        $addressId = $this->request->getPost('address_id');
        $address = $addressId ? $addressModel->find($addressId) : null;

        if (! $address || $address['user_id'] != $userId) {
            return redirect()->to('/checkout')->with('error', 'Please select a saved delivery location before placing your order.');
        }
        if (! $address['lat'] || ! $address['lng']) {
            return redirect()->to('/profile')->with('error', 'That address doesn\'t have a map location saved yet. Please add a new address using the map before ordering.');
        }

        // Final gate before anything is actually created — the restaurant
        // could have closed at any point between adding items to the cart
        // and clicking Place Order, and cart/add() blocking new additions
        // isn't enough on its own since items already in the cart stay there.
        $restaurant = (new RestaurantModel())->find($cart['restaurant_id']);
        if (! $restaurant || ! RestaurantModel::isOpenNow($restaurant)) {
            return redirect()->to('/cart')->with('error', ($restaurant['name'] ?? 'This restaurant') . ' is currently closed. Please check back when it reopens.');
        }

        // Same idea for stock: an item sitting in the cart could have been
        // marked out-of-stock by the restaurant since it was added.
        $outOfStock = array_filter($items, static fn ($it) => ! $it['is_available']);
        if ($outOfStock) {
            $names = implode(', ', array_column($outOfStock, 'name'));
            return redirect()->to('/cart')->with('error', "$names is out of stock. Please remove it from your cart to continue.");
        }

        $subtotal = 0;
        foreach ($items as $it) {
            $subtotal += $it['price'] * $it['quantity'];
        }

        // Discount is NEVER taken from the client — a submitted coupon_id
        // is re-validated and re-priced from the DB right here, at the
        // moment of order placement, so a tampered "discount" POST field
        // (or a coupon that expired between apply and submit) can't create
        // an under-priced order.
        $discount = 0.0;
        $couponId = $this->request->getPost('coupon_id') ?: null;
        if ($couponId) {
            $couponModel = new CouponModel();
            $coupon = $couponModel->find($couponId);
            if ($coupon && $couponModel->validateForOrder($coupon['code'], $subtotal)) {
                $discount = $couponModel->calculateDiscount($coupon, $subtotal);
            } else {
                $couponId = null; // stale/invalid coupon — silently drop it, don't apply any discount
            }
        }
        $deliveryFee = $subtotal >= 199 ? 0 : 30;
        $total = max($subtotal - $discount + $deliveryFee, 0);
        $paymentMethod = $this->request->getPost('payment_method') ?? 'cod';
        $addressId = $this->request->getPost('address_id');

        if ($paymentMethod === 'cod') {
            $orderCode = $this->createOrderInDb($userId, $cart, $items, $addressId, $couponId, $subtotal, $discount, $deliveryFee, $total, 'cod', 'pending');
            return redirect()->to('/order/track/' . $orderCode);
        }

        // UPI/Card: create the Razorpay order, stash everything in session,
        // don't touch the orders table or the cart yet.
        $razorpay = new RazorpayClient();
        if (! $razorpay->isConfigured()) {
            return redirect()->to('/checkout')->with('error', 'Online payment is not available right now. Please try Cash on Delivery.');
        }

        $tempReceipt = 'JEEVI-' . strtoupper(bin2hex(random_bytes(5)));
        $result = $razorpay->createOrder($total, $tempReceipt);
        if (! $result['success']) {
            return redirect()->to('/checkout')->with('error', 'Could not start payment: ' . $result['error']);
        }

        session()->set('pending_payment', [
            'cart_id'            => $cart['id'],
            'address_id'         => $addressId,
            'coupon_id'          => $couponId,
            'subtotal'           => $subtotal,
            'discount'           => $discount,
            'delivery_fee'       => $deliveryFee,
            'total'              => $total,
            'payment_method'     => $paymentMethod,
            'razorpay_order_id'  => $result['order_id'],
        ]);

        return redirect()->to('/checkout/pay');
    }

    /**
     * Shared by PaymentController::verify() (for UPI/Card, after the
     * signature checks out) and placeOrder() above (for COD).
     */
    public function createOrderInDb($userId, $cart, $items, $addressId, $couponId, $subtotal, $discount, $deliveryFee, $total, $paymentMethod, $paymentStatus, $razorpayOrderId = null, $razorpayPaymentId = null): string
    {
        $orderModel = new OrderModel();
        $orderItemModel = new OrderItemModel();
        $trackingModel = new OrderTrackingModel();
        $cartItemModel = new CartItemModel();
        $cartModel = new CartModel();

        $orderId = $orderModel->insert([
            'order_code'             => $orderModel->generateOrderCode(),
            'user_id'                => $userId,
            'restaurant_id'          => $cart['restaurant_id'],
            'address_id'             => $addressId,
            'delivery_partner_id'    => null,
            'coupon_id'              => $couponId,
            'subtotal'               => $subtotal,
            'discount'               => $discount,
            'delivery_fee'           => $deliveryFee,
            'total'                  => $total,
            'payment_method'         => $paymentMethod,
            'payment_status'         => $paymentStatus,
            'razorpay_order_id'      => $razorpayOrderId,
            'razorpay_payment_id'    => $razorpayPaymentId,
            'order_status'           => 'placed',
            'estimated_delivery_min' => 30,
            'placed_at'              => date('Y-m-d H:i:s'),
        ]);

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
            'note'     => $paymentStatus === 'paid' ? 'Payment received. Order placed successfully.' : 'Your order has been placed successfully.',
        ]);

        $cartItemModel->where('cart_id', $cart['id'])->delete();
        $cartModel->delete($cart['id']);

        return $orderModel->find($orderId)['order_code'];
    }
}
