import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../state/theme_provider.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

// Kept in one place and bumped by hand alongside pubspec.yaml's `version:`
// — this app has no backend "app version" endpoint, so there is nothing
// dynamic to read at runtime.
const String kAppVersion = '1.0.0';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<_AccountSummary> _future = _load();

  Future<_AccountSummary> _load() async {
    final profile = await ProfileService.view();
    final orders = await OrderService.myOrders();
    return _AccountSummary(user: profile.user, orderCount: orders.length);
  }

  String _formatJoined(dynamic createdAt) {
    if (createdAt == null) return '';
    final d = DateTime.tryParse(createdAt.toString());
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Joined ${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}, ${d.year}';
  }

  Future<void> _confirmDeleteAccount(AppLocalizations t) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.deleteAccountWarning),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: t.password, border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.deleteAccount, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await ProfileService.deleteAccount(password: passwordController.text);
      await AuthService.logout();
      if (!mounted) return;
      context.read<AppState>().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(t.profile)),
      body: FutureBuilder<_AccountSummary>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final summary = snap.data!;
          final user = summary.user;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                color: AppTheme.primary.withOpacity(0.12),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 34, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 38, color: Colors.grey)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name']?.toString() ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_formatJoined(user['created_at']), style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                      icon: const Icon(Icons.edit, size: 18, color: AppTheme.primary),
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            name: user['name']?.toString() ?? '',
                            phone: user['phone']?.toString() ?? '',
                            email: user['email']?.toString() ?? '',
                          ),
                        ));
                        setState(() => _future = _load());
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _StatCard(icon: Icons.shopping_bag_outlined, value: '${summary.orderCount}', label: t.totalOrders)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(icon: Icons.account_balance_wallet_outlined, value: '₹${user['wallet_balance'] ?? 0}', label: t.walletBalance)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      label: t.darkMode,
                      trailing: Switch(
                        value: themeProvider.darkMode,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => themeProvider.setDarkMode(v),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: t.notifications,
                      trailing: Switch(
                        value: context.watch<AppState>().notificationsEnabled,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => context.read<AppState>().setNotificationsEnabled(v),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      label: t.changePassword,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                    ),
                    _SettingsTile(
                      icon: Icons.person_remove_outlined,
                      label: t.deleteAccount,
                      iconColor: Colors.red,
                      labelColor: Colors.red,
                      onTap: () => _confirmDeleteAccount(t),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text('${t.versionLabel}  $kAppVersion', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountSummary {
  final Map<String, dynamic> user;
  final int orderCount;
  _AccountSummary({required this.user, required this.orderCount});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;
  const _SettingsTile({required this.icon, required this.label, this.trailing, this.onTap, this.iconColor, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: TextStyle(color: labelColor)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }
}
