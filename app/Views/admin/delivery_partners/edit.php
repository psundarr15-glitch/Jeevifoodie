<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Delivery Partner - <?= esc($partner['name']) ?></h3>

<form method="post" action="<?= base_url('admin/delivery-partners/update/' . $partner['id']) ?>" enctype="multipart/form-data" class="card card-jeevi p-4">
    <?= csrf_field() ?>

    <h5>Personal Details</h5>
    <div class="row">
        <div class="col-md-4 mb-3">
            <label class="form-label">Full Name</label>
            <input type="text" name="name" class="form-control" value="<?= esc($partner['name']) ?>" required>
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Mobile Number</label>
            <input type="text" name="phone" class="form-control" value="<?= esc($partner['phone']) ?>" required>
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Email</label>
            <input type="email" class="form-control" value="<?= esc($partner['email'] ?? '') ?>" disabled>
            <div class="form-text">Email is set at sign-up and can't be changed here.</div>
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Date of Birth</label>
            <input type="date" name="dob" class="form-control" value="<?= esc($partner['dob'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">City / Town</label>
            <input type="text" name="city" class="form-control" value="<?= esc($partner['city'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">District</label>
            <input type="text" name="district" class="form-control" value="<?= esc($partner['district'] ?? '') ?>">
        </div>
        <div class="col-md-3 mb-3">
            <label class="form-label">Pincode</label>
            <input type="text" name="pincode" class="form-control" value="<?= esc($partner['pincode'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Profile Photo</label><br>
            <?php if (! empty($partner['photo'])): ?>
                <img src="<?= esc($partner['photo']) ?>" alt="" style="width:64px;height:64px;object-fit:cover;border-radius:50%;" class="mb-2 d-block">
            <?php endif; ?>
            <input type="file" name="photo" accept="image/*" class="form-control">
        </div>
    </div>

    <hr class="my-4">
    <h5>Identity & Vehicle</h5>
    <div class="row">
        <div class="col-md-4 mb-3">
            <label class="form-label">Aadhaar Number</label>
            <input type="text" name="aadhaar_number" class="form-control" value="<?= esc($partner['aadhaar_number'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Aadhaar / ID Proof document</label><br>
            <?php if (! empty($partner['id_proof_document'])): ?>
                <a href="<?= esc($partner['id_proof_document']) ?>" target="_blank" class="d-block small mb-2">View current document</a>
            <?php endif; ?>
            <input type="file" name="id_proof_document" class="form-control">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Driving Licence Number</label>
            <input type="text" name="license_number" class="form-control" value="<?= esc($partner['license_number'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Vehicle Type</label>
            <select name="vehicle_type" class="form-select">
                <?php foreach (['bike' => 'Bike', 'scooter' => 'Scooter', 'bicycle' => 'Bicycle', 'car' => 'Car'] as $val => $label): ?>
                    <option value="<?= $val ?>" <?= ($partner['vehicle_type'] ?? '') === $val ? 'selected' : '' ?>><?= $label ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Vehicle Number</label>
            <input type="text" name="vehicle_number" class="form-control" value="<?= esc($partner['vehicle_number'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">RC Number</label>
            <input type="text" name="rc_number" class="form-control" value="<?= esc($partner['rc_number'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">RC Document</label><br>
            <?php if (! empty($partner['rc_document'])): ?>
                <a href="<?= esc($partner['rc_document']) ?>" target="_blank" class="d-block small mb-2">View current document</a>
            <?php endif; ?>
            <input type="file" name="rc_document" class="form-control">
        </div>
    </div>

    <hr class="my-4">
    <h5>Bank Details <span class="text-muted small">(optional)</span></h5>
    <div class="row">
        <div class="col-md-4 mb-3">
            <label class="form-label">Account Number</label>
            <input type="text" name="bank_account_number" class="form-control" value="<?= esc($partner['bank_account_number'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">IFSC Code</label>
            <input type="text" name="bank_ifsc" class="form-control" value="<?= esc($partner['bank_ifsc'] ?? '') ?>">
        </div>
        <div class="col-md-4 mb-3">
            <label class="form-label">Account Holder Name</label>
            <input type="text" name="bank_account_holder" class="form-control" value="<?= esc($partner['bank_account_holder'] ?? '') ?>">
        </div>
    </div>

    <button class="btn btn-jeevi">Save</button>
    <a href="<?= base_url('admin/delivery-partners') ?>" class="btn btn-outline-secondary">Back</a>
</form>
<?= $this->endSection() ?>
