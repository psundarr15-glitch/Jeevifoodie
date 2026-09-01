<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4"><?= $item ? 'Edit' : 'Add' ?> Menu Item</h3>

<form method="post" action="<?= $item ? base_url('admin/menu-items/update/' . $item['id']) : base_url('admin/menu-items/store') ?>" enctype="multipart/form-data" class="card card-jeevi p-4">
    <?= csrf_field() ?>
    <div class="row">
        <div class="col-md-6 mb-3">
            <label class="form-label">Restaurant</label>
            <select name="restaurant_id" class="form-select" required>
                <?php foreach ($restaurants as $r): ?>
                    <option value="<?= $r['id'] ?>" <?= (isset($item) && $item['restaurant_id'] == $r['id']) ? 'selected' : '' ?>><?= esc($r['name']) ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="col-md-6 mb-3">
            <label class="form-label">Sub-Category</label>
            <select name="sub_category_id" class="form-select">
                <option value="">-- None --</option>
                <?php foreach ($subCategories as $sc): ?>
                    <option value="<?= $sc['id'] ?>" <?= (isset($item) && $item['sub_category_id'] == $sc['id']) ? 'selected' : '' ?>>
                        <?= esc($sc['name']) ?><?= empty($restaurants) || count($restaurants) > 1 ? ' (' . esc($sc['restaurant_name']) . ')' : '' ?>
                    </option>
                <?php endforeach; ?>
            </select>
            <div class="form-text">No sub-category yet for this restaurant? Add one under "Sub-Categories" in the sidebar first.</div>
        </div>
        <div class="col-md-8 mb-3">
            <label class="form-label">Item Name</label>
            <input type="text" name="name" class="form-control" value="<?= esc($item['name'] ?? '') ?>" required>
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Price (₹)</label>
            <input type="number" step="0.01" name="price" class="form-control" value="<?= esc($item['price'] ?? '') ?>" required>
        </div>
        <div class="col-12 mb-3">
            <label class="form-label">Item image</label><br>
            <?php if (! empty($item['image'])): ?>
                <img src="<?= esc($item['image']) ?>" alt="" style="width:100px;height:75px;object-fit:cover;border-radius:8px;" class="mb-2 d-block">
            <?php endif; ?>
            <input type="file" name="image" accept="image/*" class="form-control" style="max-width:400px;">
            <div class="form-text">Shown on the item card in the app. Leave empty to keep the current image.</div>
        </div>
        <div class="col-12 mb-3">
            <label class="form-label">Description</label>
            <textarea name="description" class="form-control"><?= esc($item['description'] ?? '') ?></textarea>
        </div>
        <div class="col-md-3 mb-3 form-check">
            <input type="checkbox" name="is_veg" class="form-check-input" id="is_veg" <?= (!isset($item) || $item['is_veg']) ? 'checked' : '' ?>>
            <label class="form-check-label" for="is_veg">Vegetarian</label>
        </div>
        <div class="col-md-3 mb-3 form-check">
            <input type="checkbox" name="is_available" class="form-check-input" id="is_available" <?= (!isset($item) || $item['is_available']) ? 'checked' : '' ?>>
            <label class="form-check-label" for="is_available">Available</label>
        </div>
    </div>
    <button type="submit" class="btn btn-jeevi">Save Item</button>
</form>

<?= $this->endSection() ?>
