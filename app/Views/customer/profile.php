<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4">My Profile</h4>

<div class="row">
    <div class="col-md-5 mb-4" id="account-details">
        <div class="card card-jeevi p-4">
            <h6 class="fw-bold mb-3">Account Details</h6>
            <form method="post" action="<?= base_url('profile/update') ?>">
                <?= csrf_field() ?>
                <div class="mb-3">
                    <label class="form-label">Full Name</label>
                    <input type="text" name="name" class="form-control" value="<?= esc($user['name']) ?>" required>
                </div>
                <div class="mb-3">
                    <label class="form-label">Email</label>
                    <input type="email" class="form-control" value="<?= esc($user['email']) ?>" disabled>
                    <div class="form-text">Email can't be changed here.</div>
                </div>
                <div class="mb-3">
                    <label class="form-label">Phone</label>
                    <input type="text" name="phone" class="form-control" value="<?= esc($user['phone']) ?>" required>
                </div>
                <button type="submit" class="btn btn-jeevi w-100">Save Changes</button>
            </form>
            <hr>
            <p class="small text-muted mb-0">You've placed <strong><?= (int)$orderCount ?></strong> order<?= $orderCount == 1 ? '' : 's' ?> with Jeevi.</p>
        </div>
    </div>

    <div class="col-md-7 mb-4" id="addresses">
        <div class="card card-jeevi p-4 mb-3">
            <h6 class="fw-bold mb-3">My Delivery Addresses</h6>

            <?php if (empty($addresses)): ?>
                <p class="text-muted small">No saved addresses yet. Add one below.</p>
            <?php endif; ?>

            <?php foreach ($addresses as $addr): ?>
                <div class="d-flex justify-content-between align-items-start border-bottom py-2">
                    <div>
                        <strong><?= esc($addr['label']) ?></strong>
                        <?php if ($addr['is_default']): ?><span class="badge bg-success ms-1">Default</span><?php endif; ?>
                        <p class="small text-muted mb-0"><?= esc($addr['address_line']) ?>, <?= esc($addr['city']) ?>, <?= esc($addr['state']) ?> - <?= esc($addr['pincode']) ?></p>
                    </div>
                    <div class="text-nowrap">
                        <?php if (! $addr['is_default']): ?>
                            <a href="<?= base_url('profile/address/default/' . $addr['id']) ?>" class="btn btn-sm btn-jeevi-outline">Set Default</a>
                        <?php endif; ?>
                        <a href="<?= base_url('profile/address/delete/' . $addr['id']) ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Remove this address?')">Remove</a>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>

        <div class="card card-jeevi p-4">
            <h6 class="fw-bold mb-3">Add New Address</h6>
            <p class="small text-muted">We currently deliver only within <strong>Salem district</strong>. Tap the map to drop a pin — your address will be filled in automatically, and you can edit it if needed.</p>

            <div id="addressPickerMap" style="height: 280px; border-radius: 12px; margin-bottom: 12px;"></div>
            <p class="small mb-3" id="mapPickStatus">No location picked yet — tap the map above.</p>

            <form method="post" action="<?= base_url('profile/address/add') ?>" id="addAddressForm">
                <?= csrf_field() ?>
                <input type="hidden" name="lat" id="pickedLat">
                <input type="hidden" name="lng" id="pickedLng">
                <div class="row">
                    <div class="col-md-4 mb-3">
                        <label class="form-label">Label</label>
                        <select name="label" class="form-select">
                            <option value="Home">Home</option>
                            <option value="Work">Work</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                    <div class="col-md-8 mb-3">
                        <label class="form-label">Address Line</label>
                        <input type="text" name="address_line" class="form-control" placeholder="House no, street" required>
                    </div>
                    <div class="col-md-4 mb-3">
                        <label class="form-label">City</label>
                        <input type="text" name="city" class="form-control" required>
                    </div>
                    <div class="col-md-4 mb-3">
                        <label class="form-label">State</label>
                        <input type="text" name="state" class="form-control" value="Tamil Nadu" required>
                    </div>
                    <div class="col-md-4 mb-3">
                        <label class="form-label">Pincode</label>
                        <input type="text" name="pincode" class="form-control" required>
                    </div>
                    <div class="col-12 mb-3 form-check">
                        <input type="checkbox" name="is_default" class="form-check-input" id="is_default">
                        <label class="form-check-label" for="is_default">Set as default address</label>
                    </div>
                </div>
                <button type="submit" class="btn btn-jeevi" id="addAddressSubmit" disabled>Add Address</button>
            </form>
        </div>
    </div>
</div>

<h6 class="text-muted mt-4 mb-2">General</h6>
<div class="card card-jeevi">
    <div class="list-group list-group-flush">
        <a href="#account-details" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-person-fill fs-5"></i> <?= t('profile') ?>
        </a>
        <a href="#addresses" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-geo-alt-fill fs-5"></i> <?= t('my_addresses') ?>
        </a>
        <a href="<?= base_url('language') ?>" class="list-group-item list-group-item-action d-flex align-items-center justify-content-between py-3">
            <span><i class="bi bi-translate fs-5"></i> <?= t('change_language') ?></span>
            <span class="text-muted small"><?= (session()->get('site_lang') ?? 'en') === 'ta' ? 'தமிழ்' : 'English' ?></span>
        </a>
    </div>
</div>

<h6 class="text-muted mt-4 mb-2">Promotional Activity</h6>
<div class="card card-jeevi">
    <div class="list-group list-group-flush">
        <a href="<?= base_url('coupons') ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-ticket-perforated-fill fs-5"></i> Coupons
        </a>
        <a href="<?= base_url('wallet') ?>" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center py-3">
            <span><i class="bi bi-wallet2 fs-5"></i> My Wallet</span>
            <span class="badge bg-danger rounded-pill">₹<?= number_format($user['wallet_balance'] ?? 0, 0) ?></span>
        </a>
    </div>
</div>

<h6 class="text-muted mt-4 mb-2">Earnings</h6>
<div class="card card-jeevi">
    <div class="list-group list-group-flush">
        <a href="<?= base_url('delivery/register') ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-bicycle fs-5"></i> <?= t('join_as_delivery') ?>
        </a>
        <a href="<?= base_url('restaurant/register') ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-shop fs-5"></i> <?= t('open_vendor') ?>
        </a>
    </div>
</div>

<h6 class="text-muted mt-4 mb-2"><?= t('help_support') ?></h6>
<div class="card card-jeevi">
    <div class="list-group list-group-flush">
        <a href="https://wa.me/<?= esc(env('support.whatsappNumber', '919999999999')) ?>?text=<?= rawurlencode('Hi, I need help with my Jeevi order.') ?>" target="_blank" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-chat-dots-fill fs-5"></i> <?= t('live_chat') ?>
        </a>
        <a href="tel:+<?= esc(env('support.whatsappNumber', '919999999999')) ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-telephone-fill fs-5"></i> <?= t('help_support') ?>
        </a>
        <a href="<?= base_url('about') ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-info-circle-fill fs-5"></i> <?= t('about_us') ?>
        </a>
        <a href="<?= base_url('terms') ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-file-text-fill fs-5"></i> <?= t('terms_conditions') ?>
        </a>
        <a href="<?= base_url('privacy') ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-shield-lock-fill fs-5"></i> <?= t('privacy_policy') ?>
        </a>
        <a href="<?= base_url('refund-policy') ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-cash-coin fs-5"></i> <?= t('refund_policy') ?>
        </a>
        <a href="<?= base_url('shipping-policy') ?>" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
            <i class="bi bi-truck fs-5"></i> <?= t('shipping_policy') ?>
        </a>
    </div>
</div>

<div class="text-center mt-4 mb-2">
    <a href="<?= base_url('logout') ?>" class="btn btn-outline-danger px-4"><i class="bi bi-power"></i> <?= t('logout') ?></a>
</div>

<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
// Same Salem district polygon enforced server-side in
// ProfileController::SALEM_POLYGON — kept in sync so the map visually
// matches exactly what the backend will accept.
const salemPolygonPoints = [
    [11.9560, 77.7280], // Mettur / West Border
    [12.0830, 77.9140], // North West / Mecheri
    [12.0120, 78.1820], // North / Yercaud hills edge
    [11.7580, 78.5860], // East / Attur edge
    [11.5320, 78.6540], // South East / Thalaivasal
    [11.4500, 78.3620], // South / Vazhapadi-Namakkal border
    [11.5300, 77.8900], // South West / Sankagiri edge
    [11.6020, 77.7500], // Jalakandapuram border
    [11.9560, 77.7280]  // Closed loop
];

// Ray-casting point-in-polygon, mirrors the PHP version exactly.
function isInsideSalemPolygon(lat, lng) {
    let inside = false;
    for (let i = 0, j = salemPolygonPoints.length - 1; i < salemPolygonPoints.length; j = i++) {
        const latI = salemPolygonPoints[i][0], lngI = salemPolygonPoints[i][1];
        const latJ = salemPolygonPoints[j][0], lngJ = salemPolygonPoints[j][1];
        const intersects = ((lngI > lng) !== (lngJ > lng))
            && (lat < (latJ - latI) * (lng - lngI) / (lngJ - lngI) + latI);
        if (intersects) inside = !inside;
    }
    return inside;
}

// Leaflet still needs a rectangular maxBounds for panning limits — pad
// slightly around the polygon's own extent so the whole shape is reachable.
const lats = salemPolygonPoints.map(p => p[0]);
const lngs = salemPolygonPoints.map(p => p[1]);
const salemPanBounds = L.latLngBounds(
    L.latLng(Math.min(...lats) - 0.05, Math.min(...lngs) - 0.05),
    L.latLng(Math.max(...lats) + 0.05, Math.max(...lngs) + 0.05)
);

const map = L.map('addressPickerMap', {
    maxBounds: salemPanBounds,
    maxBoundsViscosity: 1.0,
    minZoom: 9
}).setView([11.6643, 78.1460], 11); // centered on Salem city

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors'
}).addTo(map);

// Nicely shaded district boundary — soft red fill + solid border, instead
// of a plain dashed outline.
L.polygon(salemPolygonPoints, {
    color: '#E31E24',
    weight: 3,
    opacity: 0.9,
    fill: true,
    fillColor: '#E31E24',
    fillOpacity: 0.06,
    lineJoin: 'round'
}).addTo(map);

// Custom teardrop pin (Jeevi red, white center dot, soft drop shadow) —
// built as an inline SVG so it stays crisp at any zoom/screen density,
// no separate image file to host.
const pinSvg = `
<svg width="44" height="58" viewBox="0 0 44 58" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="pinShadow" x="-50%" y="-20%" width="200%" height="150%">
      <feDropShadow dx="0" dy="2" stdDeviation="2" flood-color="#000" flood-opacity="0.35"/>
    </filter>
  </defs>
  <path filter="url(#pinShadow)" d="M22 2C11.5 2 3 10.5 3 21c0 15.5 19 33 19 33s19-17.5 19-33C41 10.5 32.5 2 22 2z"
        fill="#E31E24" stroke="#ffffff" stroke-width="2.5"/>
  <circle cx="22" cy="21" r="8" fill="#ffffff"/>
  <circle cx="22" cy="21" r="4" fill="#E31E24"/>
</svg>`;
const pinIcon = L.icon({
    iconUrl: 'data:image/svg+xml;base64,' + btoa(pinSvg),
    iconSize: [44, 58],
    iconAnchor: [22, 56], // tip of the pin points at the exact picked spot
    popupAnchor: [0, -50]
});

let marker = null;
const statusEl = document.getElementById('mapPickStatus');
const submitBtn = document.getElementById('addAddressSubmit');
const addressLineInput = document.querySelector('input[name="address_line"]');
const cityInput = document.querySelector('input[name="city"]');
const pincodeInput = document.querySelector('input[name="pincode"]');

function reverseGeocode(lat, lng) {
    statusEl.className = 'small mb-3 text-muted';
    statusEl.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Fetching address...';

    fetch(`https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lng}&addressdetails=1`, {
        headers: { 'Accept-Language': 'en' }
    })
    .then(res => res.json())
    .then(data => {
        const addr = data.address || {};

        if (data.display_name) {
            addressLineInput.value = data.display_name;
        }
        cityInput.value = addr.city || addr.town || addr.village || addr.suburb || addr.county || '';
        if (addr.postcode) {
            pincodeInput.value = addr.postcode;
        }

        statusEl.className = 'small mb-3 text-success';
        statusEl.textContent = 'Location picked ✓ — address filled in automatically. Feel free to edit it below.';
    })
    .catch(() => {
        statusEl.className = 'small mb-3 text-warning';
        statusEl.textContent = 'Location picked, but we couldn\'t auto-fill the address — please type it in manually below.';
    });
}

map.on('click', function (e) {
    if (! isInsideSalemPolygon(e.latlng.lat, e.latlng.lng)) {
        statusEl.className = 'small mb-3 text-danger';
        statusEl.textContent = 'That point is outside Salem district — please pick a location within the shaded boundary.';
        return;
    }

    if (marker) {
        marker.setLatLng(e.latlng);
    } else {
        marker = L.marker(e.latlng, { icon: pinIcon }).addTo(map);
    }

    document.getElementById('pickedLat').value = e.latlng.lat.toFixed(6);
    document.getElementById('pickedLng').value = e.latlng.lng.toFixed(6);
    submitBtn.disabled = false;

    reverseGeocode(e.latlng.lat, e.latlng.lng);
});
</script>
<?= $this->endSection() ?>
