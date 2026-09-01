<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register Your Restaurant — Jeevi</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="<?= base_url('assets/css/style.css') ?>" rel="stylesheet">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
</head>
<body style="background:#f7f7f8;">
<div class="container py-4" style="max-width: 640px;">
    <div class="text-center mb-4"><img src="<?= base_url('assets/img/logo.svg') ?>" alt="Jeevi" height="46"></div>

    <div class="card card-jeevi p-4">
        <h4 class="section-title mb-1">Register Your Restaurant</h4>
        <p class="text-muted small mb-4">Create your manager account and list your restaurant on Jeevi — both in one step.</p>

        <?php if (session()->getFlashdata('error')): ?>
            <div class="alert alert-danger"><?= esc(session()->getFlashdata('error')) ?></div>
        <?php endif; ?>

        <form method="post" action="<?= base_url('restaurant/register') ?>" enctype="multipart/form-data">
            <?= csrf_field() ?>

            <h6 class="fw-bold text-muted text-uppercase small mb-3">Your Manager Account</h6>
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Your Name</label>
                    <input type="text" name="manager_name" class="form-control" value="<?= old('manager_name') ?>" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Email (login)</label>
                    <input type="email" name="manager_email" class="form-control" value="<?= old('manager_email') ?>" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Password</label>
                    <input type="password" name="manager_password" class="form-control" required>
                </div>
            </div>

            <hr class="my-4">
            <h6 class="fw-bold text-muted text-uppercase small mb-3">Restaurant Details</h6>
            <div class="row">
                <div class="col-md-8 mb-3">
                    <label class="form-label">Restaurant Name</label>
                    <input type="text" name="restaurant_name" class="form-control" value="<?= old('restaurant_name') ?>" required>
                </div>
                <div class="col-md-4 mb-3">
                    <label class="form-label">Phone Number</label>
                    <input type="text" name="restaurant_phone" class="form-control" value="<?= old('restaurant_phone') ?>" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Cuisine</label>
                    <input type="text" name="cuisine" class="form-control" placeholder="e.g. Biryani, North Indian" value="<?= old('cuisine') ?>" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Cost for Two (₹)</label>
                    <input type="number" name="cost_for_two" class="form-control" value="<?= old('cost_for_two') ?>">
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Opening Time</label>
                    <input type="time" name="opening_time" class="form-control" value="09:00">
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Closing Time</label>
                    <input type="time" name="closing_time" class="form-control" value="23:00">
                </div>
                <div class="col-12 mb-3">
                    <label class="form-label">Description</label>
                    <textarea name="description" class="form-control" rows="2"><?= old('description') ?></textarea>
                </div>
                <div class="col-12 mb-3">
                    <label class="form-label">Restaurant Photo</label>
                    <input type="file" name="restaurant_image" class="form-control" accept="image/*">
                </div>
                <div class="col-12 mb-3">
                    <label class="form-label">Full Address</label>
                    <input type="text" name="address" id="addressInput" class="form-control" placeholder="Street, area, city" value="<?= old('address') ?>" required>
                </div>
            </div>

            <label class="form-label fw-bold">Pin Your Restaurant's Location</label>
            <p class="small text-muted">We currently only serve <strong>Salem district</strong> — tap the map inside the boundary.</p>
            <div id="regPickerMap" style="height: 280px; border-radius: 12px; margin-bottom: 10px;"></div>
            <p class="small mb-3" id="regMapStatus">No location picked yet — tap the map above.</p>
            <input type="hidden" name="lat" id="regLat">
            <input type="hidden" name="lng" id="regLng">

            <button type="submit" class="btn btn-jeevi w-100 btn-lg mt-2" id="regSubmitBtn" disabled>Register Restaurant</button>
        </form>

        <p class="text-center small text-muted mt-3 mb-0">Already registered? <a href="<?= base_url('admin/login') ?>">Login here</a></p>
    </div>
</div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
const salemPolygonPoints = [
    [11.9560, 77.7280], [12.0830, 77.9140], [12.0120, 78.1820],
    [11.7580, 78.5860], [11.5320, 78.6540], [11.4500, 78.3620],
    [11.5300, 77.8900], [11.6020, 77.7500], [11.9560, 77.7280]
];

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

const lats = salemPolygonPoints.map(p => p[0]);
const lngs = salemPolygonPoints.map(p => p[1]);
const panBounds = L.latLngBounds(
    L.latLng(Math.min(...lats) - 0.05, Math.min(...lngs) - 0.05),
    L.latLng(Math.max(...lats) + 0.05, Math.max(...lngs) + 0.05)
);

const map = L.map('regPickerMap', { maxBounds: panBounds, maxBoundsViscosity: 1.0, minZoom: 9 })
    .setView([11.6643, 78.1460], 11);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '&copy; OpenStreetMap contributors' }).addTo(map);
L.polygon(salemPolygonPoints, { color: '#E31E24', weight: 3, fillColor: '#E31E24', fillOpacity: 0.06, lineJoin: 'round' }).addTo(map);

const pinSvg = `data:image/svg+xml;base64,${btoa(`
<svg xmlns="http://www.w3.org/2000/svg" width="44" height="58" viewBox="0 0 44 58">
  <defs><filter id="s" x="-50%" y="-20%" width="200%" height="150%"><feDropShadow dx="0" dy="2" stdDeviation="2" flood-color="#000" flood-opacity="0.35"/></filter></defs>
  <g filter="url(#s)">
    <path d="M22 2C11 2 3 10.5 3 21c0 14 19 33 19 33s19-19 19-33C41 10.5 33 2 22 2z" fill="#E31E24" stroke="#fff" stroke-width="2.5"/>
    <circle cx="22" cy="21" r="9" fill="#fff"/>
    <circle cx="22" cy="21" r="4.5" fill="#E31E24"/>
  </g>
</svg>`)}`;
const pinIcon = L.icon({ iconUrl: pinSvg, iconSize: [44, 58], iconAnchor: [22, 56], popupAnchor: [0, -50] });

let marker = null;
const statusEl = document.getElementById('regMapStatus');
const submitBtn = document.getElementById('regSubmitBtn');
const addressInput = document.getElementById('addressInput');

map.on('click', function (e) {
    if (! isInsideSalemPolygon(e.latlng.lat, e.latlng.lng)) {
        statusEl.className = 'small mb-3 text-danger';
        statusEl.textContent = 'That point is outside Salem district — please pick within the shaded boundary.';
        return;
    }

    if (marker) { marker.setLatLng(e.latlng); } else { marker = L.marker(e.latlng, { icon: pinIcon }).addTo(map); }

    document.getElementById('regLat').value = e.latlng.lat.toFixed(6);
    document.getElementById('regLng').value = e.latlng.lng.toFixed(6);

    statusEl.className = 'small mb-3 text-muted';
    statusEl.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Fetching address...';
    submitBtn.disabled = false;

    fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${e.latlng.lat}&lon=${e.latlng.lng}`)
        .then(res => res.json())
        .then(data => {
            if (data && data.display_name) {
                if (! addressInput.value) addressInput.value = data.display_name;
                statusEl.className = 'small mb-3 text-success';
                statusEl.textContent = 'Location picked ✓ address filled in automatically';
            } else {
                statusEl.className = 'small mb-3 text-success';
                statusEl.textContent = 'Location picked ✓';
            }
        })
        .catch(() => {
            statusEl.className = 'small mb-3 text-success';
            statusEl.textContent = 'Location picked ✓ (address lookup unavailable — please fill it in manually)';
        });
});
</script>
</body>
</html>
