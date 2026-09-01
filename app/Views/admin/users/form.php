<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4">Edit Customer</h3>

<form method="post" action="<?= base_url('admin/users/update/' . $user['id']) ?>" class="card card-jeevi p-4" style="max-width: 500px;">
    <?= csrf_field() ?>
    <div class="mb-3">
        <label class="form-label">Name</label>
        <input type="text" name="name" class="form-control" value="<?= esc($user['name']) ?>" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Email</label>
        <input type="email" name="email" class="form-control" value="<?= esc($user['email']) ?>" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Phone</label>
        <input type="text" name="phone" class="form-control" value="<?= esc($user['phone']) ?>" required>
    </div>
    <div class="mb-3">
        <label class="form-label">New Password</label>
        <input type="password" name="new_password" class="form-control" placeholder="Leave blank to keep current password">
    </div>
    <button type="submit" class="btn btn-jeevi">Save Changes</button>
</form>

<?= $this->endSection() ?>
