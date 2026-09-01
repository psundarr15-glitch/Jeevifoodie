<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>
<div class="card card-jeevi p-4">
    <h4 class="section-title mb-3">Shipping / Delivery Policy</h4>
    <p class="text-muted small">Last updated: <?= date('F Y') ?></p>

    <h6 class="fw-bold mt-3">Delivery Area</h6>
    <p>Jeevi Foodie Delivery currently delivers only within Salem district. During checkout, you'll need to pick a delivery location on the map within our serviceable boundary.</p>

    <h6 class="fw-bold mt-3">Delivery Time</h6>
    <p>Estimated delivery time is shown on your order tracking page and typically ranges from 20-40 minutes, depending on the restaurant's preparation time and distance to your location.</p>

    <h6 class="fw-bold mt-3">Delivery Fee</h6>
    <p>Orders above ₹199 qualify for free delivery. A flat delivery fee of ₹30 applies to smaller orders.</p>

    <h6 class="fw-bold mt-3">Live Tracking</h6>
    <p>Once your order is out for delivery, you can track your delivery partner's live location from your Order Tracking page.</p>
</div>
<?= $this->endSection() ?>
