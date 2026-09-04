import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import 'otp_verify_screen.dart';
import '../profile/static_page_screen.dart';

/// Register only - a phone that's already registered (has a name on
/// file) is rejected here (see PhoneAuthApiController::sendOtp()), so
/// nobody can silently take over an existing account by "signing up"
/// with the same number again.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _agreedToTerms = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _register() async {
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
      await AuthService.sendOtp(phone: phone, name: _name.text.trim());
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
                Text(t.registerTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: '${t.fullName} *', prefixIcon: const Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.trim().length < 2) ? t.validatorRequired : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: '${t.phoneLabel} *',
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
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t.registerTitle),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${t.alreadyHaveAccount} '),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(t.signIn, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
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
