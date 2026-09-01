<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4"><?= t('change_language') ?></h4>

<div class="card card-jeevi p-4">
    <?php $current = session()->get('site_lang') ?? 'en'; ?>
    <a href="<?= base_url('lang/en') ?>" class="d-flex justify-content-between align-items-center py-3 border-bottom text-decoration-none text-dark">
        <span class="fs-5">English</span>
        <?php if ($current === 'en'): ?><i class="bi bi-check-circle-fill text-success fs-4"></i><?php endif; ?>
    </a>
    <a href="<?= base_url('lang/ta') ?>" class="d-flex justify-content-between align-items-center py-3 text-decoration-none text-dark">
        <span class="fs-5">தமிழ் (Tamil)</span>
        <?php if ($current === 'ta'): ?><i class="bi bi-check-circle-fill text-success fs-4"></i><?php endif; ?>
    </a>
</div>

<?= $this->endSection() ?>
