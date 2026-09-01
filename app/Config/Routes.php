<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */

// ==================== CUSTOMER-FACING ROUTES ====================
$routes->get('/', 'Customer\HomeController::index');

$routes->get('login', 'Customer\AuthController::showLogin');
$routes->post('login', 'Customer\AuthController::login');
$routes->get('register', 'Customer\AuthController::showRegister');
$routes->post('register', 'Customer\AuthController::register');
$routes->get('logout', 'Customer\AuthController::logout');

$routes->get('restaurants', 'Customer\RestaurantController::index');
$routes->get('restaurants/(:num)', 'Customer\RestaurantController::view/$1');

// Routes requiring a logged-in customer
$routes->group('', ['filter' => 'auth'], static function ($routes) {
    $routes->get('cart', 'Customer\CartController::view');
    $routes->post('cart/add', 'Customer\CartController::add');
    $routes->post('cart/update', 'Customer\CartController::update');
    $routes->get('cart/remove/(:num)', 'Customer\CartController::remove/$1');

    $routes->get('checkout', 'Customer\CheckoutController::index');
    $routes->post('checkout/apply-coupon', 'Customer\CheckoutController::applyCoupon');
    $routes->post('checkout/place-order', 'Customer\CheckoutController::placeOrder');
    $routes->get('checkout/pay', 'Customer\PaymentController::show');
    $routes->post('checkout/payment/verify', 'Customer\PaymentController::verify');

    $routes->get('orders', 'Customer\OrderController::myOrders');
    $routes->get('order/track/(:segment)', 'Customer\OrderController::track/$1');
    $routes->post('review/store', 'Customer\ReviewController::store');
    $routes->post('restaurants/(:num)/like', 'Customer\RestaurantLikeController::toggle/$1');
    $routes->get('wallet', 'Customer\WalletController::index');
    $routes->get('coupons', 'Customer\WalletController::coupons');

    $routes->get('profile', 'Customer\ProfileController::index');
    $routes->post('profile/update', 'Customer\ProfileController::updateProfile');
    $routes->post('profile/address/add', 'Customer\ProfileController::addAddress');
    $routes->get('profile/address/default/(:num)', 'Customer\ProfileController::setDefaultAddress/$1');
    $routes->get('profile/address/delete/(:num)', 'Customer\ProfileController::deleteAddress/$1');

    $routes->get('chat/firebase-token', 'Customer\ChatController::firebaseToken');
});

// ==================== MOBILE APP REST API (token-based) ====================
$routes->group('api', static function ($routes) {
    // Public — no token yet at this point, so these stay outside apiAuth
    $routes->post('customer/register', 'Api\CustomerAuthApiController::register');
    $routes->post('customer/login', 'Api\CustomerAuthApiController::login');
    $routes->post('customer/forgot-password', 'Api\CustomerAuthApiController::forgotPassword');
    $routes->post('customer/reset-password', 'Api\CustomerAuthApiController::resetPassword');

    $routes->get('customer/restaurants', 'Api\CustomerApiController::restaurants');
    $routes->get('customer/restaurants/(:num)', 'Api\CustomerApiController::restaurantMenu/$1');

    $routes->post('delivery/login', 'Api\DeliveryAuthApiController::login');
    $routes->post('delivery/register', 'Api\DeliveryAuthApiController::register');
    $routes->post('vendor/register', 'Api\VendorApiController::register');

    $routes->get('pages/about', 'Api\StaticContentApiController::about');
    $routes->get('pages/terms', 'Api\StaticContentApiController::terms');
    $routes->get('pages/privacy', 'Api\StaticContentApiController::privacy');
    $routes->get('pages/refund-policy', 'Api\StaticContentApiController::refundPolicy');
    $routes->get('pages/shipping-policy', 'Api\StaticContentApiController::shippingPolicy');

    // Everything below needs a valid bearer token. This is a route-level
    // backstop (see ApiAuthFilter) on top of the existing per-method
    // authCustomer()/authPartner() calls in each controller — previously
    // this whole group had no filter, so a method that forgot that call
    // was silently unauthenticated.
    $routes->group('', ['filter' => 'apiAuth'], static function ($routes) {
        $routes->post('customer/logout', 'Api\CustomerAuthApiController::logout');

        $routes->get('customer/home', 'Api\CustomerApiController::home');
        $routes->get('customer/notifications', 'Api\CustomerApiController::notifications');
        $routes->get('customer/coupons', 'Api\CustomerApiController::coupons');
        $routes->post('customer/restaurants/(:num)/like', 'Api\CustomerApiController::toggleLike/$1');

        $routes->get('customer/cart', 'Api\CartApiController::view');
        $routes->post('customer/cart/add', 'Api\CartApiController::add');
        $routes->post('customer/cart/update', 'Api\CartApiController::update');

        $routes->post('customer/checkout/apply-coupon', 'Api\CheckoutApiController::applyCoupon');
        $routes->post('customer/checkout/place-order', 'Api\CheckoutApiController::placeOrder');

        $routes->get('customer/orders', 'Api\OrderApiController::myOrders');
        $routes->get('customer/orders/track/(:segment)', 'Api\OrderApiController::track/$1');

        $routes->get('customer/profile', 'Api\ProfileApiController::view');
        $routes->post('customer/profile/update', 'Api\ProfileApiController::update');
        $routes->post('customer/profile/address/add', 'Api\ProfileApiController::addAddress');
        $routes->post('customer/profile/address/default/(:num)', 'Api\ProfileApiController::setDefaultAddress/$1');
        $routes->post('customer/profile/address/delete/(:num)', 'Api\ProfileApiController::deleteAddress/$1');
        $routes->get('customer/wallet', 'Api\ProfileApiController::wallet');
        $routes->post('customer/device-token', 'Api\ProfileApiController::registerDeviceToken');

        $routes->get('customer/chat/firebase-token', 'Api\ChatApiController::firebaseToken');

        $routes->post('delivery/logout', 'Api\DeliveryAuthApiController::logout');
        $routes->get('delivery/dashboard', 'Api\DeliveryApiController::dashboard');
        $routes->get('delivery/orders/(:num)', 'Api\DeliveryApiController::orderDetails/$1');
        $routes->post('delivery/orders/(:num)/accept', 'Api\DeliveryApiController::acceptOrder/$1');
        $routes->post('delivery/orders/(:num)/reject', 'Api\DeliveryApiController::rejectOrder/$1');
        $routes->post('delivery/orders/(:num)/update-status', 'Api\DeliveryApiController::updateStatus/$1');
        $routes->post('delivery/update-location', 'Api\DeliveryApiController::updateLocation');
    });
});

// Live tracking JSON API (polled by the tracking page)
$routes->get('api/track/(:segment)', 'Api\TrackingApiController::status/$1');

// ==================== DELIVERY PARTNER ====================
$routes->get('delivery/login', 'Delivery\AuthController::showLogin');
$routes->post('delivery/login', 'Delivery\AuthController::login');
$routes->get('delivery/register', 'Delivery\RegisterController::show');
$routes->post('delivery/register', 'Delivery\RegisterController::store');
$routes->get('delivery/logout', 'Delivery\AuthController::logout');

$routes->group('delivery', ['filter' => 'deliveryAuth'], static function ($routes) {
    $routes->get('dashboard', 'Delivery\DashboardController::index');
    $routes->get('orders/(:num)', 'Delivery\DashboardController::viewOrder/$1');
    $routes->post('orders/(:num)/accept', 'Delivery\DashboardController::acceptOrder/$1');
    $routes->post('orders/(:num)/reject', 'Delivery\DashboardController::rejectOrder/$1');
    $routes->post('orders/(:num)/update-status', 'Delivery\DashboardController::updateStatus/$1');
    $routes->post('update-location', 'Delivery\DashboardController::updateLocation');
});

// ==================== ADMIN / RESTAURANT PANEL ====================
$routes->get('admin/login', 'Admin\AuthController::showLogin');
$routes->post('admin/login', 'Admin\AuthController::login');

$routes->get('restaurant/register', 'Admin\RestaurantRegisterController::show');
$routes->post('restaurant/register', 'Admin\RestaurantRegisterController::store');

$routes->get('about', 'Customer\PageController::about');
$routes->get('terms', 'Customer\PageController::terms');
$routes->get('privacy', 'Customer\PageController::privacy');
$routes->get('refund-policy', 'Customer\PageController::refundPolicy');
$routes->get('shipping-policy', 'Customer\PageController::shippingPolicy');

$routes->get('language', 'Customer\LanguageController::show');
$routes->get('lang/(:segment)', 'Customer\LanguageController::switch/$1');
$routes->get('admin/logout', 'Admin\AuthController::logout');

$routes->group('admin', ['filter' => 'adminAuth'], static function ($routes) {
    $routes->get('dashboard', 'Admin\DashboardController::index');
    $routes->get('reports', 'Admin\ReportController::index');
    $routes->get('chat', 'Admin\ChatController::index');
    $routes->get('chat/(:num)', 'Admin\ChatController::conversation/$1');
    $routes->get('chat/firebase-token', 'Admin\ChatController::firebaseToken');
    $routes->get('chat/diagnose', 'Admin\ChatController::diagnose');

    $routes->get('restaurants', 'Admin\RestaurantController::index');
    $routes->get('restaurants/create', 'Admin\RestaurantController::create');
    $routes->post('restaurants/store', 'Admin\RestaurantController::store');
    $routes->get('restaurants/edit/(:num)', 'Admin\RestaurantController::edit/$1');
    $routes->post('restaurants/update/(:num)', 'Admin\RestaurantController::update/$1');
    $routes->post('restaurants/delete/(:num)', 'Admin\RestaurantController::delete/$1');

    $routes->get('menu-items', 'Admin\MenuItemController::index');
    $routes->get('menu-items/create', 'Admin\MenuItemController::create');
    $routes->post('menu-items/store', 'Admin\MenuItemController::store');
    $routes->get('menu-items/edit/(:num)', 'Admin\MenuItemController::edit/$1');
    $routes->post('menu-items/update/(:num)', 'Admin\MenuItemController::update/$1');
    $routes->post('menu-items/delete/(:num)', 'Admin\MenuItemController::delete/$1');
    $routes->post('menu-items/toggle-availability/(:num)', 'Admin\MenuItemController::toggleAvailability/$1');

    $routes->get('categories', 'Admin\CategoryController::index');
    $routes->post('categories/store', 'Admin\CategoryController::store');
    $routes->get('categories/edit/(:num)', 'Admin\CategoryController::edit/$1');
    $routes->post('categories/update/(:num)', 'Admin\CategoryController::update/$1');
    $routes->post('categories/delete/(:num)', 'Admin\CategoryController::delete/$1');

    $routes->get('sub-categories', 'Admin\SubCategoryController::index');
    $routes->post('sub-categories/store', 'Admin\SubCategoryController::store');
    $routes->post('sub-categories/delete/(:num)', 'Admin\SubCategoryController::delete/$1');

    $routes->get('coupons', 'Admin\CouponController::index');
    $routes->post('coupons/store', 'Admin\CouponController::store');
    $routes->post('coupons/toggle/(:num)', 'Admin\CouponController::toggle/$1');
    $routes->post('coupons/delete/(:num)', 'Admin\CouponController::delete/$1');

    $routes->get('notifications', 'Admin\NotificationController::index');
    $routes->post('notifications/send', 'Admin\NotificationController::send');
    $routes->get('notifications/diagnose', 'Admin\NotificationController::diagnose');
    $routes->get('password-reset-diagnose', 'Admin\PasswordResetDiagnoseController::index');

    $routes->get('orders', 'Admin\OrderController::index');
    $routes->get('orders/(:num)', 'Admin\OrderController::view/$1');
    $routes->post('orders/(:num)/update-status', 'Admin\OrderController::updateStatus/$1');

    $routes->get('delivery-partners', 'Admin\DeliveryPartnerController::index');
    $routes->post('delivery-partners/store', 'Admin\DeliveryPartnerController::store');
    $routes->get('delivery-partners/edit/(:num)', 'Admin\DeliveryPartnerController::edit/$1');
    $routes->post('delivery-partners/update/(:num)', 'Admin\DeliveryPartnerController::update/$1');
    $routes->post('delivery-partners/delete/(:num)', 'Admin\DeliveryPartnerController::delete/$1');

    $routes->get('managers', 'Admin\ManagerController::index');
    $routes->post('managers/store', 'Admin\ManagerController::store');
    $routes->post('managers/delete/(:num)', 'Admin\ManagerController::delete/$1');

    $routes->get('users', 'Admin\UserController::index');
    $routes->get('users/(:num)', 'Admin\UserController::view/$1');
    $routes->get('users/edit/(:num)', 'Admin\UserController::edit/$1');
    $routes->post('users/update/(:num)', 'Admin\UserController::update/$1');
    $routes->post('users/delete/(:num)', 'Admin\UserController::delete/$1');
});
