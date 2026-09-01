<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<div class="hero-banner mb-4">
    <div class="offer-starburst">
        <span>UPTO</span>
        <span class="big">40%</span>
        <span>OFF</span>
    </div>
    <div class="row w-100">
        <div class="col-md-8">
            <h1>Super</h1>
            <div class="subtitle">Delicious Food</div>
            <a href="<?= base_url('restaurants') ?>" class="btn btn-pill-white mt-3">Order Now</a>
        </div>
    </div>
</div>

<h5 class="section-title mb-3">Browse Categories</h5>
<div class="row text-center mb-4">
    <?php $icons = ['Biryani' => 'bi-egg-fried', 'Pizza' => 'bi-pie-chart-fill', 'Burger' => 'bi-cup-hot-fill', 'Chicken' => 'bi-fire', 'Desserts' => 'bi-cake2-fill', 'Beverages' => 'bi-cup-straw']; ?>
    <?php foreach ($categories as $cat): ?>
        <div class="col-4 col-md-2 mb-3">
            <a href="<?= base_url('restaurants?q=' . urlencode($cat['name'])) ?>" class="category-pill">
                <div class="category-circle"><i class="bi <?= $icons[$cat['name']] ?? 'bi-egg-fried' ?> text-danger"></i></div>
                <span><?= esc($cat['name']) ?></span>
            </a>
        </div>
    <?php endforeach; ?>
    <div class="col-4 col-md-2 mb-3">
        <a href="<?= base_url('restaurants') ?>" class="category-pill">
            <div class="category-circle"><i class="bi bi-grid-3x3-gap-fill text-danger"></i></div>
            <span>More</span>
        </a>
    </div>
</div>

<?php if (!empty($coupons)): ?>
<h5 class="section-title mb-3">Best Offers For You</h5>
<div class="row mb-4">
    <div class="col-md-6 mb-3">
        <div class="promo-card promo-yellow">
            <i class="bi bi-truck fs-3 mb-1"></i>
            <div class="promo-title">Free Delivery</div>
            <div class="promo-sub">On orders above ₹199</div>
        </div>
    </div>
    <?php foreach ($coupons as $c): ?>
        <div class="col-md-6 mb-3">
            <div class="promo-card promo-red">
                <div class="promo-title"><?= esc($c['description']) ?></div>
                <span class="promo-code">USE CODE: <?= esc($c['code']) ?></span>
            </div>
        </div>
    <?php endforeach; ?>
</div>
<?php endif; ?>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="section-title mb-0">Popular Restaurants</h5>
    <a href="<?= base_url('restaurants') ?>" class="text-danger fw-bold text-decoration-none">View All &raquo;</a>
</div>
<div class="row">
    <?php foreach ($restaurants as $r): ?>
        <?php $isOpen = \App\Models\RestaurantModel::isOpenNow($r); ?>
        <?php $liked = isset($liked_by_me[$r['id']]); ?>
        <div class="col-md-3 col-6 mb-4 position-relative">
            <?php if (session()->get('logged_in')): ?>
                <button type="button" class="card-like-overlay like-toggle-btn <?= $liked ? 'liked' : '' ?>" data-restaurant-id="<?= $r['id'] ?>">
                    <i class="bi <?= $liked ? 'bi-heart-fill' : 'bi-heart' ?>"></i>
                </button>
            <?php endif; ?>
            <a href="<?= base_url('restaurants/' . $r['id']) ?>" class="text-decoration-none text-dark">
                <div class="card card-jeevi h-100 <?= $isOpen ? '' : 'restaurant-closed' ?>">
                    <div class="card-img-wrap">
                        <img class="cover-img h-sm" src="<?= esc($r['image'] ?: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&h=350&fit=crop') ?>" alt="<?= esc($r['name']) ?>" onerror="this.src='https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&h=350&fit=crop'">
                        <span class="open-status-chip <?= $isOpen ? 'open' : 'closed' ?>"><?= $isOpen ? 'Open Now' : 'Closed' ?></span>
                    </div>
                    <?php if ($r['discount_label']): ?>
                        <span class="discount-chip"><?= esc($r['discount_label']) ?></span>
                    <?php endif; ?>
                    <div class="card-body pt-2">
                        <h6 class="fw-bold mb-1"><?= esc($r['name']) ?></h6>
                        <span class="rating-badge">★ <?= esc($r['rating']) ?></span>
                        <span class="text-muted small">(<?= (int)$r['rating_count'] ?>+)</span>
                        <p class="small text-muted mt-1 mb-0"><?= esc($r['prep_time_min']) ?>-<?= esc($r['prep_time_max']) ?> min</p>
                    </div>
                </div>
            </a>
        </div>
    <?php endforeach; ?>
</div>

<script>
document.querySelectorAll('.like-toggle-btn').forEach(btn => {
    btn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        const id = this.dataset.restaurantId;
        fetch(`<?= base_url('restaurants/') ?>${id}/like`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: '<?= csrf_token() ?>=<?= csrf_hash() ?>'
        })
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;
            this.classList.toggle('liked', data.liked);
            this.querySelector('i').className = 'bi ' + (data.liked ? 'bi-heart-fill' : 'bi-heart');
        });
    });
});
</script>

<h5 class="section-title mb-3 mt-3">Why Choose <span class="text-danger">JEEVI</span> Foodie Delivery?</h5>
<div class="row text-center mb-4">
    <div class="col-6 col-md-3 mb-3 why-choose-item">
        <div class="why-choose-icon"><i class="bi bi-egg-fried"></i></div>
        <div class="label">Wide Range<br>of Cuisines</div>
    </div>
    <div class="col-6 col-md-3 mb-3 why-choose-item">
        <div class="why-choose-icon"><i class="bi bi-award-fill"></i></div>
        <div class="label">Best Quality<br>Food</div>
    </div>
    <div class="col-6 col-md-3 mb-3 why-choose-item">
        <div class="why-choose-icon"><i class="bi bi-lightning-charge-fill"></i></div>
        <div class="label">Lightning<br>Fast Delivery</div>
    </div>
    <div class="col-6 col-md-3 mb-3 why-choose-item">
        <div class="why-choose-icon"><i class="bi bi-emoji-smile-fill"></i></div>
        <div class="label">Happy Customers<br>Everyday</div>
    </div>
</div>

<?= $this->endSection() ?>
