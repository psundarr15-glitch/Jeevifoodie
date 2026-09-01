<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4">Checkout</h4>

<div class="row">
    <div class="col-md-7">
        <div class="card card-jeevi mb-4">
            <div class="card-body">
                <h6 class="fw-bold mb-3">Order Summary</h6>
                <?php foreach ($items as $it): ?>
                    <div class="d-flex justify-content-between py-1">
                        <span><?= esc($it['name']) ?> x <?= (int)$it['quantity'] ?></span>
                        <span>₹<?= number_format($it['price'] * $it['quantity'], 2) ?></span>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>

        <div class="card card-jeevi mb-4">
            <div class="card-body">
                <h6 class="fw-bold mb-3">Delivery Address</h6>
                <?php if (empty($addresses)): ?>
                    <p class="text-muted">No saved address. The order will be delivered to your default location.</p>
                <?php else: ?>
                    <?php foreach ($addresses as $addr): ?>
                        <div class="form-check mb-2">
                            <input class="form-check-input" type="radio" name="address_id" form="orderForm" value="<?= $addr['id'] ?>" <?= $addr['is_default'] ? 'checked' : '' ?> required>
                            <label class="form-check-label">
                                <strong><?= esc($addr['label']) ?></strong> - <?= esc($addr['address_line']) ?>, <?= esc($addr['city']) ?>
                            </label>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>

        <div class="card card-jeevi mb-4">
            <div class="card-body">
                <h6 class="fw-bold mb-3">Have a coupon?</h6>
                <div class="input-group">
                    <input type="text" id="couponCode" class="form-control" placeholder="e.g. JEEVI30">
                    <button type="button" id="applyCouponBtn" class="btn btn-jeevi-outline">Apply</button>
                </div>
                <div id="couponMsg" class="small mt-2"></div>
            </div>
        </div>
    </div>

    <div class="col-md-5">
        <div class="card card-jeevi">
            <div class="card-body">
                <h6 class="fw-bold mb-3">Bill Details</h6>
                <div class="d-flex justify-content-between"><span>Subtotal</span><span id="billSubtotal">₹<?= number_format($subtotal, 2) ?></span></div>
                <div class="d-flex justify-content-between text-success"><span>Discount</span><span id="billDiscount">-₹0.00</span></div>
                <div class="d-flex justify-content-between"><span>Delivery Fee</span><span id="billDelivery"><?= $subtotal >= 199 ? 'FREE' : '₹30.00' ?></span></div>
                <hr>
                <div class="d-flex justify-content-between fw-bold fs-5"><span>Total</span><span id="billTotal">₹<?= number_format($subtotal + ($subtotal >= 199 ? 0 : 30), 2) ?></span></div>

                <form id="orderForm" method="post" action="<?= base_url('checkout/place-order') ?>" class="mt-3">
                    <?= csrf_field() ?>
                    <input type="hidden" name="discount" id="discountInput" value="0">
                    <input type="hidden" name="coupon_id" id="couponIdInput" value="">
                    <label class="form-label fw-bold">Payment Method</label>
                    <select name="payment_method" class="form-select mb-3">
                        <option value="cod">Cash on Delivery</option>
                        <option value="upi">UPI</option>
                        <option value="card">Card</option>
                    </select>
                    <button type="submit" class="btn btn-jeevi btn-lg w-100">Place Order</button>
                </form>
            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<script>
const subtotal = <?= (float)$subtotal ?>;

document.getElementById('applyCouponBtn').addEventListener('click', function () {
    const code = document.getElementById('couponCode').value;
    fetch('<?= base_url('checkout/apply-coupon') ?>', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `code=${encodeURIComponent(code)}&subtotal=${subtotal}&<?= csrf_token() ?>=<?= csrf_hash() ?>`
    })
    .then(res => res.json())
    .then(data => {
        const msg = document.getElementById('couponMsg');
        if (data.success) {
            msg.className = 'small mt-2 text-success';
            msg.textContent = data.message;
            document.getElementById('discountInput').value = data.discount;
            document.getElementById('couponIdInput').value = data.coupon_id;
            document.getElementById('billDiscount').textContent = '-₹' + parseFloat(data.discount).toFixed(2);
            const deliveryFee = subtotal >= 199 ? 0 : 30;
            document.getElementById('billTotal').textContent = '₹' + (subtotal - data.discount + deliveryFee).toFixed(2);
        } else {
            msg.className = 'small mt-2 text-danger';
            msg.textContent = data.message;
        }
    });
});
</script>
<?= $this->endSection() ?>
