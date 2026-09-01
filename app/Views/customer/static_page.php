<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4"><?= esc($heading) ?></h4>

<div class="card card-jeevi p-4 mb-3">
    <?php foreach ($body as $paragraph): ?>
        <p><?= esc($paragraph) ?></p>
    <?php endforeach; ?>

    <?php if (! empty($faqs)): ?>
        <hr class="my-3">
        <div class="accordion" id="faqAccordion">
            <?php foreach ($faqs as $i => $faq): [$q, $a] = $faq; ?>
                <div class="accordion-item">
                    <h2 class="accordion-header">
                        <button class="accordion-button <?= $i > 0 ? 'collapsed' : '' ?>" type="button" data-bs-toggle="collapse" data-bs-target="#faq<?= $i ?>">
                            <?= esc($q) ?>
                        </button>
                    </h2>
                    <div id="faq<?= $i ?>" class="accordion-collapse collapse <?= $i === 0 ? 'show' : '' ?>" data-bs-parent="#faqAccordion">
                        <div class="accordion-body text-muted"><?= esc($a) ?></div>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>

        <div class="text-center mt-4">
            <p class="small text-muted mb-2">Still need help?</p>
            <button type="button" class="btn btn-jeevi" onclick="if (window.jeeviChat) { window.jeeviChat.open(); } else { window.location.href = '<?= base_url('login') ?>'; }">
                <i class="bi bi-chat-dots-fill"></i> Start Live Chat
            </button>
        </div>
    <?php endif; ?>
</div>

<?= $this->endSection() ?>
