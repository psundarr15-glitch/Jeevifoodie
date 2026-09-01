<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\CartModel;
use App\Models\CartItemModel;
use App\Libraries\RazorpayClient;

class PaymentController extends BaseController
{
    /**
     * Payment page for a UPI/Card checkout that hasn't been confirmed yet.
     * Reads everything from the session — no order exists in the database
     * at this point.
     */
    public function show()
    {
        $pending = session()->get('pending_payment');
        if (! $pending) {
            return redirect()->to('/cart')->with('error', 'No payment in progress. Please checkout again.');
        }

        $razorpay = new RazorpayClient();

        return view('customer/payment', [
            'total'           => $pending['total'],
            'razorpayOrderId' => $pending['razorpay_order_id'],
            'razorpayKeyId'   => $razorpay->keyId(),
        ]);
    }

    /**
     * Called by the Checkout.js success callback with the three values
     * Razorpay returns. We verify the signature ourselves before trusting
     * the payment succeeded — and ONLY create the order in the database
     * once that verification passes. If the customer closes the popup or
     * the payment fails, this is never called and nothing is written.
     */
    public function verify()
    {
        $userId = session()->get('user_id');
        $pending = session()->get('pending_payment');
        if (! $pending) {
            return $this->response->setStatusCode(400)->setJSON(['success' => false, 'message' => 'No payment in progress.']);
        }

        $razorpayOrderId = $this->request->getPost('razorpay_order_id');
        $razorpayPaymentId = $this->request->getPost('razorpay_payment_id');
        $razorpaySignature = $this->request->getPost('razorpay_signature');

        if ($pending['razorpay_order_id'] !== $razorpayOrderId) {
            return $this->response->setJSON(['success' => false, 'message' => 'Order mismatch.']);
        }

        $razorpay = new RazorpayClient();
        $valid = $razorpay->verifySignature($razorpayOrderId, $razorpayPaymentId, $razorpaySignature ?? '');
        if (! $valid) {
            return $this->response->setJSON(['success' => false, 'message' => 'Payment verification failed.']);
        }

        $cartModel = new CartModel();
        $cartItemModel = new CartItemModel();
        $cart = $cartModel->find($pending['cart_id']);
        if (! $cart) {
            return $this->response->setJSON(['success' => false, 'message' => 'Your cart has changed. Please try again.']);
        }
        $items = $cartItemModel->itemsWithDetails($cart['id']);
        if (empty($items)) {
            return $this->response->setJSON(['success' => false, 'message' => 'Your cart is empty.']);
        }

        $checkoutController = new CheckoutController();
        $orderCode = $checkoutController->createOrderInDb(
            $userId, $cart, $items,
            $pending['address_id'], $pending['coupon_id'],
            $pending['subtotal'], $pending['discount'], $pending['delivery_fee'], $pending['total'],
            $pending['payment_method'], 'paid',
            $razorpayOrderId, $razorpayPaymentId
        );

        session()->remove('pending_payment');

        return $this->response->setJSON([
            'success'      => true,
            'redirect_url' => base_url('order/track/' . $orderCode),
        ]);
    }
}
