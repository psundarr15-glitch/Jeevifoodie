import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import 'otp_verify_screen.dart';
import 'register_screen.dart';
import '../profile/static_page_screen.dart';

/// Login only - a phone with no registered account is rejected here (see
/// PhoneAuthApiController::sendOtp()), matching the "Login" vs "Register"
/// split in the reference design rather than silently auto-signing-up.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _rememberMe = true;
  bool _agreedToTerms = false;
  bool _loading = false;
  String? _error;

  static const _rememberMeKey = 'remember_me';

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context)!;
    if (!_agreedToTerms) {
      setState(() => _error = t.pleaseAgreeToTerms);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final phone = _phone.text.trim();
    try {
      await AuthService.sendOtp(phone: phone);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, _rememberMe);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OtpVerifyScreen(phone: phone)));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Image.asset('assets/icon/icon.png', height: 96, errorBuilder: (_, __, ___) => Icon(Icons.storefront_rounded, color: AppTheme.primary, size: 72)),
                ),
                const SizedBox(height: 32),
                Text(t.loginTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: t.phoneLabel,
                    counterText: '',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('🇮🇳 +91', style: TextStyle(fontSize: 15)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  ),
                  validator: (v) => (v == null || !RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) ? t.enterValidMobileNumber : null,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.rememberMe),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('${t.agreeWithThe} '),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StaticPageScreen(url: ApiConfig.pageTerms))),
                            child: Text(t.termsAndConditions, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t.loginTitle),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text(t.registerTitle),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
