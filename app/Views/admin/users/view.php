<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4"><?= esc($user['name']) ?></h3>

<div class="row">
    <div class="col-md-5 mb-4">
        <div class="card card-jeevi p-4">
            <h6 class="fw-bold mb-3">Details</h6>
            <p class="mb-1"><strong>Email:</strong> <?= esc($user['email']) ?></p>
            <p class="mb-1"><strong>Phone:</strong> <?= esc($user['phone']) ?></p>
            <a href="<?= base_url('admin/users/edit/' . $user['id']) ?>" class="btn btn-jeevi mt-2">Edit User</a>
        </div>

        <div class="card card-jeevi p-4 mt-3">
            <h6 class="fw-bold mb-3">Saved Addresses</h6>
            <?php if (empty($addresses)): ?>
                <p class="text-muted small mb-0">No saved addresses.</p>
            <?php endif; ?>
            <?php foreach ($addresses as $addr): ?>
                <div class="border-bottom py-2">
                    <strong><?= esc($addr['label']) ?></strong> <?= $addr['is_default'] ? '<span class="badge bg-success">Default</span>' : '' ?>
                    <p class="small text-muted mb-0"><?= esc($addr['address_line']) ?>, <?= esc($addr['city']) ?>, <?= esc($addr['state']) ?> - <?= esc($addr['pincode']) ?></p>
                </div>
            <?php endforeach; ?>
        </div>
    </div>

    <div class="col-md-7 mb-4">
        <div class="card card-jeevi p-4">
            <h6 class="fw-bold mb-3">Order History</h6>
            <?php if (empty($orders)): ?>
                <p class="text-muted small mb-0">No orders yet.</p>
            <?php endif; ?>
            <table class="table table-sm mb-0">
                <thead><tr><th>Code</th><th>Status</th><th>Total</th><th>Placed At</th></tr></thead>
                <tbody>
                <?php foreach ($orders as $o): ?>
                    <tr>
                        <td><?= esc($o['order_code']) ?></td>
                        <td><span class="badge bg-secondary"><?= order_status_label($o['order_status']) ?></span></td>
                        <td>₹<?= number_format($o['total'], 2) ?></td>
                        <td><?= esc($o['placed_at']) ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?= $this->endSection() ?>
