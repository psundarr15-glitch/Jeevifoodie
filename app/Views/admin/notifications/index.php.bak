<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Push Notification</h3>

<div class="card card-jeevi p-4 mb-4" style="max-width: 600px;">
    <h6 class="fw-bold mb-3">Send to all customers</h6>
    <p class="text-muted small mb-3">
        Sends an instant push notification to every customer who has the
        app installed and notifications enabled (e.g. "50% off today!").
        This does not go to a specific customer — use it for general
        offers/announcements only.
    </p>
    <form method="post" action="<?= base_url('admin/notifications/send') ?>" enctype="multipart/form-data">
        <?= csrf_field() ?>
        <div class="mb-3">
            <label class="form-label">Title</label>
            <input type="text" name="title" class="form-control" placeholder="e.g. Flat 30% OFF today!" maxlength="60" required>
        </div>
        <div class="mb-3">
            <label class="form-label">Message</label>
            <textarea name="body" class="form-control" rows="3" placeholder="e.g. Use code JEEVI30 on all orders above ₹199. Valid till midnight!" maxlength="150" required></textarea>
        </div>
        <div class="mb-3">
            <label class="form-label">Banner image (optional)</label>
            <input type="file" name="image" class="form-control" accept="image/*">
            <div class="form-text">Shown as a big banner image in the notification. Skip this to send a plain text notification.</div>
        </div>
        <button class="btn btn-jeevi">Send Notification</button>
    </form>
</div>
<?= $this->endSection() ?>
