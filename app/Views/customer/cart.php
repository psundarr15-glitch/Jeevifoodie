<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4">Your Cart</h4>

<?php if (empty($items)): ?>
    <p class="text-muted" id="emptyCartMsg">Your cart is empty. <a href="<?= base_url('restaurants') ?>">Browse restaurants</a></p>
<?php else: ?>
    <p class="text-muted">Ordering from <strong><?= esc($restaurant['name'] ?? '') ?></strong></p>
    <div class="card card-jeevi mb-4">
        <div class="card-body" id="cartItemsWrap">
            <?php foreach ($items as $it): ?>
                <div class="d-flex justify-content-between align-items-center border-bottom py-2" data-cart-item-id="<?= $it['id'] ?>">
                    <div>
                        <strong><?= esc($it['name']) ?></strong>
                        <p class="small text-muted mb-0">₹<?= esc($it['price']) ?> each</p>
                    </div>
                    <div class="d-flex align-items-center gap-3">
                        <div class="qty-stepper" data-cart-item-id="<?= $it['id'] ?>" data-price="<?= $it['price'] ?>">
                            <button type="button" class="qty-minus">−</button>
                            <span class="qty-value"><?= (int)$it['quantity'] ?></span>
                            <button type="button" class="qty-plus">+</button>
                        </div>
                        <strong class="item-line-total" style="min-width: 70px; text-align: right;">₹<?= number_format($it['price'] * $it['quantity'], 2) ?></strong>
                    </div>
                </div>
            <?php endforeach; ?>
            <div class="d-flex justify-content-between pt-3">
                <h5>Subtotal</h5>
                <h5>₹<span id="cartSubtotal"><?= number_format($subtotal, 2) ?></span></h5>
            </div>
        </div>
    </div>
    <a href="<?= base_url('checkout') ?>" class="btn btn-jeevi btn-lg w-100" id="checkoutBtn">Proceed to Checkout</a>
<?php endif; ?>

<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<script>
const cartUpdateUrl = "<?= base_url('cart/update') ?>";
const csrfName = "<?= csrf_token() ?>";
const csrfHash = "<?= csrf_hash() ?>";

function updateCartItem(cartItemId, newQty, row, stepper) {
    stepper.querySelector('.qty-plus').disabled = true;
    stepper.querySelector('.qty-minus').disabled = true;

    fetch(cartUpdateUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `cart_item_id=${cartItemId}&quantity=${newQty}&${csrfName}=${csrfHash}`
    })
    .then(res => res.json())
    .then(data => {
        if (!data.success) return;

        document.getElementById('cartSubtotal').textContent = parseFloat(data.cart_subtotal).toFixed(2);

        if (data.removed) {
            row.remove();
            if (data.cart_count === 0) {
                document.querySelector('.card-jeevi.mb-4').outerHTML = '<p class="text-muted">Your cart is empty. <a href="<?= base_url('restaurants') ?>">Browse restaurants</a></p>';
                document.getElementById('checkoutBtn')?.remove();
            }
        } else {
            row.querySelector('.qty-value').textContent = data.new_quantity;
            row.querySelector('.item-line-total').textContent = '₹' + parseFloat(data.item_total).toFixed(2);
        }
    })
    .finally(() => {
        // Row may have been removed above; guard against re-enabling a detached element
        if (document.body.contains(stepper)) {
            stepper.querySelector('.qty-plus').disabled = false;
            stepper.querySelector('.qty-minus').disabled = false;
        }
    });
}

document.querySelectorAll('.qty-stepper').forEach(stepper => {
    const cartItemId = stepper.dataset.cartItemId;
    const row = stepper.closest('[data-cart-item-id]');

    stepper.querySelector('.qty-plus').addEventListener('click', function () {
        const current = parseInt(stepper.querySelector('.qty-value').textContent, 10);
        updateCartItem(cartItemId, current + 1, row, stepper);
    });

    stepper.querySelector('.qty-minus').addEventListener('click', function () {
        const current = parseInt(stepper.querySelector('.qty-value').textContent, 10);
        updateCartItem(cartItemId, current - 1, row, stepper); // update() deletes automatically when quantity reaches 0
    });
});
</script>
<?= $this->endSection() ?>
