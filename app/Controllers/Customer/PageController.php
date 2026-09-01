<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;

/**
 * Simple static informational pages (About Us, Terms, Privacy, Refund,
 * Shipping) — linked from the Profile menu.
 */
class PageController extends BaseController
{
    public function about()
    {
        return view('customer/pages/about');
    }

    public function terms()
    {
        return view('customer/pages/terms');
    }

    public function privacy()
    {
        return view('customer/pages/privacy');
    }

    public function refundPolicy()
    {
        return view('customer/pages/refund_policy');
    }

    public function shippingPolicy()
    {
        return view('customer/pages/shipping_policy');
    }
}
