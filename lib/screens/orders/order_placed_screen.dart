import 'package:flutter/material.dart';
import '../../theme.dart';
import 'order_track_screen.dart';
import '../../widgets/root_shell.dart';
import '../../l10n/app_localizations.dart';

class OrderPlacedScreen extends StatelessWidget {
  final String orderCode;
  const OrderPlacedScreen({super.key, required this.orderCode});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppTheme.success, size: 72),
              ),
              const SizedBox(height: 28),
              Text(t.orderPlacedSuccessfully, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                t.orderPlacedBeingConfirmed,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Text(t.orderId, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text('#$orderCode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => OrderTrackScreen(orderCode: orderCode)),
                  ),
                  child: Text(t.trackOrder),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RootShell()),
                  (route) => false,
                ),
                child: Text(t.backToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
