<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4">Order #<?= esc($order['order_code']) ?></h3>

<div class="row">
    <div class="col-md-6 mb-4">
        <div class="card card-jeevi p-4">
            <h6 class="fw-bold mb-3">Order Items</h6>
            <?php foreach ($items as $it): ?>
                <div class="d-flex justify-content-between">
                    <span><?= esc($it['item_name']) ?> x <?= (int)$it['quantity'] ?></span>
                    <span>₹<?= number_format($it['price'] * $it['quantity'], 2) ?></span>
                </div>
            <?php endforeach; ?>
            <hr>
            <div class="d-flex justify-content-between"><span>Subtotal</span><span>₹<?= number_format($order['subtotal'], 2) ?></span></div>
            <div class="d-flex justify-content-between"><span>Discount</span><span>-₹<?= number_format($order['discount'], 2) ?></span></div>
            <div class="d-flex justify-content-between"><span>Delivery Fee</span><span>₹<?= number_format($order['delivery_fee'], 2) ?></span></div>
            <div class="d-flex justify-content-between fw-bold"><span>Total</span><span>₹<?= number_format($order['total'], 2) ?></span></div>
        </div>
    </div>

    <div class="col-md-6 mb-4">
        <div class="card card-jeevi p-4">
            <h6 class="fw-bold mb-3">Update Status &amp; Live Location</h6>
            <p class="small text-muted">Updates here push instantly to the customer's live tracking page (polled every 5s).</p>
            <form method="post" action="<?= base_url('admin/orders/' . $order['id'] . '/update-status') ?>">
                <?= csrf_field() ?>
                <div class="mb-3">
                    <label class="form-label">Order Status</label>
                    <select name="order_status" class="form-select">
                        <?php foreach (['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'] as $s): ?>
                            <option value="<?= $s ?>" <?= $order['order_status'] === $s ? 'selected' : '' ?>><?= order_status_label($s) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="mb-3">
                    <label class="form-label">Delivery Partner</label>
                    <select name="delivery_partner_id" class="form-select">
                        <option value="">-- Unassigned --</option>
                        <?php foreach ($partners as $p): ?>
                            <option value="<?= $p['id'] ?>" <?= $order['delivery_partner_id'] == $p['id'] ? 'selected' : '' ?>><?= esc($p['name']) ?> (<?= esc($p['phone']) ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="row">
                    <div class="col-6 mb-3">
                        <label class="form-label">Latitude</label>
                        <input type="text" name="lat" class="form-control" placeholder="e.g. 11.6650">
                    </div>
                    <div class="col-6 mb-3">
                        <label class="form-label">Longitude</label>
                        <input type="text" name="lng" class="form-control" placeholder="e.g. 78.1470">
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label">Note (optional)</label>
                    <input type="text" name="note" class="form-control" placeholder="e.g. Picked up, heading to you">
                </div>
                <button type="submit" class="btn btn-jeevi w-100">Update Order</button>
            </form>
        </div>
    </div>
</div>

<div class="card card-jeevi p-4">
    <h6 class="fw-bold mb-3">Tracking History</h6>
    <ul class="list-unstyled small mb-0">
        <?php foreach ($history as $h): ?>
            <li class="mb-2">
                <strong><?= order_status_label($h['status']) ?></strong> — <?= esc($h['note']) ?>
                <?php if ($h['lat'] && $h['lng']): ?> <span class="text-muted">(<?= esc($h['lat']) ?>, <?= esc($h['lng']) ?>)</span><?php endif; ?>
                <br><span class="text-muted"><?= esc($h['created_at']) ?></span>
            </li>
        <?php endforeach; ?>
    </ul>
</div>

<?= $this->endSection() ?>
