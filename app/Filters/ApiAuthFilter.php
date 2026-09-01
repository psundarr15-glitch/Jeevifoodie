<?php

namespace App\Filters;

use App\Models\DeliveryPartnerModel;
use App\Models\UserModel;
use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;

/**
 * Route-level safety net for the token-based mobile API.
 *
 * Previously the whole `api` route group had NO filter at all — every
 * endpoint relied on the controller method itself remembering to call
 * BaseApiController::authCustomer()/authPartner(). If any single method
 * forgot that call, the endpoint was silently open to the world.
 *
 * This filter is applied to the routes that require *some* logged-in
 * principal (see Config\Routes) and just confirms the bearer token
 * resolves to a real, currently-valid customer or delivery partner
 * before the controller ever runs. It does NOT replace authCustomer()/
 * authPartner() in the controllers — those still run and still decide
 * *which* principal type a given endpoint needs (customer vs partner);
 * this filter only guarantees nothing protected is reachable with a
 * missing/garbage token.
 */
class ApiAuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $header = $request->getHeaderLine('Authorization');
        $token = ($header && str_starts_with($header, 'Bearer ')) ? trim(substr($header, 7)) : null;

        if (! $token) {
            return service('response')->setStatusCode(401)->setJSON([
                'success' => false,
                'message' => 'Missing API token',
            ]);
        }

        $isCustomer = (new UserModel())->where('api_token', $token)->first();
        $isPartner  = $isCustomer ? null : (new DeliveryPartnerModel())->where('api_token', $token)->first();

        if (! $isCustomer && ! $isPartner) {
            return service('response')->setStatusCode(401)->setJSON([
                'success' => false,
                'message' => 'Invalid or expired token',
            ]);
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
    }
}
