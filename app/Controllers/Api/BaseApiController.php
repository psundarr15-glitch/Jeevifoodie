<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\UserModel;
use App\Models\DeliveryPartnerModel;
use CodeIgniter\HTTP\ResponseInterface;

/**
 * Shared helpers for the mobile-app-facing REST API: reading the
 * "Authorization: Bearer <token>" header and resolving it to a
 * logged-in customer or delivery partner.
 */
abstract class BaseApiController extends BaseController
{
    protected function bearerToken(): ?string
    {
        $header = $this->request->getHeaderLine('Authorization');
        if ($header && str_starts_with($header, 'Bearer ')) {
            return trim(substr($header, 7));
        }

        return null;
    }

    /**
     * Returns the authenticated customer's user row, or sends a 401 JSON
     * response and returns null if the token is missing/invalid.
     */
    protected function authCustomer(): ?array
    {
        $token = $this->bearerToken();
        if (! $token) {
            $this->response->setStatusCode(401)->setJSON(['success' => false, 'message' => 'Missing API token']);
            return null;
        }

        $user = (new UserModel())->where('api_token', $token)->first();
        if (! $user) {
            $this->response->setStatusCode(401)->setJSON(['success' => false, 'message' => 'Invalid or expired token']);
            return null;
        }

        return $user;
    }

    /**
     * Same idea, for delivery partners.
     */
    protected function authPartner(): ?array
    {
        $token = $this->bearerToken();
        if (! $token) {
            $this->response->setStatusCode(401)->setJSON(['success' => false, 'message' => 'Missing API token']);
            return null;
        }

        $partner = (new DeliveryPartnerModel())->where('api_token', $token)->first();
        if (! $partner) {
            $this->response->setStatusCode(401)->setJSON(['success' => false, 'message' => 'Invalid or expired token']);
            return null;
        }

        return $partner;
    }

    protected function ok($data = []): ResponseInterface
    {
        return $this->response->setJSON(array_merge(['success' => true], $data));
    }

    protected function fail(string $message, int $status = 400): ResponseInterface
    {
        return $this->response->setStatusCode($status)->setJSON(['success' => false, 'message' => $message]);
    }
}
