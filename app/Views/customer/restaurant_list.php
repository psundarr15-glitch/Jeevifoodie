<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h5 class="section-title mb-3">Recommended for you</h5>
<div class="row">
    <?php if (empty($restaurants)): ?>
        <p class="text-muted">No restaurants found<?= $keyword ? ' for "' . esc($keyword) . '"' : '' ?>.</p>
    <?php endif; ?>
    <?php foreach ($restaurants as $r): ?>
        <?php $isOpen = \App\Models\RestaurantModel::isOpenNow($r); ?>
        <?php $liked = isset($liked_by_me[$r['id']]); ?>
        <?php $likeCount = $like_counts[$r['id']] ?? 0; ?>
        <div class="col-md-4 col-6 mb-4 position-relative">
            <?php if (session()->get('logged_in')): ?>
                <button type="button" class="card-like-overlay like-toggle-btn <?= $liked ? 'liked' : '' ?>" data-restaurant-id="<?= $r['id'] ?>">
                    <i class="bi <?= $liked ? 'bi-heart-fill' : 'bi-heart' ?>"></i>
                </button>
            <?php endif; ?>
            <a href="<?= base_url('restaurants/' . $r['id']) ?>" class="text-decoration-none text-dark">
                <div class="card card-jeevi h-100 <?= $isOpen ? '' : 'restaurant-closed' ?>">
                    <div class="card-img-wrap">
                        <img class="cover-img h-md" src="<?= esc($r['image'] ?: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&h=350&fit=crop') ?>" alt="<?= esc($r['name']) ?>" onerror="this.src='https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&h=350&fit=crop'">
                        <span class="open-status-chip <?= $isOpen ? 'open' : 'closed' ?>"><?= $isOpen ? 'Open Now' : 'Closed' ?></span>
                    </div>
                    <?php if ($r['discount_label']): ?>
                        <span class="discount-chip"><?= esc($r['discount_label']) ?></span>
                    <?php endif; ?>
                    <div class="card-body pt-2">
                        <h6 class="fw-bold mb-1"><?= esc($r['name']) ?></h6>
                        <p class="small text-muted mb-1"><?= esc($r['cuisine']) ?></p>
                        <span class="rating-badge">★ <?= esc($r['rating']) ?></span>
                        <span class="text-muted small">(<?= (int)$r['rating_count'] ?>+)</span>
                        <p class="small text-muted mt-1 mb-0"><?= esc($r['prep_time_min']) ?>-<?= esc($r['prep_time_max']) ?> min &bull; ₹<?= esc($r['cost_for_two']) ?> for two</p>
                        <p class="small text-muted mt-1 mb-0"><span class="like-count-<?= $r['id'] ?>"><?= $likeCount ?></span> like<?= $likeCount == 1 ? '' : 's' ?></p>
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
            const countEls = document.querySelectorAll('.like-count-' + id);
            countEls.forEach(el => el.textContent = data.like_count);
        });
    });
});
</script>

<div class="row text-center mt-4 pt-3 border-top">
    <div class="col-4 trust-badge">
        <i class="bi bi-geo-alt-fill"></i>
        <span class="label">Live Tracking</span>
        <span class="sub">Track your order</span>
    </div>
    <div class="col-4 trust-badge">
        <i class="bi bi-shield-check"></i>
        <span class="label">Secure Payment</span>
        <span class="sub">100% Secure</span>
    </div>
    <div class="col-4 trust-badge">
        <i class="bi bi-arrow-repeat"></i>
        <span class="label">Easy Returns</span>
        <span class="sub">Hassle free</span>
    </div>
</div>

<?= $this->endSection() ?>
