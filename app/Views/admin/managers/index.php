<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4">Restaurant Managers</h3>

<div class="card card-jeevi p-4 mb-4">
    <h6 class="fw-bold mb-3">Create Manager Account</h6>
    <form method="post" action="<?= base_url('admin/managers/store') ?>" class="row g-3">
        <?= csrf_field() ?>
        <div class="col-md-3"><input type="text" name="name" class="form-control" placeholder="Full Name" required></div>
        <div class="col-md-3"><input type="email" name="email" class="form-control" placeholder="Email" required></div>
        <div class="col-md-2"><input type="password" name="password" class="form-control" placeholder="Password" required></div>
        <div class="col-md-3">
            <select name="restaurant_id" class="form-select" required>
                <option value="">-- Restaurant --</option>
                <?php foreach ($restaurants as $r): ?>
                    <option value="<?= $r['id'] ?>"><?= esc($r['name']) ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="col-md-1"><button class="btn btn-jeevi w-100">Add</button></div>
    </form>
</div>

<div class="card card-jeevi">
    <table class="table mb-0">
        <thead><tr><th>Name</th><th>Email</th><th>Restaurant</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($managers as $m): ?>
            <tr>
                <td><?= esc($m['name']) ?></td>
                <td><?= esc($m['email']) ?></td>
                <td><?= esc($m['restaurant_name'] ?? '—') ?></td>
                <td><form action="<?= base_url('admin/managers/delete/' . $m['id']) ?>" method="post" class="d-inline" onsubmit="return confirm('Remove this manager account?')"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-outline-danger">Remove</button></form></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?= $this->endSection() ?>
