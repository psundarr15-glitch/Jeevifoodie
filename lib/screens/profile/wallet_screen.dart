import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<(double, List<Map<String, dynamic>>)> _future;

  @override
  void initState() {
    super.initState();
    _future = ProfileService.wallet();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.myWalletTitle)),
      body: FutureBuilder<(double, List<Map<String, dynamic>>)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(t.errorLabel(snap.error.toString())));
          }
          final (balance, transactions) = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.walletBalanceLabel, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                        const Icon(Icons.account_balance_wallet, color: AppTheme.gold, size: 32),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(t.recentTransactions, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(t.noTransactionsYet, style: TextStyle(color: Colors.grey.shade600))),
                )
              else
                for (final tx in transactions) _TransactionTile(tx: tx),
            ],
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx['type'] == 'credit';
    final amount = double.tryParse(tx['amount']?.toString() ?? '') ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
        child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red, size: 18),
      ),
      title: Text(tx['description']?.toString() ?? (isCredit ? AppLocalizations.of(context)!.walletCredit : AppLocalizations.of(context)!.walletDebit)),
      subtitle: Text((tx['created_at']?.toString() ?? '').split('.').first),
      trailing: Text(
        '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
        style: TextStyle(color: isCredit ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold),
      ),
    );
  }
}
