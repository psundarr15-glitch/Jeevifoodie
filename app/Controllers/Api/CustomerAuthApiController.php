<?php

namespace App\Controllers\Api;

use App\Models\UserModel;
use Config\Services;

class CustomerAuthApiController extends BaseApiController
{
    public function register()
    {
        $model = new UserModel();

        $rules = [
            'name'     => 'required|min_length[2]',
            'email'    => 'required|valid_email|is_unique[users.email]',
            'phone'    => 'required|min_length[10]',
            'password' => 'required|min_length[6]',
        ];

        if (! $this->validate($rules)) {
            return $this->fail(implode(' ', $this->validator->getErrors()));
        }

        $token = bin2hex(random_bytes(32));

        $id = $model->insert([
            'name'      => $this->request->getPost('name'),
            'email'     => $this->request->getPost('email'),
            'phone'     => $this->request->getPost('phone'),
            'password'  => password_hash($this->request->getPost('password'), PASSWORD_DEFAULT),
            'api_token' => $token,
        ]);

        $user = $model->find($id);

        return $this->ok([
            'token' => $token,
            'user'  => ['id' => $user['id'], 'name' => $user['name'], 'email' => $user['email'], 'phone' => $user['phone']],
        ]);
    }

    public function login()
    {
        $model = new UserModel();
        $user = $model->where('email', $this->request->getPost('email'))->first();

        if (! $user || ! password_verify($this->request->getPost('password'), $user['password'])) {
            return $this->fail('Invalid email or password.', 401);
        }

        $token = bin2hex(random_bytes(32));
        $model->update($user['id'], ['api_token' => $token]);

        return $this->ok([
            'token' => $token,
            'user'  => ['id' => $user['id'], 'name' => $user['name'], 'email' => $user['email'], 'phone' => $user['phone']],
        ]);
    }

    public function logout()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        (new UserModel())->update($user['id'], ['api_token' => null]);
        return $this->ok();
    }

    /**
     * Step 1 of "forgot password": generate a 6-digit OTP valid for 15
     * minutes and email it.
     *
     * Reports whether the email actually sent (email_sent) so the app
     * can tell the person clearly instead of silently going nowhere -
     * but only when we found a matching account. If no account matches,
     * we still claim success without attempting anything, so this
     * endpoint can't be used to check which emails have accounts.
     *
     * Requires SMTP to actually be configured in .env - Config\Email
     * defaults to PHP's mail() with no SMTP host, which fails silently
     * on most hosts. Set email.protocol = smtp plus SMTPHost/SMTPUser/
     * SMTPPass/SMTPPort in .env, then check them via
     * /admin/password-reset-diagnose.
     */
    public function forgotPassword()
    {
        $email = trim((string) $this->request->getPost('email'));
        if (! $email) {
            return $this->fail('Email is required.');
        }

        $model = new UserModel();
        $user = $model->where('email', $email)->first();

        // Default true (nothing to report) when there's no matching
        // account at all, so the response doesn't leak account existence.
        $emailSent = true;

        if ($user) {
            $otp = (string) random_int(100000, 999999);
            $updated = $model->update($user['id'], [
                'reset_otp'            => $otp,
                'reset_otp_expires_at' => date('Y-m-d H:i:s', strtotime('+15 minutes')),
            ]);

            // update() returns false (not an exception) when e.g. the
            // reset_otp column doesn't exist yet because the migration
            // wasn't run.
            if (! $updated) {
                log_message(
                    'error',
                    'Password reset: failed to save OTP for user ' . $user['id']
                    . '. Check that the AddPasswordResetToUsers migration has been run.'
                );
                $emailSent = false;
            } else {
                $emailSent = $this->sendOtpEmail($user['email'], $user['name'], $otp);
                if (! $emailSent) {
                    log_message('error', 'Password reset: OTP saved but email failed to send to ' . $user['email']);
                }
            }
        }

        return $this->ok([
            'email_sent' => $emailSent,
            'message'    => $emailSent
                ? 'If that email is registered, a reset code has been sent.'
                : "We couldn't send the reset email right now. Please try again in a bit, or contact support.",
        ]);
    }

    /**
     * Step 2: verify the OTP (checked against the stored code and its
     * expiry) and set the new password. The OTP is cleared either way
     * once used so it can't be replayed.
     */
    public function resetPassword()
    {
        $rules = [
            'email'    => 'required|valid_email',
            'otp'      => 'required|exact_length[6]',
            'password' => 'required|min_length[6]',
        ];
        if (! $this->validate($rules)) {
            return $this->fail(implode(' ', $this->validator->getErrors()));
        }

        $model = new UserModel();
        $email = $this->request->getPost('email');
        $user = $model->where('email', $email)->first();

        if (! $user || ! $user['reset_otp'] || $user['reset_otp'] !== $this->request->getPost('otp')) {
            return $this->fail('Invalid or expired code.', 401);
        }

        if (! $user['reset_otp_expires_at'] || strtotime($user['reset_otp_expires_at']) < time()) {
            return $this->fail('This code has expired. Please request a new one.', 401);
        }

        $model->update($user['id'], [
            'password'             => password_hash($this->request->getPost('password'), PASSWORD_DEFAULT),
            'reset_otp'            => null,
            'reset_otp_expires_at' => null,
            'api_token'            => null, // force re-login everywhere after a password reset
        ]);

        return $this->ok(['message' => 'Password updated. Please log in with your new password.']);
    }

    private function sendOtpEmail(string $to, string $name, string $otp): bool
    {
        try {
            $email = Services::email();

            // Config\Email's fromEmail/fromName are blank by default, and
            // CodeIgniter's mail library refuses to send at all without a
            // From header ("Cannot send mail with no 'From' header").
            // Prefer an explicit email.fromEmail/.fromName from .env if
            // set, otherwise fall back to the SMTP login itself so this
            // works even if that's the only mail setting configured.
            $config = config('Email');
            $fromEmail = $config->fromEmail !== '' ? $config->fromEmail : $config->SMTPUser;
            $fromName = $config->fromName !== '' ? $config->fromName : 'Jeevi Foodie';
            $email->setFrom($fromEmail, $fromName);

            $email->setTo($to);
            $email->setSubject('Your Jeevi Foodie password reset code');
            $email->setMessage(
                "Hi {$name},\n\nYour password reset code is: {$otp}\n\n"
                . "This code expires in 15 minutes. If you didn't request this, you can ignore this email."
            );
            return $email->send();
        } catch (\Throwable $e) {
            log_message('error', 'sendOtpEmail: ' . $e->getMessage());
            return false;
        }
    }
}
