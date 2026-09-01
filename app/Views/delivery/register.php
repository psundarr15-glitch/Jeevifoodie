<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Join as a Delivery Partner — Jeevi</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="<?= base_url('assets/css/style.css') ?>" rel="stylesheet">
</head>
<body style="background:#f7f7f8;">
<div class="container py-4" style="max-width: 460px;">
    <div class="text-center mb-3"><img src="<?= base_url('assets/img/logo.svg') ?>" alt="Jeevi" height="42"></div>

    <div class="card card-jeevi p-4">
        <h4 class="section-title mb-1 text-center">🛵 Join as a Delivery Partner</h4>
        <p class="text-muted small text-center mb-4">Deliver with Jeevi and start earning.</p>

        <?php if (session()->getFlashdata('error')): ?>
            <div class="alert alert-danger"><?= esc(session()->getFlashdata('error')) ?></div>
        <?php endif; ?>

        <form method="post" action="<?= base_url('delivery/register') ?>">
            <?= csrf_field() ?>
            <div class="mb-3">
                <label class="form-label">Full Name</label>
                <input type="text" name="name" class="form-control" value="<?= old('name') ?>" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Email (login)</label>
                <input type="email" name="email" class="form-control" value="<?= old('email') ?>" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Password</label>
                <input type="password" name="password" class="form-control" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Phone Number</label>
                <input type="text" name="phone" class="form-control" value="<?= old('phone') ?>" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Vehicle Number</label>
                <input type="text" name="vehicle_number" class="form-control" placeholder="e.g. TN-30-AB-1234" value="<?= old('vehicle_number') ?>" required>
            </div>
            <button type="submit" class="btn btn-jeevi w-100">Register</button>
        </form>

        <p class="text-center small text-muted mt-3 mb-0">Already registered? <a href="<?= base_url('delivery/login') ?>">Login here</a></p>
    </div>
</div>
</body>
</html>
