<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4">My Wallet</h4>

<div class="card card-jeevi p-4 mb-4 text-center" style="background: linear-gradient(135deg, var(--jeevi-red), #ff6b6b); color: #fff;">
    <p class="mb-1 opacity-75">Available Balance</p>
    <h1 class="fw-bold mb-0">₹<?= number_format($balance, 2) ?></h1>
</div>

<h6 class="fw-bold mb-3">Transaction History</h6>
<?php if (empty($transactions)): ?>
    <p class="text-muted">No wallet transactions yet.</p>
<?php else: ?>
    <div class="card card-jeevi">
        <div class="list-group list-group-flush">
            <?php foreach ($transactions as $tx): ?>
                <div class="list-group-item d-flex justify-content-between align-items-center py-3">
                    <div>
                        <strong><?= esc($tx['description'] ?: ucfirst($tx['type'])) ?></strong>
                        <p class="small text-muted mb-0"><?= esc($tx['created_at']) ?></p>
                    </div>
                    <span class="fw-bold <?= $tx['type'] === 'credit' ? 'text-success' : 'text-danger' ?>">
                        <?= $tx['type'] === 'credit' ? '+' : '−' ?>₹<?= number_format($tx['amount'], 2) ?>
                    </span>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
<?php endif; ?>

<?= $this->endSection() ?>
