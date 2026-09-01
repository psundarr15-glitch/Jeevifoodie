<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>
<div class="card card-jeevi p-4">
    <h4 class="section-title mb-3">Terms &amp; Conditions</h4>
    <p class="text-muted small">Last updated: <?= date('F Y') ?></p>

    <h6 class="fw-bold mt-3">1. Using Jeevi</h6>
    <p>By placing an order through Jeevi Foodie Delivery, you agree to provide accurate delivery details and to be available to receive your order at the address and time indicated.</p>

    <h6 class="fw-bold mt-3">2. Orders &amp; Pricing</h6>
    <p>Menu prices, availability, and restaurant operating hours are set by each partner restaurant and may change without notice. Delivery fees, coupons, and taxes are shown at checkout before you confirm payment.</p>

    <h6 class="fw-bold mt-3">3. Delivery</h6>
    <p>Estimated delivery times are approximate and can vary due to traffic, weather, or order volume. We currently deliver only within Salem district.</p>

    <h6 class="fw-bold mt-3">4. Payments</h6>
    <p>We accept Cash on Delivery, UPI, and Card payments processed securely through Razorpay. We do not store your card details.</p>

    <h6 class="fw-bold mt-3">5. Cancellations</h6>
    <p>Orders may be cancelled before a restaurant confirms preparation. Once preparation begins, cancellation may not be possible — please see our Refund Policy for details.</p>

    <h6 class="fw-bold mt-3">6. Conduct</h6>
    <p>Please treat our delivery partners and restaurant staff with respect. Abusive behavior towards our team may result in account suspension.</p>
</div>
<?= $this->endSection() ?>
