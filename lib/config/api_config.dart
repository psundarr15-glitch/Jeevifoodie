/// Backend API base URL — points at the live deployed backend.
class ApiConfig {
  static const String baseUrl = 'https://food.tvkomalur.xyz/api';

  // Individual endpoints, matching app/Config/Routes.php on the backend.
  // Login is phone + OTP only now (see PhoneAuthApiController) - the old
  // email/password register/login/forgot-password/reset-password
  // endpoints are no longer called from the app.
  static const String logout = '$baseUrl/customer/logout';
  static const String sendOtp = '$baseUrl/customer/auth/send-otp';
  static const String verifyOtp = '$baseUrl/customer/auth/verify-otp';

  static const String home = '$baseUrl/customer/home';
  static const String restaurants = '$baseUrl/customer/restaurants';
  static String restaurantMenu(int id) => '$baseUrl/customer/restaurants/$id';
  static String toggleLike(int id) => '$baseUrl/customer/restaurants/$id/like';
  static String toggleItemLike(int id) => '$baseUrl/customer/menu-items/$id/like';
  static String search(String q) => '$baseUrl/customer/search?q=${Uri.encodeQueryComponent(q)}';

  static const String cartView = '$baseUrl/customer/cart';
  static const String cartAdd = '$baseUrl/customer/cart/add';
  static const String cartUpdate = '$baseUrl/customer/cart/update';

  static const String applyCoupon = '$baseUrl/customer/checkout/apply-coupon';
  static const String placeOrder = '$baseUrl/customer/checkout/place-order';
  static const String createCardPayment = '$baseUrl/customer/checkout/card/create';
  static const String verifyCardPayment = '$baseUrl/customer/checkout/card/verify';

  static const String myOrders = '$baseUrl/customer/orders';
  static String trackOrder(String orderCode) => '$baseUrl/customer/orders/track/$orderCode';
  static const String reviewStore = '$baseUrl/customer/review/store';

  static const String profileView = '$baseUrl/customer/profile';
  static const String profileUpdate = '$baseUrl/customer/profile/update';
  static const String addAddress = '$baseUrl/customer/profile/address/add';
  static String setDefaultAddress(int id) => '$baseUrl/customer/profile/address/default/$id';
  static String deleteAddress(int id) => '$baseUrl/customer/profile/address/delete/$id';
  static const String wallet = '$baseUrl/customer/wallet';
  static const String deviceToken = '$baseUrl/customer/device-token';
  static const String unregisterDeviceToken = '$baseUrl/customer/device-token/unregister';
  static const String changePassword = '$baseUrl/customer/change-password';
  static const String deleteAccount = '$baseUrl/customer/delete-account';
  static const String notifications = '$baseUrl/customer/notifications';
  static const String coupons = '$baseUrl/customer/coupons';

  // Live chat is now real-time via Firestore — this endpoint just mints a
  // Firebase custom auth token + tells the app which threadId to use.
  // No restaurantId means the general app-admin thread; a restaurantId
  // means that restaurant's manager thread (the backend only honors a
  // restaurantId the customer actually has an order from).
  static String chatFirebaseToken([int? restaurantId]) => restaurantId != null
      ? '$baseUrl/customer/chat/firebase-token?restaurant_id=$restaurantId'
      : '$baseUrl/customer/chat/firebase-token';

  // Chat image attachments upload here (saved on our own server, not
  // Firebase Storage) — only the returned URL goes into the Firestore
  // message.
  static const String chatUploadImage = '$baseUrl/customer/chat/upload-image';

  // Rendered natively in-app (see StaticPageScreen) rather than opening
  // the web frontend, which is not shipped alongside the app - the API
  // is the only thing this app ever depends on.
  static const String pageAbout = '$baseUrl/pages/about';
  static const String pageTerms = '$baseUrl/pages/terms';
  static const String pagePrivacy = '$baseUrl/pages/privacy';
  static const String pageRefundPolicy = '$baseUrl/pages/refund-policy';
  static const String pageShippingPolicy = '$baseUrl/pages/shipping-policy';
  static const String pageSupport = '$baseUrl/pages/support';

  static const String deliveryPartnerRegister = '$baseUrl/delivery/register';
  static const String vendorRegister = '$baseUrl/vendor/register';
}
