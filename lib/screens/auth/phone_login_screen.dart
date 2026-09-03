import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import 'otp_verify_screen.dart';

/// Entry point for login now - phone number in, OTP out (via Twilio SMS,
/// see PhoneAuthApiController::sendOtp on the backend). A phone with no
/// existing account is silently signed up server-side; there's no
/// separate registration step or password to set.
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final phone = _phone.text.trim();
    try {
      await AuthService.sendOtp(phone: phone);
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 64),
                Icon(Icons.storefront_rounded, color: AppTheme.primary, size: 56),
                const SizedBox(height: 20),
                Text(t.welcomeBack, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(t.enterPhoneToContinue, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: t.mobileNumber,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('🇮🇳 +91', style: TextStyle(fontSize: 15)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                    counterText: '',
                  ),
                  validator: (v) => (v == null || !RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) ? t.enterValidMobileNumber : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t.sendOtp),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    t.otpTermsNotice,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
