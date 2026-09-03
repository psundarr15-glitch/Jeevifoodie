import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../auth/phone_login_screen.dart';
import '../orders/orders_screen.dart';
import 'addresses_screen.dart';
import 'coupons_screen.dart';
import 'delivery_partner_signup_screen.dart';
import 'account_screen.dart';
import 'help_support_screen.dart';
import 'language_screen.dart';
import 'payment_methods_screen.dart';
import 'static_page_screen.dart';
import 'vendor_signup_screen.dart';
import 'wallet_screen.dart';
import '../../l10n/app_localizations.dart';
import '../chat/chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = ProfileService.view();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.read<AppState>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
      (route) => false,
    );
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  String _joinedDate(dynamic raw) {
    final dt = DateTime.tryParse(raw?.toString() ?? '');
    if (dt == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<ProfileData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorLabel(snap.error.toString())));
          }
          final user = snap.data!.user;
          final name = user['name']?.toString() ?? '';
          final walletBalance = double.tryParse(user['wallet_balance']?.toString() ?? '0') ?? 0;
          final t = AppLocalizations.of(context)!;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(border: Border.all(color: Colors.white70, width: 1.5), shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.gold,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          if (user['created_at'] != null)
                            Text(_joinedDate(user['created_at']), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(t.generalSection),
              _SectionCard(children: [
                _MenuTile(
                  icon: Icons.person_outline,
                  label: t.profileLabel,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
                    setState(() => _future = ProfileService.view());
                  },
                ),
                _MenuTile(
                  icon: Icons.map_outlined,
                  label: t.myAddress,
                  onTap: () => _push(const AddressesScreen()),
                ),
                _MenuTile(
                  icon: Icons.translate,
                  label: t.language,
                  onTap: () => showLanguagePicker(context),
                ),
              ]),
              _SectionLabel(t.promotionalActivitySection),
              _SectionCard(children: [
                _MenuTile(
                  icon: Icons.confirmation_number_outlined,
                  label: t.coupon,
                  onTap: () => _push(const CouponsScreen()),
                ),
                _MenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: t.myWallet,
                  onTap: () => _push(const WalletScreen()),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text('₹${walletBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ),
              ]),
              _SectionLabel(t.earningsSection),
              _SectionCard(children: [
                _MenuTile(
                  icon: Icons.two_wheeler_outlined,
                  label: t.joinAsDeliveryMan,
                  onTap: () => _push(const DeliveryPartnerSignupScreen()),
                ),
                _MenuTile(
                  icon: Icons.storefront_outlined,
                  label: t.openVendor,
                  onTap: () => _push(const VendorSignupScreen()),
                ),
              ]),
              _SectionLabel(t.helpSupportSection),
              _SectionCard(children: [
                _MenuTile(
                  icon: Icons.chat_bubble_outline,
                  label: t.liveChat,
                  onTap: () => _push(const ChatScreen()),
                ),
                _MenuTile(
                  icon: Icons.headset_mic_outlined,
                  label: t.helpSupport,
                  onTap: () => _push(const HelpSupportScreen()),
                ),
                _MenuTile(
                  icon: Icons.info_outline,
                  label: t.aboutUs,
                  onTap: () => _push(const StaticPageScreen(url: ApiConfig.pageAbout)),
                ),
                _MenuTile(
                  icon: Icons.description_outlined,
                  label: t.termsConditions,
                  onTap: () => _push(const StaticPageScreen(url: ApiConfig.pageTerms)),
                ),
                _MenuTile(
                  icon: Icons.privacy_tip_outlined,
                  label: t.privacyPolicy,
                  onTap: () => _push(const StaticPageScreen(url: ApiConfig.pagePrivacy)),
                ),
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  label: t.refundPolicy,
                  onTap: () => _push(const StaticPageScreen(url: ApiConfig.pageRefundPolicy)),
                ),
                _MenuTile(
                  icon: Icons.local_shipping_outlined,
                  label: t.shippingPolicy,
                  onTap: () => _push(const StaticPageScreen(url: ApiConfig.pageShippingPolicy)),
                ),
              ]),
              _SectionLabel(t.ordersPaymentsSection),
              _SectionCard(children: [
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  label: t.myOrders,
                  onTap: () => _push(const OrdersScreen()),
                ),
                _MenuTile(
                  icon: Icons.credit_card_outlined,
                  label: t.paymentMethods,
                  onTap: () => _push(const PaymentMethodsScreen()),
                ),
              ]),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.power_settings_new, color: Colors.red),
                  label: Text(t.logout, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(text, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
