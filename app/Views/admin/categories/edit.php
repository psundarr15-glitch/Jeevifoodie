<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Edit Category</h3>

<form method="post" action="<?= base_url('admin/categories/update/' . $category['id']) ?>" enctype="multipart/form-data" class="card card-jeevi p-4" style="max-width: 600px;">
    <?= csrf_field() ?>
    <div class="mb-3">
        <label class="form-label">Category name (English)</label>
        <input type="text" name="name" class="form-control" value="<?= esc($category['name']) ?>" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Category name (Tamil)</label>
        <input type="text" name="name_ta" class="form-control" value="<?= esc($category['name_ta'] ?? '') ?>" placeholder="e.g. பிரியாணி">
    </div>
    <div class="mb-3">
        <label class="form-label">Icon image</label><br>
        <?php if (! empty($category['icon'])): ?>
            <img src="<?= esc($category['icon']) ?>" alt="" style="width:64px;height:64px;object-fit:cover;border-radius:50%;" class="mb-2">
        <?php endif; ?>
        <input type="file" name="icon" accept="image/*" class="form-control">
        <div class="form-text">Leave empty to keep the current image.</div>
    </div>
    <button class="btn btn-jeevi">Save Category</button>
    <a href="<?= base_url('admin/categories') ?>" class="btn btn-outline-secondary">Cancel</a>
</form>
<?= $this->endSection() ?>
