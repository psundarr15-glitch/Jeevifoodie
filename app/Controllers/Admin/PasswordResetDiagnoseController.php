<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\UserModel;
use Config\Services;

class PasswordResetDiagnoseController extends BaseController
{
    public function index()
    {
        $report = [];

        // 1) DB migration check - this is the #1 cause of "no OTP saved":
        // if the migration hasn't been run, the reset_otp columns don't
        // exist, so UserModel::update() silently fails (no exception,
        // because CodeIgniter model update() just returns false when
        // DBDebug is off in production) - the API still responds
        // "success" either way so the app doesn't notice.
        $db = db_connect();
        $hasOtpColumn = $db->fieldExists('reset_otp', 'users');
        $report['1. reset_otp column exists on users table'] = $hasOtpColumn
            ? 'OK'
            : 'MISSING - run "php spark migrate" on the server to add it (migration: AddPasswordResetToUsers). Until this runs, OTPs cannot be saved at all.';

        // 2) Email protocol/config check
        $emailConfig = config('Email');
        $protocol = $emailConfig->protocol;
        $report['2. email.protocol in .env'] = $protocol === 'smtp'
            ? 'OK - set to "smtp"'
            : "using \"{$protocol}\" - most shared hosting blocks PHP's mail() function or routes it to spam. Set email.protocol = smtp in .env for reliable delivery.";

        if ($protocol === 'smtp') {
            $report['3. email.SMTPHost in .env'] = $emailConfig->SMTPHost !== ''
                ? "OK - set to \"{$emailConfig->SMTPHost}\""
                : 'MISSING - add email.SMTPHost to .env';
            $report['4. email.SMTPUser in .env'] = $emailConfig->SMTPUser !== ''
                ? 'OK - set'
                : 'MISSING - add email.SMTPUser to .env';
            $report['5. email.SMTPPass in .env'] = $emailConfig->SMTPPass !== ''
                ? 'OK - set'
                : 'MISSING - add email.SMTPPass to .env';

            // Port 25 (CodeIgniter's default when this isn't set at all)
            // works for very few hosts anymore, and specifically won't
            // offer STARTTLS on most shared hosting - causing exactly
            // "503 STARTTLS command used when not advertised" when
            // SMTPCrypto is set to tls. 587 (STARTTLS) or 465 (implicit
            // SSL, needs SMTPCrypto = ssl) are almost always the right
            // choice instead.
            $report['5b. email.SMTPPort in .env'] = $emailConfig->SMTPPort == 25
                ? 'Using port 25 (the default) with SMTPCrypto=' . $emailConfig->SMTPCrypto . ' - this combination fails on most hosts. Set email.SMTPPort = 587 in .env (keep SMTPCrypto = tls), or if that also fails, try email.SMTPPort = 465 with email.SMTPCrypto = ssl.'
                : "Using port {$emailConfig->SMTPPort} with SMTPCrypto={$emailConfig->SMTPCrypto}";
        }

        // 6) The "From" address - CodeIgniter's mail library refuses to
        // send at all without one ("Cannot send mail with no 'From'
        // header"), and email.fromEmail/.fromName in Config\Email are
        // blank by default. The actual send methods (forgotPassword's
        // sendOtpEmail, and the test-send below) already fall back to
        // SMTPUser when this is blank, so this step can never truly
        // block sending - it just tells you which address will show up
        // as the sender.
        $fromEmail = $emailConfig->fromEmail !== '' ? $emailConfig->fromEmail : $emailConfig->SMTPUser;
        $report['6. "From" address that will be used'] = $fromEmail !== ''
            ? "\"{$fromEmail}\" (" . ($emailConfig->fromEmail !== '' ? 'from email.fromEmail' : 'falling back to email.SMTPUser - add email.fromEmail to .env to use a different address') . ')'
            : 'MISSING - set email.fromEmail (or email.SMTPUser) in .env, or sending will fail with "Cannot send mail with no From header"';

        // 7) Optional: actually try sending, if a test address was submitted
        $testResult = null;
        $testTo = $this->request->getGet('test_email');
        if ($testTo) {
            $email = Services::email();
            $email->setFrom($fromEmail !== '' ? $fromEmail : 'no-reply@example.com', 'Jeevi Foodie');
            $email->setTo($testTo);
            $email->setSubject('Jeevi Foodie - test email');
            $email->setMessage('This is a test email from the password-reset diagnostic page. If you received this, SMTP is working.');
            $sent = $email->send();
            $testResult = [
                'to' => $testTo,
                'success' => $sent,
                'debug' => $sent ? null : $email->printDebugger(['headers']),
            ];
        }

        // 8) Any users currently mid-reset (helps confirm #1 in practice) -
        // only query this if the column actually exists, otherwise this
        // whole diagnostic page would crash with an SQL error instead of
        // reporting the missing-migration problem cleanly.
        $pending = [];
        if ($hasOtpColumn) {
            $pending = (new UserModel())
                ->select('id, email, reset_otp_expires_at')
                ->where('reset_otp IS NOT NULL')
                ->findAll(5);
        }

        return view('admin/password_reset/diagnose', [
            'report'     => $report,
            'testResult' => $testResult,
            'pending'    => $pending,
        ]);
    }
}
