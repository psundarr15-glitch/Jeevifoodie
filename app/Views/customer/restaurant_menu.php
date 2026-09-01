<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<?php $isOpen = \App\Models\RestaurantModel::isOpenNow($restaurant); ?>

<div class="card card-jeevi mb-4 <?= $isOpen ? '' : 'restaurant-closed' ?>">
    <div class="card-img-wrap">
        <img class="cover-img h-lg" src="<?= esc($restaurant['image'] ?: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900&h=400&fit=crop') ?>" alt="<?= esc($restaurant['name']) ?>" onerror="this.src='https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900&h=400&fit=crop'">
        <span class="open-status-chip <?= $isOpen ? 'open' : 'closed' ?>"><?= $isOpen ? 'Open Now' : 'Closed' ?></span>
    </div>
    <div class="card-body">
        <h3 class="fw-bold"><?= esc($restaurant['name']) ?></h3>
        <p class="text-muted mb-1"><?= esc($restaurant['cuisine']) ?></p>
        <span class="rating-badge">★ <?= esc($restaurant['rating']) ?></span>
        <span class="text-muted small">(<?= (int)$restaurant['rating_count'] ?>+ ratings)</span>
        <span class="text-muted small ms-2"><?= esc($restaurant['prep_time_min']) ?>-<?= esc($restaurant['prep_time_max']) ?> min</span>
        <p class="mt-2 mb-0"><?= esc($restaurant['description']) ?></p>

        <div class="like-share-row mt-3">
            <?php if (session()->get('logged_in')): ?>
                <button type="button" id="likeBtn" class="like-btn <?= $liked_by_me ? 'liked' : '' ?>" data-restaurant-id="<?= $restaurant['id'] ?>">
                    <i class="bi <?= $liked_by_me ? 'bi-heart-fill' : 'bi-heart' ?>"></i>
                    <span id="likeCountText"><?= (int)$like_count ?></span> Like<?= $like_count == 1 ? '' : 's' ?>
                </button>
            <?php else: ?>
                <span class="like-btn"><i class="bi bi-heart"></i> <?= (int)$like_count ?> Likes</span>
            <?php endif; ?>
            <button type="button" id="shareBtn" class="share-btn">
                <i class="bi bi-share-fill"></i> Share
            </button>
        </div>
    </div>
</div>

<?php if (! $isOpen): ?>
    <div class="closed-banner">
        <i class="bi bi-clock-fill"></i>
        This restaurant is currently closed. You can browse the menu, but ordering is disabled until it reopens.
    </div>
<?php endif; ?>

<?php if (empty($grouped)): ?>
    <p class="text-muted">No menu items available right now.</p>
<?php endif; ?>

<?php foreach ($grouped as $categoryName => $items): ?>
    <h5 class="section-title mt-4 mb-3"><?= esc($categoryName) ?></h5>
    <div class="row">
        <?php foreach ($items as $item): ?>
            <?php $state = $item_cart_state[$item['id']] ?? null; $available = (bool) $item['is_available']; ?>
            <div class="col-md-6 mb-3">
                <div class="card card-jeevi" <?= $available ? '' : 'style="opacity:0.65;"' ?>>
                    <div class="card-body d-flex justify-content-between align-items-center gap-3">
                        <div class="flex-grow-1">
                            <span class="<?= $item['is_veg'] ? 'veg-dot' : 'nonveg-dot' ?>" title="<?= $item['is_veg'] ? 'Veg' : 'Non-Veg' ?>"></span>
                            <h6 class="fw-bold mb-1 d-inline"> <?= esc($item['name']) ?></h6>
                            <?php if (! $available): ?>
                                <span class="badge bg-secondary ms-1">Out of Stock</span>
                            <?php endif; ?>
                            <p class="small text-muted mb-1"><?= esc($item['description']) ?></p>
                            <strong>₹<?= esc($item['price']) ?></strong>
                            <span class="text-muted small ms-2">★ <?= esc($item['rating']) ?> (<?= (int)$item['rating_count'] ?>+)</span>
                        </div>
                        <div class="text-center flex-shrink-0">
                            <img src="<?= esc($item['image'] ?: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&h=200&fit=crop') ?>" alt="<?= esc($item['name']) ?>" style="width:80px;height:80px;object-fit:cover;border-radius:12px;<?= $available ? '' : 'opacity:0.5;' ?>" onerror="this.src='https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&h=200&fit=crop'">

                            <?php if (! $available): ?>
                                <button class="btn btn-sm btn-secondary mt-1 w-100" disabled>Out of Stock</button>
                            <?php elseif (! session()->get('logged_in')): ?>
                                <a href="<?= base_url('login') ?>" class="btn btn-sm btn-jeevi-outline mt-1 w-100">ADD +</a>
                            <?php elseif (! $isOpen): ?>
                                <button class="btn btn-sm btn-secondary mt-1 w-100" disabled>Closed</button>
                            <?php else: ?>
                                <div class="item-add-control mt-1" data-item-id="<?= $item['id'] ?>" data-price="<?= $item['price'] ?>">
                                    <button class="btn btn-sm btn-jeevi add-to-cart-btn w-100 <?= $state ? 'd-none' : '' ?>" data-id="<?= $item['id'] ?>">ADD +</button>
                                    <div class="item-qty-stepper <?= $state ? '' : 'd-none' ?>" data-cart-item-id="<?= $state['cart_item_id'] ?? '' ?>">
                                        <button type="button" class="qty-minus">−</button>
                                        <span class="item-qty-value"><?= $state['quantity'] ?? 0 ?></span>
                                        <button type="button" class="qty-plus">+</button>
                                    </div>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
<?php endforeach; ?>

<div id="addToast" class="add-toast">
    <span>Item added to cart</span>
    <a href="<?= base_url('cart') ?>">View Cart</a>
</div>

<div id="cartSummaryBar" class="cart-summary-bar <?= $cart_count > 0 ? 'show' : '' ?>">
    <div class="summary-left">
        <div class="item-count">Item: <span id="summaryItemCount"><?= (int)$cart_count ?></span></div>
        <div class="item-total">Total: ₹<span id="summaryItemTotal"><?= number_format($cart_subtotal, 2) ?></span></div>
    </div>
    <a href="<?= base_url('cart') ?>" class="btn-view-cart">View Cart</a>
</div>

<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<script>
const csrfName = "<?= csrf_token() ?>";
const csrfHash = "<?= csrf_hash() ?>";

const likeBtn = document.getElementById('likeBtn');
if (likeBtn) {
    likeBtn.addEventListener('click', function () {
        const id = this.dataset.restaurantId;
        fetch(`<?= base_url('restaurants/') ?>${id}/like`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: `${csrfName}=${csrfHash}`
        })
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;
            this.classList.toggle('liked', data.liked);
            this.querySelector('i').className = 'bi ' + (data.liked ? 'bi-heart-fill' : 'bi-heart');
            document.getElementById('likeCountText').textContent = data.like_count;
        });
    });
}

document.getElementById('shareBtn').addEventListener('click', function () {
    const shareData = {
        title: "<?= esc($restaurant['name'], 'js') ?> — Jeevi Foodie Delivery",
        text: "Check out <?= esc($restaurant['name'], 'js') ?> on Jeevi Foodie Delivery!",
        url: window.location.href
    };

    if (navigator.share) {
        navigator.share(shareData).catch(() => {});
    } else {
        navigator.clipboard.writeText(window.location.href).then(() => {
            this.innerHTML = '<i class="bi bi-check2"></i> Link copied';
            setTimeout(() => { this.innerHTML = '<i class="bi bi-share-fill"></i> Share'; }, 1800);
        });
    }
});
const addToast = document.getElementById('addToast');
const summaryBar = document.getElementById('cartSummaryBar');
const summaryItemCount = document.getElementById('summaryItemCount');
const summaryItemTotal = document.getElementById('summaryItemTotal');
let toastTimer = null;

function showAddToast() {
    addToast.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => addToast.classList.remove('show'), 2000);
}

function updateSummary(count, subtotal) {
    summaryItemCount.textContent = count;
    summaryItemTotal.textContent = parseFloat(subtotal).toFixed(2);
    summaryBar.classList.toggle('show', count > 0);
}

// First "ADD +" tap for an item: creates the cart row, then swaps the
// button out for a +/- stepper matching the reference design.
document.querySelectorAll('.add-to-cart-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        const id = this.dataset.id;
        const control = this.closest('.item-add-control');

        fetch('<?= base_url('cart/add') ?>', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
            body: 'menu_item_id=' + id + '&quantity=1&' + csrfName + '=' + csrfHash
        })
        .then(res => res.json())
        .then(data => {
            if (!data.success) {
                alert(data.message || 'Could not add item.');
                return;
            }

            const stepper = control.querySelector('.item-qty-stepper');
            stepper.dataset.cartItemId = data.cart_item_id;
            stepper.querySelector('.item-qty-value').textContent = data.new_quantity;

            this.classList.add('d-none');
            stepper.classList.remove('d-none');

            updateSummary(data.cart_count, data.cart_subtotal);
            showAddToast();
        });
    });
});

// +/- on an already-added item's stepper.
document.querySelectorAll('.item-qty-stepper').forEach(stepper => {
    const control = stepper.closest('.item-add-control');
    const addBtn = control.querySelector('.add-to-cart-btn');

    function sendUpdate(newQty) {
        const cartItemId = stepper.dataset.cartItemId;
        if (!cartItemId) return;

        fetch('<?= base_url('cart/update') ?>', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: `cart_item_id=${cartItemId}&quantity=${newQty}&${csrfName}=${csrfHash}`
        })
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;

            if (data.removed) {
                stepper.classList.add('d-none');
                addBtn.classList.remove('d-none');
            } else {
                stepper.querySelector('.item-qty-value').textContent = data.new_quantity;
            }

            updateSummary(data.cart_count, data.cart_subtotal);
        });
    }

    stepper.querySelector('.qty-plus').addEventListener('click', function () {
        const current = parseInt(stepper.querySelector('.item-qty-value').textContent, 10);
        sendUpdate(current + 1);
    });

    stepper.querySelector('.qty-minus').addEventListener('click', function () {
        const current = parseInt(stepper.querySelector('.item-qty-value').textContent, 10);
        sendUpdate(current - 1);
    });
});
</script>
<?= $this->endSection() ?>
