<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4">My Orders</h4>

<?php if (empty($orders)): ?>
    <p class="text-muted">You haven't placed any orders yet.</p>
<?php else: ?>
    <?php foreach ($orders as $o): ?>
        <div class="card card-jeevi mb-3">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center flex-wrap">
                    <div>
                        <strong>#<?= esc($o['order_code']) ?></strong>
                        <span class="badge bg-secondary ms-2"><?= order_status_label($o['order_status']) ?></span>
                        <p class="small text-muted mb-0">₹<?= number_format($o['total'], 2) ?> &bull; <?= esc($o['placed_at']) ?></p>
                    </div>
                    <a href="<?= base_url('order/track/' . $o['order_code']) ?>" class="btn btn-jeevi-outline">Track Order</a>
                </div>

                <?php if ($o['order_status'] === 'delivered'): ?>
                    <?php if (in_array($o['id'], $reviewedOrderIds)): ?>
                        <p class="small text-success mt-2 mb-0">✓ You rated this order</p>
                    <?php else: ?>
                        <hr>
                        <form method="post" action="<?= base_url('review/store') ?>" class="star-rating-form">
                            <?= csrf_field() ?>
                            <input type="hidden" name="order_id" value="<?= $o['id'] ?>">

                            <label class="small fw-bold d-block mb-1">Rate the restaurant</label>
                            <div class="star-rating mb-3">
                                <?php for ($i = 5; $i >= 1; $i--): ?>
                                    <input type="radio" id="star<?= $o['id'] ?>_<?= $i ?>" name="rating" value="<?= $i ?>" required>
                                    <label for="star<?= $o['id'] ?>_<?= $i ?>">★</label>
                                <?php endfor; ?>
                            </div>

                            <?php if ($o['delivery_partner_id']): ?>
                                <label class="small fw-bold d-block mb-1">Rate the delivery partner</label>
                                <div class="star-rating mb-3">
                                    <?php for ($i = 5; $i >= 1; $i--): ?>
                                        <input type="radio" id="pstar<?= $o['id'] ?>_<?= $i ?>" name="partner_rating" value="<?= $i ?>" required>
                                        <label for="pstar<?= $o['id'] ?>_<?= $i ?>">★</label>
                                    <?php endfor; ?>
                                </div>
                            <?php endif; ?>

                            <input type="text" name="comment" class="form-control form-control-sm mb-2" placeholder="Add a comment (optional)">
                            <button type="submit" class="btn btn-sm btn-jeevi">Submit Rating</button>
                        </form>
                    <?php endif; ?>
                <?php endif; ?>
            </div>
        </div>
    <?php endforeach; ?>
<?php endif; ?>

<?= $this->endSection() ?>
