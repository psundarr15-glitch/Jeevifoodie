<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>
<div class="row justify-content-center">
    <div class="col-md-5">
        <div class="card card-jeevi p-4">
            <h4 class="section-title mb-3 text-center">Login to Jeevi</h4>
            <form method="post" action="<?= base_url('login') ?>">
                <?= csrf_field() ?>
                <div class="mb-3">
                    <label class="form-label">Email</label>
                    <input type="email" name="email" class="form-control" required>
                </div>
                <div class="mb-3">
                    <label class="form-label">Password</label>
                    <input type="password" name="password" class="form-control" required>
                </div>
                <button type="submit" class="btn btn-jeevi w-100">Login</button>
            </form>
            <p class="text-center mt-3 mb-0">No account? <a href="<?= base_url('register') ?>">Register</a></p>
            <p class="text-center text-muted small mt-2">Demo login: demo@jeevi.com / demo123</p>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
