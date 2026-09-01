<?php

namespace App\Libraries;

/**
 * Minimal Razorpay REST API client using plain cURL — no Composer package
 * needed. Reads credentials from .env (razorpay.keyId / razorpay.keySecret),
 * so the actual key/secret never live in committed source code.
 */
class RazorpayClient
{
    protected string $keyId;
    protected string $keySecret;

    public function __construct()
    {
        $this->keyId = env('razorpay.keyId', '');
        $this->keySecret = env('razorpay.keySecret', '');
    }

    public function isConfigured(): bool
    {
        return $this->keyId !== '' && $this->keySecret !== '';
    }

    public function keyId(): string
    {
        return $this->keyId;
    }

    /**
     * Creates a Razorpay Order for the given amount in rupees.
     * Returns ['success' => bool, 'order_id' => ?string, 'error' => ?string]
     */
    public function createOrder(float $amountRupees, string $receipt): array
    {
        if (! $this->isConfigured()) {
            return ['success' => false, 'error' => 'Razorpay keys are not configured on the server.'];
        }

        $payload = json_encode([
            'amount'   => (int) round($amountRupees * 100), // Razorpay expects paise
            'currency' => 'INR',
            'receipt'  => $receipt,
        ]);

        $ch = curl_init('https://api.razorpay.com/v1/orders');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_USERPWD        => $this->keyId . ':' . $this->keySecret,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_TIMEOUT        => 15,
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($curlError) {
            return ['success' => false, 'error' => 'Connection error: ' . $curlError];
        }

        $data = json_decode($response, true);

        if ($httpCode !== 200 || empty($data['id'])) {
            $message = $data['error']['description'] ?? 'Razorpay order creation failed.';
            return ['success' => false, 'error' => $message];
        }

        return ['success' => true, 'order_id' => $data['id']];
    }

    /**
     * Verifies the signature Razorpay's Checkout.js returns after a
     * successful payment, per Razorpay's documented HMAC-SHA256 scheme.
     */
    public function verifySignature(string $razorpayOrderId, string $razorpayPaymentId, string $razorpaySignature): bool
    {
        if (! $this->isConfigured()) {
            return false;
        }

        $expected = hash_hmac('sha256', $razorpayOrderId . '|' . $razorpayPaymentId, $this->keySecret);

        return hash_equals($expected, $razorpaySignature);
    }
}
