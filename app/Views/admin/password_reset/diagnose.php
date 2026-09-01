<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Password Reset / Email Diagnosis</h3>

<div class="card card-jeevi p-4 mb-4" style="max-width: 700px;">
    <p class="text-muted small mb-3">Checked top to bottom - fix the first FAILED/MISSING step, then reload this page.</p>
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

<div class="card card-jeevi p-4 mb-4" style="max-width: 700px;">
    <h5>Send a test email</h5>
    <p class="text-muted small">Confirms your SMTP settings actually deliver, independent of the app.</p>
    <form method="get" class="d-flex gap-2">
        <input type="email" name="test_email" class="form-control" placeholder="you@example.com" value="<?= esc($testResult['to'] ?? '') ?>" required>
        <button class="btn btn-jeevi">Send Test</button>
    </form>

    <?php if ($testResult): ?>
        <div class="mt-3">
            <?php if ($testResult['success']): ?>
                <span class="text-success fw-bold">Sent to <?= esc($testResult['to']) ?> - check that inbox (and spam folder).</span>
            <?php else: ?>
                <span class="text-danger fw-bold">Failed to send to <?= esc($testResult['to']) ?>.</span>
                <pre class="small bg-light p-2 mt-2" style="white-space: pre-wrap;"><?= esc($testResult['debug']) ?></pre>
            <?php endif; ?>
        </div>
    <?php endif; ?>
</div>

<div class="card card-jeevi p-4" style="max-width: 700px;">
    <h5>Users currently mid-reset</h5>
    <?php if (empty($pending)): ?>
        <p class="text-muted small mb-0">None - either nobody has requested a reset recently, or (per step 1 above) OTPs aren't being saved.</p>
    <?php else: ?>
        <table class="table mb-0">
            <thead><tr><th>Email</th><th>Code expires</th></tr></thead>
            <tbody>
            <?php foreach ($pending as $u): ?>
                <tr><td><?= esc($u['email']) ?></td><td><?= esc($u['reset_otp_expires_at']) ?></td></tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</div>
<?= $this->endSection() ?>
