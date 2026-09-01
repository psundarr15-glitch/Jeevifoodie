import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await ApiClient.post(ApiConfig.register, {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    await ApiClient.setToken(res['token']?.toString());
    return res['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post(ApiConfig.login, {
      'email': email,
      'password': password,
    });
    await ApiClient.setToken(res['token']?.toString());
    return res['user'] as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post(ApiConfig.logout);
    } catch (_) {
      // ignore network errors on logout, still clear local token
    }
    await ApiClient.setToken(null);
  }

  static Future<bool> isLoggedIn() async => (await ApiClient.getToken()) != null;

  /// Returns true if the reset email actually sent (or if there simply
  /// wasn't an account to send to - the backend can't distinguish that
  /// case in its response, on purpose). Returns false only when we know
  /// for certain a real send attempt failed, so the screen can show a
  /// clear "couldn't send" message instead of silently going nowhere.
  static Future<bool> forgotPassword({required String email}) async {
    final res = await ApiClient.post(ApiConfig.forgotPassword, {'email': email});
    return res['email_sent'] != false;
  }

  static Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await ApiClient.post(ApiConfig.resetPassword, {
      'email': email,
      'otp': otp,
      'password': newPassword,
    });
  }
}
