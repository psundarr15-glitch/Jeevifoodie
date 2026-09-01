<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4">Coupons</h4>

<?php if (empty($coupons)): ?>
    <p class="text-muted">No active coupons right now — check back soon!</p>
<?php else: ?>
    <?php foreach ($coupons as $c): ?>
        <div class="promo-card <?= $c['discount_type'] === 'percent' ? 'promo-yellow' : 'promo-red' ?> mb-3">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <div class="promo-title"><?= esc($c['description'] ?: ($c['discount_type'] === 'percent' ? $c['discount_value'] . '% OFF' : '₹' . $c['discount_value'] . ' OFF')) ?></div>
                    <?php if ($c['min_order_value'] > 0): ?>
                        <div class="promo-sub">On orders above ₹<?= esc($c['min_order_value']) ?></div>
                    <?php endif; ?>
                    <div class="promo-code">USE CODE: <?= esc($c['code']) ?></div>
                </div>
                <button type="button" class="btn btn-sm btn-pill-white copy-code-btn" data-code="<?= esc($c['code']) ?>">Copy</button>
            </div>
        </div>
    <?php endforeach; ?>
<?php endif; ?>

<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<script>
document.querySelectorAll('.copy-code-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        navigator.clipboard.writeText(this.dataset.code).then(() => {
            const original = this.textContent;
            this.textContent = 'Copied!';
            setTimeout(() => this.textContent = original, 1500);
        });
    });
});
</script>
<?= $this->endSection() ?>
