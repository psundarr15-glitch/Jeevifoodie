<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $title ?? 'Jeevi Admin' ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="<?= base_url('assets/css/style.css') ?>" rel="stylesheet">
    <style>
        .admin-sidebar { min-height: 100vh; background: #1a1a1a; }
        .admin-sidebar a { color: #ccc; display: block; padding: .6rem 1rem; text-decoration: none; }
        .admin-sidebar a:hover, .admin-sidebar a.active { background: var(--jeevi-red); color: #fff; }
    </style>
</head>
<body>
<div class="d-flex">
    <div class="admin-sidebar" style="width: 230px;">
        <div class="p-3"><span class="brand-badge"><img src="<?= base_url('assets/img/logo.svg') ?>" alt="Jeevi Admin" height="30"></span></div>
        <a href="<?= base_url('admin/dashboard') ?>">Dashboard</a>
        <a href="<?= base_url('admin/reports') ?>">Reports</a>
        <a href="<?= base_url('admin/chat') ?>">Live Chat</a>
        <a href="<?= base_url('admin/orders') ?>">Orders</a>
        <a href="<?= base_url('admin/restaurants') ?>">Restaurants</a>
        <a href="<?= base_url('admin/menu-items') ?>">Menu Items</a>
        <a href="<?= base_url('admin/sub-categories') ?>">Sub-Categories</a>
        <?php if (session()->get('admin_role') !== 'restaurant_manager'): ?>
            <a href="<?= base_url('admin/categories') ?>">Categories</a>
            <a href="<?= base_url('admin/coupons') ?>">Coupons</a>
            <a href="<?= base_url('admin/notifications') ?>">Notifications</a>
            <a href="<?= base_url('admin/password-reset-diagnose') ?>">Password Reset Diagnose</a>
            <a href="<?= base_url('admin/delivery-partners') ?>">Delivery Partners</a>
            <a href="<?= base_url('admin/users') ?>">Customers</a>
            <a href="<?= base_url('admin/managers') ?>">Restaurant Managers</a>
        <?php endif; ?>
        <a href="<?= base_url('admin/logout') ?>">Logout</a>
    </div>
    <div class="flex-grow-1 p-4">
        <?php if (session()->getFlashdata('success')): ?>
            <div class="alert alert-success"><?= esc(session()->getFlashdata('success')) ?></div>
        <?php endif; ?>
        <?php if (session()->getFlashdata('error')): ?>
            <div class="alert alert-danger"><?= esc(session()->getFlashdata('error')) ?></div>
        <?php endif; ?>
        <?= $this->renderSection('content') ?>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
