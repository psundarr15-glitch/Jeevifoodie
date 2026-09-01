<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Categories</h3>
<div class="card card-jeevi p-3 mb-4">
    <form method="post" action="<?= base_url('admin/categories/store') ?>" enctype="multipart/form-data" class="row g-2 align-items-end">
        <?= csrf_field() ?>
        <div class="col-md-3">
            <label class="form-label">Category name (English)</label>
            <input type="text" name="name" class="form-control" placeholder="e.g. Biryani" required>
        </div>
        <div class="col-md-3">
            <label class="form-label">Category name (Tamil)</label>
            <input type="text" name="name_ta" class="form-control" placeholder="e.g. பிரியாணி">
        </div>
        <div class="col-md-4">
            <label class="form-label">Icon image</label>
            <input type="file" name="icon" accept="image/*" class="form-control">
        </div>
        <div class="col-md-2">
            <button class="btn btn-jeevi w-100">Add</button>
        </div>
    </form>
</div>
<div class="card card-jeevi">
    <table class="table mb-0 align-middle">
        <thead><tr><th>Icon</th><th>Name (English)</th><th>Name (Tamil)</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($categories as $c): ?>
            <tr>
                <td>
                    <?php if (! empty($c['icon'])): ?>
                        <img src="<?= esc($c['icon']) ?>" alt="" style="width:40px;height:40px;object-fit:cover;border-radius:50%;">
                    <?php else: ?>
                        <span class="text-muted small">No image</span>
                    <?php endif; ?>
                </td>
                <td><?= esc($c['name']) ?></td>
                <td><?= esc($c['name_ta'] ?? '') ?: '<span class="text-muted small">Not set</span>' ?></td>
                <td class="text-end">
                    <a href="<?= base_url('admin/categories/edit/' . $c['id']) ?>" class="btn btn-sm btn-outline-secondary">Edit</a>
                    <form action="<?= base_url('admin/categories/delete/' . $c['id']) ?>" method="post" class="d-inline" onsubmit="return confirm('Delete?')"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-outline-danger">Delete</button></form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?= $this->endSection() ?>
