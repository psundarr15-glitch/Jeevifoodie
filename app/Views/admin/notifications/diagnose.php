<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Firebase Setup Diagnosis</h3>

<div class="card card-jeevi p-4" style="max-width: 700px;">
    <p class="text-muted small mb-3">Checked top to bottom - fix the first FAILED step, then reload this page.</p>
    <table class="table mb-0">
        <tbody>
        <?php foreach ($report as $step => $result): ?>
            <tr>
                <td style="width: 45%;"><?= esc($step) ?></td>
                <td>
                    <?php if (str_starts_with($result, 'OK')): ?>
                        <span class="text-success fw-bold"><?= esc($result) ?></span>
                    <?php elseif (str_starts_with($result, 'FAILED') || str_starts_with($result, 'MISSING')): ?>
                        <span class="text-danger fw-bold"><?= esc($result) ?></span>
                    <?php else: ?>
                        <span class="text-muted"><?= esc($result) ?></span>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<a href="<?= base_url('admin/notifications') ?>" class="btn btn-jeevi-outline mt-3">Back to Notifications</a>
<?= $this->endSection() ?>
