<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4">Dashboard <?php if ($is_manager): ?><span class="badge bg-secondary fs-6">Restaurant Manager View</span><?php endif; ?></h3>

<div class="row mb-4">
    <div class="col-md-3 mb-3">
        <div class="card card-jeevi p-3 text-center">
            <h2><?= (int)$total_orders ?></h2><span>Total Orders</span>
        </div>
    </div>
    <?php if (! $is_manager): ?>
        <div class="col-md-3 mb-3">
            <div class="card card-jeevi p-3 text-center">
                <h2><?= (int)$total_restaurants ?></h2><span>Restaurants</span>
            </div>
        </div>
    <?php endif; ?>
    <div class="col-md-3 mb-3">
        <div class="card card-jeevi p-3 text-center">
            <h2><?= (int)$total_menu_items ?></h2><span>Menu Items</span>
        </div>
    </div>
    <?php if (! $is_manager): ?>
        <div class="col-md-3 mb-3">
            <div class="card card-jeevi p-3 text-center">
                <h2><?= (int)$total_users ?></h2><span>Customers</span>
            </div>
        </div>
    <?php endif; ?>
    <div class="col-md-3 mb-3">
        <div class="card card-jeevi p-3 text-center">
            <h2>₹<?= number_format($revenue, 2) ?></h2><span>Revenue (Paid)</span>
        </div>
    </div>
</div>

<h5 class="section-title mb-3"><?= $is_manager ? 'Your Restaurant\'s Recent Orders' : 'Recent Orders' ?></h5>
<div class="card card-jeevi">
    <table class="table mb-0">
        <thead><tr><th>Code</th><th>Status</th><th>Total</th><th>Placed At</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($recent_orders as $o): ?>
            <tr>
                <td><?= esc($o['order_code']) ?></td>
                <td><span class="badge bg-secondary"><?= order_status_label($o['order_status']) ?></span></td>
                <td>₹<?= number_format($o['total'], 2) ?></td>
                <td><?= esc($o['placed_at']) ?></td>
                <td><a href="<?= base_url('admin/orders/' . $o['id']) ?>" class="btn btn-sm btn-jeevi-outline">Manage</a></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?= $this->endSection() ?>
