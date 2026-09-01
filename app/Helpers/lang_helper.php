<?php

if (! function_exists('t')) {
    /**
     * Very lightweight translation lookup — not a full i18n system, just
     * enough to switch key UI strings between English and Tamil based on
     * the visitor's session('site_lang'). Falls back to the English string
     * (or the key itself) if nothing is found, so it's always safe to call.
     *
     * Currently covers the main navigation and Profile page. Extending
     * coverage to more pages just means adding more keys to $strings below.
     */
    function t(string $key): string
    {
        static $strings = [
            'home'               => ['en' => 'Home',               'ta' => 'முகப்பு'],
            'restaurants'        => ['en' => 'Restaurants',         'ta' => 'உணவகங்கள்'],
            'my_orders'          => ['en' => 'My Orders',           'ta' => 'எனது ஆர்டர்கள்'],
            'cart'               => ['en' => 'Cart',                'ta' => 'கார்ட்'],
            'profile'            => ['en' => 'Profile',             'ta' => 'சுயவிவரம்'],
            'login'              => ['en' => 'Login',                'ta' => 'உள்நுழைய'],
            'register'           => ['en' => 'Register',             'ta' => 'பதிவு செய்ய'],
            'logout'             => ['en' => 'Logout',                'ta' => 'வெளியேறு'],
            'search_placeholder' => ['en' => 'Search for food, restaurants...', 'ta' => 'உணவு, உணவகங்களைத் தேடுங்கள்...'],

            'my_profile'         => ['en' => 'My Profile',          'ta' => 'எனது சுயவிவரம்'],
            'account_details'    => ['en' => 'Account Details',      'ta' => 'கணக்கு விவரங்கள்'],
            'full_name'          => ['en' => 'Full Name',            'ta' => 'முழு பெயர்'],
            'email'              => ['en' => 'Email',                'ta' => 'மின்னஞ்சல்'],
            'phone'              => ['en' => 'Phone',                'ta' => 'தொலைபேசி'],
            'save_changes'       => ['en' => 'Save Changes',         'ta' => 'மாற்றங்களை சேமி'],
            'my_addresses'       => ['en' => 'My Delivery Addresses','ta' => 'எனது டெலிவரி முகவரிகள்'],
            'add_new_address'    => ['en' => 'Add New Address',      'ta' => 'புதிய முகவரி சேர்'],

            'join_as_delivery'   => ['en' => 'Join as a Delivery Partner', 'ta' => 'டெலிவரி பார்ட்னராக சேருங்கள்'],
            'open_vendor'        => ['en' => 'Register Your Restaurant',  'ta' => 'உங்கள் உணவகத்தை பதிவு செய்யுங்கள்'],
            'help_support'       => ['en' => 'Help & Support',        'ta' => 'உதவி மற்றும் ஆதரவு'],
            'live_chat'          => ['en' => 'Live Chat',             'ta' => 'நேரடி அரட்டை'],
            'about_us'           => ['en' => 'About Us',              'ta' => 'எங்களைப் பற்றி'],
            'terms_conditions'   => ['en' => 'Terms & Conditions',    'ta' => 'விதிமுறைகள் மற்றும் நிபந்தனைகள்'],
            'privacy_policy'     => ['en' => 'Privacy Policy',        'ta' => 'தனியுரிமைக் கொள்கை'],
            'refund_policy'      => ['en' => 'Refund Policy',         'ta' => 'பணத்தைத் திரும்பப்பெறும் கொள்கை'],
            'shipping_policy'    => ['en' => 'Shipping Policy',       'ta' => 'டெலிவரி கொள்கை'],
            'change_language'    => ['en' => 'Language',              'ta' => 'மொழி'],
        ];

        $locale = session()->get('site_lang') ?? 'en';

        return $strings[$key][$locale] ?? $strings[$key]['en'] ?? $key;
    }
}
