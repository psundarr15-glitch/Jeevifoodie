<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>
<div class="card card-jeevi p-4">
    <h4 class="section-title mb-3">Privacy Policy</h4>
    <p class="text-muted small">Last updated: <?= date('F Y') ?></p>

    <h6 class="fw-bold mt-3">Information We Collect</h6>
    <p>We collect your name, phone number, email, delivery address, and order history to provide our delivery service. Your delivery location is used only to route your order and is shared with your assigned delivery partner during active deliveries.</p>

    <h6 class="fw-bold mt-3">How We Use Your Information</h6>
    <p>Your information is used to process orders, provide live order tracking, communicate order updates, and improve our service. We do not sell your personal information to third parties.</p>

    <h6 class="fw-bold mt-3">Payment Information</h6>
    <p>Card and UPI payments are processed directly by Razorpay, our payment partner. We never see or store your full card details.</p>

    <h6 class="fw-bold mt-3">Your Choices</h6>
    <p>You can update your profile details or delete a saved address at any time from your Profile page. To request full account deletion, please contact support.</p>
</div>
<?= $this->endSection() ?>
