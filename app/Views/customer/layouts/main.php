<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $title ?? 'Jeevi Foodie Delivery' ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="<?= base_url('assets/css/style.css') ?>?v=3" rel="stylesheet">
</head>
<body class="has-bottom-nav">

<nav class="navbar navbar-jeevi navbar-expand-lg">
    <div class="container">
        <a class="navbar-brand" href="<?= base_url('/') ?>"><img src="<?= base_url('assets/img/logo.svg') ?>" alt="Jeevi Foodie Delivery" height="34"></a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#nav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="nav">
            <ul class="navbar-nav me-auto">
                <li class="nav-item"><a class="nav-link" href="<?= base_url('/') ?>"><?= t('home') ?></a></li>
                <li class="nav-item"><a class="nav-link" href="<?= base_url('restaurants') ?>"><?= t('restaurants') ?></a></li>
                <?php if (session()->get('logged_in')): ?>
                    <li class="nav-item"><a class="nav-link" href="<?= base_url('orders') ?>"><?= t('my_orders') ?></a></li>
                <?php endif; ?>
            </ul>
            <ul class="navbar-nav ms-auto align-items-lg-center">
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown"><i class="bi bi-globe"></i> <?= t('change_language') ?></a>
                    <ul class="dropdown-menu dropdown-menu-end">
                        <li><a class="dropdown-item" href="<?= base_url('lang/en') ?>">English</a></li>
                        <li><a class="dropdown-item" href="<?= base_url('lang/ta') ?>">தமிழ்</a></li>
                    </ul>
                </li>
                <?php if (session()->get('logged_in')): ?>
                    <li class="nav-item"><a class="nav-link" href="<?= base_url('cart') ?>"><i class="bi bi-cart3"></i> <?= t('cart') ?></a></li>
                    <li class="nav-item"><a class="nav-link" href="<?= base_url('profile') ?>">Hi, <?= esc(session()->get('user_name')) ?></a></li>
                    <li class="nav-item"><a class="nav-link" href="<?= base_url('logout') ?>"><?= t('logout') ?></a></li>
                <?php else: ?>
                    <li class="nav-item"><a class="nav-link" href="<?= base_url('login') ?>"><?= t('login') ?></a></li>
                    <li class="nav-item"><a class="nav-link" href="<?= base_url('register') ?>"><?= t('register') ?></a></li>
                <?php endif; ?>
            </ul>
        </div>
    </div>
</nav>

<?php
// "Deliver to" bar — shows the customer's default saved address if logged in,
// otherwise a generic placeholder. Purely presentational, matches the mockup header.
$deliverAddress = 'Set your delivery address';
if (session()->get('logged_in')) {
    $addr = (new \App\Models\AddressModel())->where('user_id', session()->get('user_id'))->where('is_default', 1)->first();
    if ($addr) {
        $deliverAddress = esc($addr['label']) . ' - ' . esc($addr['address_line']);
    }
}
?>
<div class="deliver-bar">
    <div class="container">
        <div class="d-flex justify-content-between align-items-center">
            <div>
                <div class="deliver-label"><i class="bi bi-geo-alt-fill"></i> Deliver to</div>
                <div class="deliver-address"><?= $deliverAddress ?> <i class="bi bi-chevron-down small"></i></div>
            </div>
        </div>
        <form method="get" action="<?= base_url('restaurants') ?>" class="search-pill">
            <i class="bi bi-search text-muted"></i>
            <input type="text" name="q" placeholder="Search for food, restaurants...">
            <button type="submit" class="filter-btn border-0"><i class="bi bi-sliders"></i></button>
        </form>
    </div>
</div>

<div class="container my-4">
    <?php if (session()->getFlashdata('success')): ?>
        <div class="alert alert-success"><?= esc(session()->getFlashdata('success')) ?></div>
    <?php endif; ?>
    <?php if (session()->getFlashdata('error')): ?>
        <div class="alert alert-danger"><?= esc(session()->getFlashdata('error')) ?></div>
    <?php endif; ?>

    <?= $this->renderSection('content') ?>
</div>

<footer class="footer-jeevi text-center">
    <div class="container">
        <h5 class="text-white">JEEVI FOODIE DELIVERY</h5>
        <p class="mb-1">Good Food, Great Mood</p>
        <small>&copy; <?= date('Y') ?> Jeevi. All rights reserved.</small>
    </div>
</footer>

<?php $current = uri_string() === '' ? '/' : uri_string(); ?>
<nav class="bottom-nav">
    <a href="<?= base_url('/') ?>" class="<?= $current === '/' ? 'active' : '' ?>"><i class="bi bi-house-door-fill"></i>Home</a>
    <a href="<?= base_url('restaurants') ?>" class="<?= str_starts_with($current, 'restaurants') ? 'active' : '' ?>"><i class="bi bi-search"></i>Search</a>
    <a href="<?= base_url('orders') ?>" class="<?= str_starts_with($current, 'orders') || str_starts_with($current, 'order/') ? 'active' : '' ?>"><i class="bi bi-receipt"></i>Orders</a>
    <a href="<?= base_url('cart') ?>" class="<?= $current === 'cart' ? 'active' : '' ?>"><i class="bi bi-cart3"></i>Cart</a>
    <a href="<?= session()->get('logged_in') ? base_url('profile') : base_url('login') ?>" class="<?= $current === 'profile' ? 'active' : '' ?>"><i class="bi bi-person-circle"></i>Profile</a>
</nav>

<?php if (session()->get('logged_in')): ?>
<button type="button" id="chatFab" class="chat-fab" title="Chat with us"><i class="bi bi-headset"></i></button>
<div id="chatPanel" class="chat-panel d-none">
    <div class="chat-panel-header">
        <span>Live Chat — Support</span>
        <button type="button" id="chatClose" class="btn-close btn-close-white" aria-label="Close"></button>
    </div>
    <div id="chatThread" class="chat-panel-thread"></div>
    <form id="chatForm" class="chat-panel-form">
        <input type="text" id="chatInput" placeholder="Type a message…" autocomplete="off">
        <button type="submit"><i class="bi bi-send-fill"></i></button>
    </form>
</div>
<style>
.chat-fab { position: fixed; right: 20px; bottom: 90px; width: 54px; height: 54px; border-radius: 50%; background: var(--jeevi-red, #e53935); color: #fff; border: none; font-size: 1.3rem; box-shadow: 0 4px 14px rgba(0,0,0,.25); z-index: 1050; }
.chat-panel { position: fixed; right: 20px; bottom: 155px; width: 320px; max-width: 90vw; height: 420px; background: #fff; border-radius: 14px; box-shadow: 0 8px 30px rgba(0,0,0,.3); display: flex; flex-direction: column; overflow: hidden; z-index: 1050; }
.chat-panel-header { background: var(--jeevi-red, #e53935); color: #fff; padding: .6rem .9rem; display: flex; justify-content: space-between; align-items: center; font-weight: 600; }
.chat-panel-thread { flex-grow: 1; overflow-y: auto; padding: .6rem; background: #f7f7f7; }
.chat-panel-form { display: flex; border-top: 1px solid #eee; }
.chat-panel-form input { flex-grow: 1; border: none; padding: .6rem; outline: none; }
.chat-panel-form button { border: none; background: none; color: var(--jeevi-red, #e53935); padding: 0 .9rem; }
.chat-bubble { max-width: 78%; margin-bottom: .5rem; padding: .45rem .7rem; border-radius: 10px; font-size: .85rem; }
.chat-bubble.customer { background: var(--jeevi-red, #e53935); color: #fff; margin-left: auto; }
.chat-bubble.support { background: #fff; border: 1px solid #e2e2e2; }
</style>
<script>
(function () {
    const fab = document.getElementById('chatFab');
    const panel = document.getElementById('chatPanel');
    const thread = document.getElementById('chatThread');
    const form = document.getElementById('chatForm');
    const input = document.getElementById('chatInput');
    let pollTimer = null;

    function renderMessages(messages) {
        thread.innerHTML = messages.map(m => `
            <div class="chat-bubble ${m.sender === 'customer' ? 'customer' : 'support'}">${m.message}</div>
        `).join('') || '<p class="text-muted small text-center mt-3">Send us a message — we usually reply within a few minutes.</p>';
        thread.scrollTop = thread.scrollHeight;
    }

    async function poll() {
        try {
            const res = await fetch(`<?= base_url('chat/messages') ?>`);
            const data = await res.json();
            if (data.messages) renderMessages(data.messages);
        } catch (e) { /* ignore transient network errors */ }
    }

    fab.addEventListener('click', () => {
        panel.classList.toggle('d-none');
        if (! panel.classList.contains('d-none')) {
            poll();
            if (! pollTimer) pollTimer = setInterval(poll, 4000);
        }
    });
    document.getElementById('chatClose').addEventListener('click', () => panel.classList.add('d-none'));

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const message = input.value.trim();
        if (! message) return;
        input.value = '';
        try {
            await fetch(`<?= base_url('chat/send') ?>`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'message=' + encodeURIComponent(message) + '&<?= csrf_token() ?>=<?= csrf_hash() ?>'
            });
            poll();
        } catch (e) { /* ignore */ }
    });
})();
</script>
<?php endif; ?>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<?= $this->renderSection('scripts') ?>
</body>
</html>
