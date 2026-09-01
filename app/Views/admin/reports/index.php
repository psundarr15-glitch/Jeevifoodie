<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4">Sales Report <?php if ($is_manager): ?><span class="badge bg-secondary fs-6">Your Restaurant</span><?php endif; ?></h3>

<form method="get" action="<?= base_url('admin/reports') ?>" class="card card-jeevi p-3 mb-4">
    <div class="row g-3 align-items-end">
        <div class="col-auto">
            <label class="form-label mb-1">From</label>
            <input type="date" name="date_from" value="<?= esc($date_from) ?>" class="form-control" max="<?= date('Y-m-d') ?>">
        </div>
        <div class="col-auto">
            <label class="form-label mb-1">To</label>
            <input type="date" name="date_to" value="<?= esc($date_to) ?>" class="form-control" max="<?= date('Y-m-d') ?>">
        </div>
        <?php if (! $is_manager): ?>
            <div class="col-auto">
                <label class="form-label mb-1">Restaurant</label>
                <select name="restaurant_id" class="form-select">
                    <option value="">All Restaurants</option>
                    <?php foreach ($restaurants as $r): ?>
                        <option value="<?= $r['id'] ?>" <?= $restaurant_id == $r['id'] ? 'selected' : '' ?>><?= esc($r['name']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        <?php endif; ?>
        <div class="col-auto">
            <button type="submit" class="btn btn-jeevi">Apply</button>
            <a href="<?= base_url('admin/reports') ?>" class="btn btn-jeevi-outline">Reset</a>
        </div>
    </div>
</form>

<div class="row mb-4">
    <div class="col-md-3 mb-3">
        <div class="card card-jeevi p-3 text-center">
            <h2><?= (int) $total_orders ?></h2><span>Orders in range</span>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="card card-jeevi p-3 text-center">
            <h2>₹<?= number_format($revenue, 2) ?></h2><span>Revenue (Paid, <?= (int) $paid_orders ?> orders)</span>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="card card-jeevi p-3 text-center">
            <h2>₹<?= number_format($avg_order_value, 2) ?></h2><span>Avg. Order Value</span>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="card card-jeevi p-3 text-center">
            <h2>₹<?= number_format($total_discount, 2) ?></h2><span>Discounts Given</span>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-7 mb-4">
        <h5 class="section-title mb-3">Daily Sales</h5>
        <div class="card card-jeevi p-3">
            <?php if (empty($daily_sales)): ?>
                <p class="text-muted mb-0">No orders in this date range.</p>
            <?php else: ?>
                <?php foreach ($daily_sales as $d): ?>
                    <?php $pct = $max_daily_revenue > 0 ? round(($d['revenue'] / $max_daily_revenue) * 100) : 0; ?>
                    <div class="d-flex align-items-center mb-2">
                        <div style="width:90px;" class="small text-muted"><?= esc($d['day']) ?></div>
                        <div class="flex-grow-1 bg-light rounded" style="height:18px;">
                            <div class="bg-jeevi-red rounded" style="height:18px;width:<?= max($pct, 2) ?>%;background:var(--jeevi-red,#e53935);"></div>
                        </div>
                        <div style="width:130px;" class="small text-end">₹<?= number_format($d['revenue'], 2) ?> (<?= (int) $d['orders'] ?>)</div>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>

        <h5 class="section-title mb-3 mt-4">Orders by Status</h5>
        <div class="card card-jeevi">
            <table class="table mb-0">
                <thead><tr><th>Status</th><th>Count</th></tr></thead>
                <tbody>
                <?php foreach ($status_breakdown as $s): ?>
                    <tr><td><?= order_status_label($s['order_status']) ?></td><td><?= (int) $s['count'] ?></td></tr>
                <?php endforeach; ?>
                <?php if (empty($status_breakdown)): ?>
                    <tr><td colspan="2" class="text-muted">No orders in this date range.</td></tr>
                <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    <div class="col-md-5 mb-4">
        <h5 class="section-title mb-3">Top-Selling Items</h5>
        <div class="card card-jeevi">
            <table class="table mb-0">
                <thead><tr><th>Item</th><th>Qty Sold</th><th>Revenue</th></tr></thead>
                <tbody>
                <?php foreach ($top_items as $i): ?>
                    <tr>
                        <td><?= esc($i['item_name']) ?></td>
                        <td><?= (int) $i['qty_sold'] ?></td>
                        <td>₹<?= number_format($i['item_revenue'], 2) ?></td>
                    </tr>
                <?php endforeach; ?>
                <?php if (empty($top_items)): ?>
                    <tr><td colspan="3" class="text-muted">No paid orders in this date range yet.</td></tr>
                <?php endif; ?>
                </tbody>
            </table>
        </div>

        <?php if (! $is_manager): ?>
            <h5 class="section-title mb-3 mt-4">Restaurant-wise Revenue</h5>
            <div class="card card-jeevi">
                <table class="table mb-0">
                    <thead><tr><th>Restaurant</th><th>Orders</th><th>Revenue</th></tr></thead>
                    <tbody>
                    <?php foreach ($restaurant_breakdown as $r): ?>
                        <tr>
                            <td><?= esc($r['restaurant_name']) ?></td>
                            <td><?= (int) $r['orders'] ?></td>
                            <td>₹<?= number_format($r['revenue'], 2) ?></td>
                        </tr>
                    <?php endforeach; ?>
                    <?php if (empty($restaurant_breakdown)): ?>
                        <tr><td colspan="3" class="text-muted">No orders in this date range.</td></tr>
                    <?php endif; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>

<?= $this->endSection() ?>
