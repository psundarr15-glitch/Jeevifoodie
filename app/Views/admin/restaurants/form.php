<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4"><?= $restaurant ? 'Edit' : 'Add' ?> Restaurant</h3>

<form method="post" action="<?= $restaurant ? base_url('admin/restaurants/update/' . $restaurant['id']) : base_url('admin/restaurants/store') ?>" enctype="multipart/form-data" class="card card-jeevi p-4">
    <?= csrf_field() ?>
    <div class="row">
        <div class="col-md-6 mb-3">
            <label class="form-label">Restaurant Name</label>
            <input type="text" name="name" class="form-control" value="<?= esc($restaurant['name'] ?? '') ?>" required>
        </div>
        <div class="col-md-6 mb-3">
            <label class="form-label">Owner Name</label>
            <input type="text" name="owner_name" class="form-control" value="<?= esc($restaurant['owner_name'] ?? '') ?>">
        </div>
        <div class="col-md-6 mb-3">
            <label class="form-label">Restaurant Phone</label>
            <input type="text" name="phone" class="form-control" value="<?= esc($restaurant['phone'] ?? '') ?>" placeholder="For delivery partner to call">
        </div>
        <div class="col-md-6 mb-3">
            <label class="form-label">Owner Mobile Number</label>
            <input type="text" name="owner_phone" class="form-control" value="<?= esc($restaurant['owner_phone'] ?? '') ?>">
        </div>
        <div class="col-md-6 mb-3">
            <label class="form-label">Cuisine</label>
            <input type="text" name="cuisine" class="form-control" value="<?= esc($restaurant['cuisine'] ?? '') ?>" placeholder="e.g. South Indian, Chinese">
        </div>
        <div class="col-md-6 mb-3">
            <label class="form-label">Restaurant Type</label>
            <input type="text" name="restaurant_type" class="form-control" value="<?= esc($restaurant['restaurant_type'] ?? '') ?>" placeholder="e.g. Restaurant, Cafe, Cloud Kitchen, Bakery">
        </div>
        <div class="col-md-6 mb-3">
            <label class="form-label">Veg / Non-Veg</label>
            <select name="food_type" class="form-select">
                <?php foreach (['veg' => 'Veg only', 'non_veg' => 'Non-Veg only', 'both' => 'Veg & Non-Veg'] as $val => $label): ?>
                    <option value="<?= $val ?>" <?= ($restaurant['food_type'] ?? 'both') === $val ? 'selected' : '' ?>><?= $label ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="col-12 mb-3">
            <label class="form-label">Restaurant Banner</label><br>
            <?php if (! empty($restaurant['image'])): ?>
                <img src="<?= esc($restaurant['image']) ?>" alt="" style="width:130px;height:100px;object-fit:cover;border-radius:8px;" class="mb-2 d-block">
            <?php endif; ?>
            <input type="file" name="image" accept="image/*" class="form-control" style="max-width:400px;">
            <div class="form-text">Wide banner image shown on the restaurant's card (ratio ~1.3). Leave empty to keep the current one.</div>
        </div>
        <div class="col-12 mb-3">
            <label class="form-label">Restaurant Logo</label><br>
            <?php if (! empty($restaurant['logo'])): ?>
                <img src="<?= esc($restaurant['logo']) ?>" alt="" style="width:80px;height:72px;object-fit:cover;border-radius:8px;" class="mb-2 d-block">
            <?php endif; ?>
            <input type="file" name="logo" accept="image/*" class="form-control" style="max-width:400px;">
            <div class="form-text">Square-ish logo (ratio ~1.1). Leave empty to keep the current one.</div>
        </div>
        <div class="col-12 mb-3">
            <label class="form-label">Description <span class="text-muted small">(optional)</span></label>
            <textarea name="description" class="form-control"><?= esc($restaurant['description'] ?? '') ?></textarea>
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Prep Time Min</label>
            <input type="number" name="prep_time_min" class="form-control" value="<?= esc($restaurant['prep_time_min'] ?? 20) ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Prep Time Max</label>
            <input type="number" name="prep_time_max" class="form-control" value="<?= esc($restaurant['prep_time_max'] ?? 40) ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Cost for Two</label>
            <input type="number" name="cost_for_two" class="form-control" value="<?= esc($restaurant['cost_for_two'] ?? 0) ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Discount Label</label>
            <input type="text" name="discount_label" class="form-control" value="<?= esc($restaurant['discount_label'] ?? '') ?>" placeholder="e.g. 40% OFF">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Opening Time</label>
            <input type="time" name="opening_time" class="form-control" value="<?= esc(isset($restaurant['opening_time']) ? substr($restaurant['opening_time'], 0, 5) : '09:00') ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Closing Time</label>
            <input type="time" name="closing_time" class="form-control" value="<?= esc(isset($restaurant['closing_time']) ? substr($restaurant['closing_time'], 0, 5) : '23:00') ?>">
            <div class="form-text">If closing is earlier than opening, it's treated as past midnight.</div>
        </div>
        <div class="col-md-6 mb-3">
            <label class="form-label">Restaurant Address</label>
            <input type="text" name="address" class="form-control" value="<?= esc($restaurant['address'] ?? '') ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Latitude</label>
            <input type="text" name="lat" class="form-control" value="<?= esc($restaurant['lat'] ?? '') ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Longitude</label>
            <input type="text" name="lng" class="form-control" value="<?= esc($restaurant['lng'] ?? '') ?>">
            <div class="form-text">Set from the app's map picker at sign-up; edit here if it needs correcting.</div>
        </div>

        <div class="col-12"><hr class="my-2"><h5>Compliance</h5></div>
        <div class="col-md-3 mb-3">
            <label class="form-label">FSSAI Number</label>
            <input type="text" name="fssai_number" class="form-control" value="<?= esc($restaurant['fssai_number'] ?? '') ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">FSSAI Certificate</label><br>
            <?php if (! empty($restaurant['fssai_certificate'])): ?>
                <a href="<?= esc($restaurant['fssai_certificate']) ?>" target="_blank" class="d-block small mb-1">View current</a>
            <?php endif; ?>
            <input type="file" name="fssai_certificate" class="form-control">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">TIN Number</label>
            <input type="text" name="tin_number" class="form-control" value="<?= esc($restaurant['tin_number'] ?? '') ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">TIN Certificate</label><br>
            <?php if (! empty($restaurant['tin_certificate'])): ?>
                <a href="<?= esc($restaurant['tin_certificate']) ?>" target="_blank" class="d-block small mb-1">View current</a>
            <?php endif; ?>
            <input type="file" name="tin_certificate" class="form-control">
        </div>

        <div class="col-12"><hr class="my-2"><h5>Bank Details <span class="text-muted small">(optional)</span></h5></div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Account Number</label>
            <input type="text" name="bank_account_number" class="form-control" value="<?= esc($restaurant['bank_account_number'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">IFSC Code</label>
            <input type="text" name="bank_ifsc" class="form-control" value="<?= esc($restaurant['bank_ifsc'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Account Holder Name</label>
            <input type="text" name="bank_account_holder" class="form-control" value="<?= esc($restaurant['bank_account_holder'] ?? '') ?>">
        </div>

        <div class="col-12 mb-3 form-check">
            <input type="checkbox" name="is_active" class="form-check-input" id="is_active" <?= (!$restaurant || $restaurant['is_active']) ? 'checked' : '' ?>>
            <label class="form-check-label" for="is_active">Active</label>
        </div>
    </div>
    <button type="submit" class="btn btn-jeevi">Save Restaurant</button>
</form>

<?= $this->endSection() ?>
