import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  static Future<void> logout() async {
    try {
      await ApiClient.post(ApiConfig.logout);
    } catch (_) {
      // ignore network errors on logout, still clear local token
    }
    await ApiClient.setToken(null);
  }

  static Future<bool> isLoggedIn() async => (await ApiClient.getToken()) != null;

  /// Phone + OTP login/register (via Twilio). Pass [name] only from the
  /// Register screen - its presence is what tells the backend this is a
  /// registration, not a login (see PhoneAuthApiController::sendOtp()).
  static Future<void> sendOtp({required String phone, String? name}) async {
    await ApiClient.post(ApiConfig.sendOtp, {
      'phone': phone,
      if (name != null && name.isNotEmpty) 'name': name,
    });
  }

  /// Returns the logged-in user plus whether this was their first-ever
  /// login (no name on file yet) - CompleteProfileScreen uses that flag.
  static Future<(Map<String, dynamic>, bool)> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final res = await ApiClient.post(ApiConfig.verifyOtp, {'phone': phone, 'otp': otp});
    await ApiClient.setToken(res['token']?.toString());
    return (res['user'] as Map<String, dynamic>, res['is_new_user'] == true);
  }
}
