<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Coupons</h3>

<div class="card card-jeevi p-4 mb-4">
    <h6 class="fw-bold mb-3">Create Coupon</h6>
    <form method="post" action="<?= base_url('admin/coupons/store') ?>" class="row g-3">
        <?= csrf_field() ?>
        <div class="col-md-3"><input type="text" name="code" class="form-control" placeholder="CODE" required></div>
        <div class="col-md-3">
            <select name="discount_type" class="form-select">
                <option value="percent">Percent %</option>
                <option value="flat">Flat ₹</option>
            </select>
        </div>
        <div class="col-md-2"><input type="number" step="0.01" name="discount_value" class="form-control" placeholder="Value" required></div>
        <div class="col-md-2"><input type="number" step="0.01" name="min_order_value" class="form-control" placeholder="Min Order"></div>
        <div class="col-md-2"><input type="number" step="0.01" name="max_discount" class="form-control" placeholder="Max Discount"></div>
        <div class="col-12"><input type="text" name="description" class="form-control" placeholder="Description shown to customers"></div>
        <div class="col-12"><button class="btn btn-jeevi">Create Coupon</button></div>
    </form>
</div>

<div class="card card-jeevi">
    <table class="table mb-0">
        <thead><tr><th>Code</th><th>Type</th><th>Value</th><th>Status</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($coupons as $c): ?>
            <tr>
                <td><?= esc($c['code']) ?></td>
                <td><?= esc($c['discount_type']) ?></td>
                <td><?= esc($c['discount_value']) ?></td>
                <td><?= $c['is_active'] ? '<span class="badge bg-success">Active</span>' : '<span class="badge bg-secondary">Inactive</span>' ?></td>
                <td>
                    <form action="<?= base_url('admin/coupons/toggle/' . $c['id']) ?>" method="post" class="d-inline"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-jeevi-outline">Toggle</button></form>
                    <form action="<?= base_url('admin/coupons/delete/' . $c['id']) ?>" method="post" class="d-inline" onsubmit="return confirm('Delete?')"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-outline-danger">Delete</button></form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?= $this->endSection() ?>
