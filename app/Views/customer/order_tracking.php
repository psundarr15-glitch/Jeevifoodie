<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />

<div class="d-flex justify-content-between align-items-center mb-3">
    <h4 class="section-title mb-0">Order #<?= esc($order['order_code']) ?></h4>
    <span id="statusBadge" class="badge bg-danger fs-6"><?= order_status_label($order['order_status']) ?></span>
</div>

<?php if ($restaurant): ?>
<div class="mb-3">
    <button type="button" id="restaurantChatFab" class="btn btn-jeevi-outline btn-sm"><i class="bi bi-chat-dots"></i> Chat with <?= esc($restaurant['name']) ?> about this order</button>
</div>
<div id="restaurantChatPanel" class="chat-panel d-none" style="position: static; width: 100%; max-width: 100%; height: 340px; margin-bottom: 1rem;">
    <div class="chat-panel-header">
        <span>Chat — <?= esc($restaurant['name']) ?></span>
        <button type="button" id="restaurantChatClose" class="btn-close btn-close-white" aria-label="Close"></button>
    </div>
    <div id="restaurantChatThread" class="chat-panel-thread"></div>
    <form id="restaurantChatForm" class="chat-panel-form">
        <input type="text" id="restaurantChatInput" placeholder="Describe the issue with this order…" autocomplete="off">
        <button type="submit"><i class="bi bi-send-fill"></i></button>
    </form>
</div>
<?php endif; ?>

<div class="card card-jeevi mb-4">
    <div class="card-body">
        <div class="d-flex justify-content-between flex-wrap" id="statusTimeline">
            <?php
            $flow = ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'];
            $currentIndex = array_search($order['order_status'], $flow);
            ?>
            <?php foreach ($flow as $i => $step): ?>
                <div class="status-step <?= $currentIndex !== false && $i < $currentIndex ? 'done' : '' ?> <?= $currentIndex !== false && $i === $currentIndex ? 'active' : '' ?>" data-step="<?= $step ?>">
                    <?php if ($i > 0): ?><div class="status-line"></div><?php endif; ?>
                    <div class="dot"><?= $i + 1 ?></div>
                    <small><?= order_status_label($step) ?></small>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-7 mb-4">
        <div class="card card-jeevi">
            <div class="card-body">
                <h6 class="fw-bold mb-2">Live Tracking</h6>
                <div id="trackingMap"></div>
                <p class="small text-muted mt-2 mb-0" id="etaText">Estimated delivery: <?= (int)$order['estimated_delivery_min'] ?> mins</p>
                <p class="small mb-0" id="partnerInfo" style="<?= $partner ? '' : 'display:none;' ?>">Delivery Partner: <strong id="partnerName"><?= $partner ? esc($partner['name']) : '' ?></strong> &bull; <span id="partnerPhone"><?= $partner ? esc($partner['phone']) : '' ?></span></p>
                <p class="small text-muted mb-0" id="partnerPendingText" style="<?= $partner ? 'display:none;' : '' ?>">Waiting for a delivery partner to accept your order...</p>
            </div>
        </div>
    </div>

    <div class="col-md-5 mb-4">
        <div class="card card-jeevi mb-3">
            <div class="card-body">
                <h6 class="fw-bold mb-2">Order Items</h6>
                <?php foreach ($items as $it): ?>
                    <div class="d-flex justify-content-between">
                        <span><?= esc($it['item_name']) ?> x <?= (int)$it['quantity'] ?></span>
                        <span>₹<?= number_format($it['price'] * $it['quantity'], 2) ?></span>
                    </div>
                <?php endforeach; ?>
                <hr>
                <div class="d-flex justify-content-between fw-bold"><span>Total</span><span>₹<?= number_format($order['total'], 2) ?></span></div>
            </div>
        </div>

        <div class="card card-jeevi">
            <div class="card-body">
                <h6 class="fw-bold mb-2">Status History</h6>
                <ul class="list-unstyled small mb-0" id="historyList">
                    <?php foreach ($history as $h): ?>
                        <li class="mb-2">
                            <strong><?= order_status_label($h['status']) ?></strong> — <?= esc($h['note']) ?>
                            <br><span class="text-muted"><?= esc($h['created_at']) ?></span>
                        </li>
                    <?php endforeach; ?>
                </ul>
            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
const orderCode = "<?= esc($order['order_code'], 'js') ?>";
const trackApiUrl = "<?= base_url('api/track/') ?>" + orderCode;

let map = L.map('trackingMap').setView([<?= $order['restaurant']['lat'] ?? 11.664 ?>, 78.146], 14);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors'
}).addTo(map);

let marker = null;

function updateMap(lat, lng) {
    if (lat === null || lng === null) return;
    lat = parseFloat(lat); lng = parseFloat(lng);
    if (!marker) {
        marker = L.marker([lat, lng]).addTo(map).bindPopup('Delivery Partner');
        map.setView([lat, lng], 15);
    } else {
        marker.setLatLng([lat, lng]);
    }
}

const flow = ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'];
const statusLabels = {
    placed: 'Placed', confirmed: 'Confirmed', preparing: 'Preparing',
    out_for_delivery: 'Out for Delivery', delivered: 'Delivered', cancelled: 'Cancelled'
};

function refreshTracking() {
    fetch(trackApiUrl)
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;

            document.getElementById('statusBadge').textContent = statusLabels[data.order_status] || data.order_status;
            document.getElementById('etaText').textContent = 'Estimated delivery: ' + data.eta_min + ' mins';

            updateMap(data.lat, data.lng);

            if (data.partner_name) {
                document.getElementById('partnerName').textContent = data.partner_name;
                document.getElementById('partnerPhone').textContent = data.partner_phone || '';
                document.getElementById('partnerInfo').style.display = '';
                document.getElementById('partnerPendingText').style.display = 'none';
            }

            const currentIndex = flow.indexOf(data.order_status);
            document.querySelectorAll('#statusTimeline .status-step').forEach((el, i) => {
                el.classList.remove('done', 'active');
                if (currentIndex !== -1 && i < currentIndex) el.classList.add('done');
                if (currentIndex !== -1 && i === currentIndex) el.classList.add('active');
            });

            const list = document.getElementById('historyList');
            list.innerHTML = '';
            data.history.forEach(h => {
                const li = document.createElement('li');
                li.className = 'mb-2';
                li.innerHTML = `<strong>${statusLabels[h.status] || h.status}</strong> — ${h.note || ''}<br><span class="text-muted">${h.created_at || ''}</span>`;
                list.appendChild(li);
            });

            if (data.order_status === 'delivered' || data.order_status === 'cancelled') {
                clearInterval(pollInterval);
            }
        })
        .catch(err => console.error('Tracking refresh failed', err));
}

refreshTracking();
const pollInterval = setInterval(refreshTracking, 5000); // poll every 5 seconds

<?php if ($restaurant): ?>
(function () {
    const restaurantId = <?= (int) $restaurant['id'] ?>;
    const fab = document.getElementById('restaurantChatFab');
    const panel = document.getElementById('restaurantChatPanel');
    const thread = document.getElementById('restaurantChatThread');
    const form = document.getElementById('restaurantChatForm');
    const input = document.getElementById('restaurantChatInput');
    let pollTimer = null;

    function renderMessages(messages) {
        thread.innerHTML = messages.map(m => `
            <div class="chat-bubble ${m.sender === 'customer' ? 'customer' : 'support'}">${m.message}</div>
        `).join('') || '<p class="text-muted small text-center mt-3">Tell the restaurant what went wrong with this order.</p>';
        thread.scrollTop = thread.scrollHeight;
    }

    async function poll() {
        try {
            const res = await fetch(`<?= base_url('chat/messages') ?>?restaurant_id=${restaurantId}`);
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
    document.getElementById('restaurantChatClose').addEventListener('click', () => panel.classList.add('d-none'));

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const message = input.value.trim();
        if (! message) return;
        input.value = '';
        try {
            await fetch(`<?= base_url('chat/send') ?>`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'message=' + encodeURIComponent(message) + '&restaurant_id=' + restaurantId + '&<?= csrf_token() ?>=<?= csrf_hash() ?>'
            });
            poll();
        } catch (e) { /* ignore */ }
    });
})();
<?php endif; ?>
</script>
<?= $this->endSection() ?>
