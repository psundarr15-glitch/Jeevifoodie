import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final methods = [
      (Icons.payments_outlined, t.cashOnDelivery, t.codDescription),
      (Icons.credit_card, t.onlinePayment, t.onlinePaymentDescription),
      (Icons.account_balance_wallet_outlined, t.walletLabel, t.walletDescription),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.paymentMethodsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final m in methods)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primary.withOpacity(0.1), child: Icon(m.$1, color: AppTheme.primary)),
                title: Text(m.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(m.$3),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            t.chooseOneAtCheckout,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
