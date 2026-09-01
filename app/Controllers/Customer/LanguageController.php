<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;

class LanguageController extends BaseController
{
    public function show()
    {
        return view('customer/language');
    }

    /**
     * Sets the site language in session and redirects back to wherever
     * the user was. Only 'en' and 'ta' are supported right now.
     */
    public function switch($locale)
    {
        if (in_array($locale, ['en', 'ta'], true)) {
            session()->set('site_lang', $locale);
        }

        return redirect()->back();
    }
}
