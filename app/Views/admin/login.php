<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Jeevi Admin Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="<?= base_url('assets/css/style.css') ?>" rel="stylesheet">
</head>
<body class="bg-dark">
<div class="container d-flex align-items-center justify-content-center" style="min-height:100vh;">
    <div class="card card-jeevi p-4" style="width: 400px;">
        <div class="text-center mb-3"><img src="<?= base_url('assets/img/logo.svg') ?>" alt="Jeevi" height="42"></div>
        <?php if (session()->getFlashdata('error')): ?>
            <div class="alert alert-danger"><?= esc(session()->getFlashdata('error')) ?></div>
        <?php endif; ?>
        <?php if (session()->getFlashdata('success')): ?>
            <div class="alert alert-success"><?= esc(session()->getFlashdata('success')) ?></div>
        <?php endif; ?>
        <form method="post" action="<?= base_url('admin/login') ?>">
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
        <p class="text-center text-muted small mt-3">Demo login: admin@jeevi.com / admin123</p>
        <p class="text-center small mt-2 mb-0"><a href="<?= base_url('restaurant/register') ?>">Own a restaurant? Register it here</a></p>
    </div>
</div>
</body>
</html>
