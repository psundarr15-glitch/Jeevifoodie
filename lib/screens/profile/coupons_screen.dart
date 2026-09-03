import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = CustomerService.coupons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.couponsTitle)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorLabel(snap.error.toString())));
          }
          final coupons = snap.data!;
          if (coupons.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noActiveCoupons));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, i) {
              final c = coupons[i];
              final isPercent = c['discount_type'] == 'percent';
              final label = isPercent ? AppLocalizations.of(context)!.flatOff(c['discount_value'].toString()) : AppLocalizations.of(context)!.rupeesOff(c['discount_value'].toString());
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold, width: 1.2, style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, color: AppTheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['code']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(label, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          if ((c['description'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(c['description'].toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                          ],
                          if (c['min_order_value'] != null) ...[
                            const SizedBox(height: 4),
                            Text(AppLocalizations.of(context)!.minOrder(c['min_order_value'].toString()), style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
