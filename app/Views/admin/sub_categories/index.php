<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Sub-Categories</h3>
<p class="text-muted small mb-3">
    Sub-categories group your own menu items under one of the app's main categories - e.g. under
    "Indian Food" you might add "Biryani", then list Chicken Biryani, Mutton Biryani, and Veg Biryani
    as menu items inside it.
</p>

<div class="card card-jeevi p-3 mb-4">
    <form method="post" action="<?= base_url('admin/sub-categories/store') ?>" class="row g-2 align-items-end">
        <?= csrf_field() ?>
        <?php if (! $isManager): ?>
            <div class="col-md-3">
                <label class="form-label">Restaurant</label>
                <select name="restaurant_id" class="form-select" required>
                    <?php foreach ($restaurants as $r): ?>
                        <option value="<?= $r['id'] ?>"><?= esc($r['name']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        <?php endif; ?>
        <div class="col-md-3">
            <label class="form-label">Main Category</label>
            <select name="category_id" class="form-select" required>
                <?php foreach ($categories as $c): ?>
                    <option value="<?= $c['id'] ?>"><?= esc($c['name']) ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="col-md-3">
            <label class="form-label">Sub-category name (English)</label>
            <input type="text" name="name" class="form-control" placeholder="e.g. Biryani" required>
        </div>
        <div class="col-md-2">
            <label class="form-label">Name (Tamil)</label>
            <input type="text" name="name_ta" class="form-control" placeholder="பிரியாணி">
        </div>
        <div class="col-md-1">
            <button class="btn btn-jeevi w-100">Add</button>
        </div>
    </form>
</div>

<div class="card card-jeevi">
    <table class="table mb-0 align-middle">
        <thead>
        <tr>
            <?php if (! $isManager): ?><th>Restaurant</th><?php endif; ?>
            <th>Main Category</th>
            <th>Sub-category (English)</th>
            <th>Sub-category (Tamil)</th>
            <th></th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($subCategories as $sc): ?>
            <tr>
                <?php if (! $isManager): ?><td><?= esc($sc['restaurant_name']) ?></td><?php endif; ?>
                <td><?= esc($sc['category_name']) ?></td>
                <td><?= esc($sc['name']) ?></td>
                <td><?= esc($sc['name_ta'] ?? '') ?: '<span class="text-muted small">Not set</span>' ?></td>
                <td class="text-end">
                    <form action="<?= base_url('admin/sub-categories/delete/' . $sc['id']) ?>" method="post" class="d-inline" onsubmit="return confirm('Delete?')"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-outline-danger">Delete</button></form>
                </td>
            </tr>
        <?php endforeach; ?>
        <?php if (empty($subCategories)): ?>
            <tr><td colspan="5" class="text-center text-muted py-3">No sub-categories yet.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>
</div>
<?= $this->endSection() ?>
