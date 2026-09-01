<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Delivery Partners</h3>

<div class="card card-jeevi p-4 mb-4">
    <form method="post" action="<?= base_url('admin/delivery-partners/store') ?>" class="row g-3">
        <?= csrf_field() ?>
        <div class="col-md-4"><input type="text" name="name" class="form-control" placeholder="Name" required></div>
        <div class="col-md-4"><input type="text" name="phone" class="form-control" placeholder="Phone" required></div>
        <div class="col-md-3"><input type="text" name="vehicle_number" class="form-control" placeholder="Vehicle Number"></div>
        <div class="col-md-1"><button class="btn btn-jeevi w-100">Add</button></div>
    </form>
</div>

<div class="card card-jeevi">
    <table class="table mb-0">
        <thead><tr><th>Name</th><th>Phone</th><th>Vehicle</th><th>Rating</th><th>Available</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($partners as $p): ?>
            <tr>
                <td><?= esc($p['name']) ?></td>
                <td><?= esc($p['phone']) ?></td>
                <td><?= esc($p['vehicle_number']) ?></td>
                <td><?= $p['rating_count'] > 0 ? '★ ' . esc($p['rating']) . ' (' . (int)$p['rating_count'] . ')' : '<span class="text-muted">No ratings yet</span>' ?></td>
                <td><?= $p['is_available'] ? '<span class="badge bg-success">Yes</span>' : '<span class="badge bg-secondary">No</span>' ?></td>
                <td>
                    <a href="<?= base_url('admin/delivery-partners/edit/' . $p['id']) ?>" class="btn btn-sm btn-outline-secondary">Edit / KYC</a>
                    <form action="<?= base_url('admin/delivery-partners/delete/' . $p['id']) ?>" method="post" class="d-inline" onsubmit="return confirm('Delete?')"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-outline-danger">Delete</button></form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?= $this->endSection() ?>
