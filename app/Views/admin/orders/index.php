<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4">Orders</h3>

<div class="card card-jeevi">
    <table class="table mb-0">
        <thead><tr><th>Code</th><th>Customer</th><th>Restaurant</th><th>Total</th><th>Status</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($orders as $o): ?>
            <tr>
                <td><?= esc($o['order_code']) ?></td>
                <td><?= esc($o['customer_name']) ?></td>
                <td><?= esc($o['restaurant_name']) ?></td>
                <td>₹<?= number_format($o['total'], 2) ?></td>
                <td><span class="badge bg-secondary"><?= order_status_label($o['order_status']) ?></span></td>
                <td><a href="<?= base_url('admin/orders/' . $o['id']) ?>" class="btn btn-sm btn-jeevi-outline">Manage</a></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?= $this->endSection() ?>
