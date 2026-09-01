<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;

/**
 * Protects the admin/restaurant management panel.
 */
class AdminFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $session = session();
        if (! $session->get('admin_id')) {
            return redirect()->to('/admin/login');
        }

        // Restaurant managers only ever touch their own restaurant's data
        // (enforced per-controller in Restaurants/MenuItems/Orders/Dashboard).
        // Everything else in the admin panel — categories, coupons, delivery
        // partners, customer accounts, and manager accounts themselves — is
        // superadmin-only. Block it centrally here so a manager can't reach
        // it just by typing the URL directly.
        if ($session->get('admin_role') === 'restaurant_manager') {
            $uri = $request->getUri()->getPath();
            $blockedPrefixes = ['admin/categories', 'admin/coupons', 'admin/delivery-partners', 'admin/users', 'admin/managers', 'admin/notifications/diagnose', 'admin/password-reset-diagnose'];
            foreach ($blockedPrefixes as $prefix) {
                if (strpos($uri, $prefix) === 0) {
                    $session->setFlashdata('error', 'That section is only available to superadmins.');
                    return redirect()->to('/admin/dashboard');
                }
            }
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
    }
}
