<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Deliveries — Jeevi</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="<?= base_url('assets/css/style.css') ?>" rel="stylesheet">
</head>
<body>
<nav class="navbar navbar-jeevi">
    <div class="container">
        <span class="navbar-brand"><span class="brand-badge"><img src="<?= base_url('assets/img/logo.svg') ?>" alt="Jeevi Delivery" height="26"></span></span>
        <div>
            <span class="text-white me-3">Hi, <?= esc(session()->get('partner_name')) ?></span>
            <a href="<?= base_url('delivery/logout') ?>" class="btn btn-sm btn-light">Logout</a>
        </div>
    </div>
</nav>

<div class="container my-4">
    <?php if (session()->getFlashdata('success')): ?>
        <div class="alert alert-success"><?= esc(session()->getFlashdata('success')) ?></div>
    <?php endif; ?>
    <?php if (session()->getFlashdata('error')): ?>
        <div class="alert alert-danger"><?= esc(session()->getFlashdata('error')) ?></div>
    <?php endif; ?>

    <div class="card card-jeevi p-3 mb-4">
        <div class="d-flex justify-content-between align-items-center">
            <div>
                <strong>Location Sharing</strong>
                <p class="small text-muted mb-0" id="locationStatus">Requesting permission...</p>
            </div>
            <span id="locationDot" class="badge bg-secondary">Off</span>
        </div>
        <p class="small text-muted mt-2 mb-0">Delivered today: <strong><?= (int)$completed_today ?></strong></p>
    </div>

    <div class="row mb-4">
        <div class="col-6">
            <div class="card card-jeevi p-3 text-center h-100">
                <span class="small text-muted">This Week</span>
                <strong class="fs-5"><?= (int)$weekly_orders ?> orders</strong>
                <span class="small text-muted">₹<?= number_format($weekly_earnings, 2) ?> earned</span>
            </div>
        </div>
        <div class="col-6">
            <div class="card card-jeevi p-3 text-center h-100">
                <span class="small text-muted">This Month</span>
                <strong class="fs-5"><?= (int)$monthly_orders ?> orders</strong>
                <span class="small text-muted">₹<?= number_format($monthly_earnings, 2) ?> earned</span>
            </div>
        </div>
    </div>

    <?php if (!empty($pendingOrders)): ?>
        <div class="d-flex justify-content-between align-items-center mb-2">
            <h5 class="section-title mb-0">New Orders (<?= count($pendingOrders) ?>)</h5>
            <span class="small text-muted">Tap to view · Swipe left to reject</span>
        </div>
        <div id="pendingList">
            <?php foreach ($pendingOrders as $po): ?>
                <div class="pending-swipe-wrap mb-3" data-order-id="<?= $po['id'] ?>"
                     data-reject-url="<?= base_url('delivery/orders/' . $po['id'] . '/reject') ?>"
                     data-details-url="<?= base_url('delivery/orders/' . $po['id']) ?>">
                    <div class="pending-swipe-bg"><i class="bi bi-x-circle-fill"></i> Reject</div>
                    <div class="pending-swipe-card">
                        <div class="pending-card-info">
                            <strong>#<?= esc($po['order_code']) ?></strong>
                            <p class="mb-1 mt-1"><?= esc($po['restaurant_name']) ?> &rarr; <?= esc($po['customer_name']) ?></p>
                            <div class="d-flex align-items-center gap-2 flex-wrap">
                                <?php if ($po['distance_km'] !== null): ?>
                                    <span class="distance-chip"><i class="bi bi-signpost-2"></i> <?= esc($po['distance_km']) ?> km</span>
                                <?php endif; ?>
                                <span class="small text-muted">₹<?= number_format($po['total'], 2) ?></span>
                            </div>
                        </div>
                        <form method="post" action="<?= base_url('delivery/orders/' . $po['id'] . '/accept') ?>" class="pending-accept-form" onclick="event.stopPropagation();">
                            <?= csrf_field() ?>
                            <button type="submit" class="btn btn-jeevi btn-sm">Accept</button>
                        </form>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>

    <h5 class="section-title mb-3">My Active Orders</h5>

    <?php if (empty($orders)): ?>
        <p class="text-muted">No accepted orders in progress right now.</p>
    <?php endif; ?>

    <?php foreach ($orders as $o): ?>
        <div class="card card-jeevi mb-3">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-start">
                    <div>
                        <strong>#<?= esc($o['order_code']) ?></strong>
                        <span class="badge bg-secondary ms-1"><?= order_status_label($o['order_status']) ?></span>
                        <p class="mb-1 mt-1"><?= esc($o['restaurant_name']) ?> &rarr; <?= esc($o['customer_name']) ?></p>
                        <p class="small text-muted mb-0">📞 <?= esc($o['customer_phone']) ?></p>
                        <p class="small text-muted mb-0">Total: ₹<?= number_format($o['total'], 2) ?></p>
                    </div>
                    <a href="<?= base_url('delivery/orders/' . $o['id']) ?>" class="btn btn-sm btn-jeevi-outline">View Details</a>
                </div>

                <form method="post" action="<?= base_url('delivery/orders/' . $o['id'] . '/update-status') ?>" class="mt-3 d-flex gap-2">
                    <?= csrf_field() ?>
                    <select name="order_status" class="form-select form-select-sm" style="max-width: 220px;">
                        <?php foreach (['confirmed', 'preparing', 'out_for_delivery', 'delivered'] as $s): ?>
                            <option value="<?= $s ?>" <?= $o['order_status'] === $s ? 'selected' : '' ?>><?= order_status_label($s) ?></option>
                        <?php endforeach; ?>
                    </select>
                    <button type="submit" class="btn btn-sm btn-jeevi">Update</button>
                </form>
            </div>
        </div>
    <?php endforeach; ?>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
// Shares this device's live GPS position while any order is "out for delivery".
const updateUrl = "<?= base_url('delivery/update-location') ?>";
const csrfName = "<?= csrf_token() ?>";
const csrfHash = "<?= csrf_hash() ?>";
const statusEl = document.getElementById('locationStatus');
const dotEl = document.getElementById('locationDot');

function sendLocation(lat, lng) {
    fetch(updateUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `lat=${lat}&lng=${lng}&${csrfName}=${csrfHash}`
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            statusEl.textContent = 'Sharing location — last sent just now';
            dotEl.textContent = 'Live';
            dotEl.className = 'badge bg-success';
        }
    })
    .catch(() => {
        statusEl.textContent = 'Could not reach server. Will retry.';
    });
}

if (navigator.geolocation) {
    navigator.geolocation.watchPosition(
        (pos) => sendLocation(pos.coords.latitude, pos.coords.longitude),
        (err) => {
            statusEl.textContent = 'Location permission denied. Enable it to share live tracking.';
            dotEl.textContent = 'Off';
            dotEl.className = 'badge bg-danger';
        },
        { enableHighAccuracy: true, maximumAge: 8000, timeout: 10000 }
    );
} else {
    statusEl.textContent = 'Geolocation not supported on this device.';
}

// Swipe-to-reject + tap-to-view on each pending order card, like a messaging app's swipe-to-delete.
document.querySelectorAll('.pending-swipe-wrap').forEach(function (wrap) {
    const card = wrap.querySelector('.pending-swipe-card');
    const orderId = wrap.dataset.orderId;
    const rejectUrl = wrap.dataset.rejectUrl;
    const detailsUrl = wrap.dataset.detailsUrl;

    let dragging = false;
    let startX = 0;
    let currentX = 0;
    let moved = 0;

    function onStart(x, target) {
        if (target.closest('.pending-accept-form')) return;
        dragging = true;
        startX = x;
        currentX = 0;
        moved = 0;
        card.style.transition = 'none';
    }

    function onMove(x) {
        if (!dragging) return;
        currentX = x - startX;
        moved = Math.abs(currentX);
        let translate = Math.min(0, currentX);
        translate = Math.max(translate, -140);
        card.style.transform = `translateX(${translate}px)`;
    }

    function onEnd() {
        if (!dragging) return;
        dragging = false;
        card.style.transition = 'transform .25s ease';

        if (currentX < -90) {
            // Swiped far enough left -> reject
            card.style.transform = 'translateX(-100%)';
            fetch(rejectUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `${csrfName}=${csrfHash}`
            }).finally(function () {
                wrap.style.overflow = 'hidden';
                wrap.style.maxHeight = wrap.offsetHeight + 'px';
                requestAnimationFrame(function () {
                    wrap.style.transition = 'max-height .3s ease, opacity .3s ease, margin .3s ease';
                    wrap.style.maxHeight = '0px';
                    wrap.style.opacity = '0';
                    wrap.style.marginBottom = '0';
                });
                setTimeout(function () { wrap.remove(); }, 320);
            });
        } else if (moved < 10) {
            // Treat as a tap -> go to order details
            window.location.href = detailsUrl;
        } else {
            card.style.transform = 'translateX(0)';
        }
    }

    card.addEventListener('touchstart', function (e) { onStart(e.touches[0].clientX, e.target); }, { passive: true });
    card.addEventListener('touchmove', function (e) { onMove(e.touches[0].clientX); }, { passive: true });
    card.addEventListener('touchend', onEnd);

    // Mouse fallback so this is testable on desktop too
    card.addEventListener('mousedown', function (e) { onStart(e.clientX, e.target); });
    document.addEventListener('mousemove', function (e) { if (dragging) onMove(e.clientX); });
    document.addEventListener('mouseup', onEnd);
});
</script>
</body>
</html>
