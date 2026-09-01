<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>
<div class="card card-jeevi p-4">
    <h4 class="section-title mb-3">Refund Policy</h4>
    <p class="text-muted small">Last updated: <?= date('F Y') ?></p>

    <h6 class="fw-bold mt-3">Eligible for Refund</h6>
    <ul>
        <li>Order cancelled before the restaurant begins preparing it</li>
        <li>Wrong items delivered</li>
        <li>Order not delivered within a reasonable time and confirmed lost</li>
    </ul>

    <h6 class="fw-bold mt-3">Not Eligible for Refund</h6>
    <ul>
        <li>Change of mind after the restaurant has started preparing your order</li>
        <li>Delays caused by an incorrect delivery address provided by the customer</li>
    </ul>

    <h6 class="fw-bold mt-3">How Refunds Are Processed</h6>
    <p>Approved refunds for online payments (UPI/Card) are credited back to your original payment method via Razorpay, typically within 5-7 business days. Cash on Delivery orders are not applicable for refunds since payment is collected only on delivery.</p>

    <h6 class="fw-bold mt-3">Requesting a Refund</h6>
    <p>Contact our support team via the Help &amp; Support option in your Profile menu, with your order number, and we'll review your request.</p>
</div>
<?= $this->endSection() ?>
