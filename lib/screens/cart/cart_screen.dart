import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../models/cart_item.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/quantity_stepper.dart';
import '../checkout/checkout_screen.dart';
import '../../l10n/app_localizations.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<CartSnapshot> _future;
  final Set<int> _busyItems = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = CartService.view();
  }

  Future<void> _changeQty(CartItem item, int delta) async {
    final newQty = item.quantity + delta;
    setState(() => _busyItems.add(item.id));
    try {
      await CartService.updateQuantity(cartItemId: item.id, quantity: newQty);
      if (!mounted) return;
      setState(_load);
      context.read<AppState>().refreshCartCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorLabel(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busyItems.remove(item.id));
    }
  }

  double _deliveryFee(double subtotal) => subtotal >= 199 ? 0 : 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.myCart)),
      body: FutureBuilder<CartSnapshot>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorLabel(snap.error.toString())));
          }
          final cart = snap.data!;
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.yourCartIsEmpty, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final deliveryFee = _deliveryFee(cart.subtotal);
          final total = cart.subtotal + deliveryFee;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final item in cart.items)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('₹${item.price.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              _busyItems.contains(item.id)
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : QuantityStepper(
                                      quantity: item.quantity,
                                      onIncrease: () => _changeQty(item, 1),
                                      onDecrease: () => _changeQty(item, -1),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _summaryRow(AppLocalizations.of(context)!.subtotal, cart.subtotal),
                            const SizedBox(height: 8),
                            _summaryRow(AppLocalizations.of(context)!.deliveryFee, deliveryFee),
                            if (deliveryFee == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(AppLocalizations.of(context)!.freeDeliveryAbove199, style: const TextStyle(color: AppTheme.success, fontSize: 12)),
                              ),
                            const Divider(height: 24),
                            _summaryRow(AppLocalizations.of(context)!.total, total, bold: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CheckoutScreen(subtotal: cart.subtotal)),
                      ).then((_) => setState(_load)),
                      child: Text(AppLocalizations.of(context)!.proceedToCheckout(total.toStringAsFixed(0)), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 17 : 14);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('₹${value.toStringAsFixed(0)}', style: style),
      ],
    );
  }
}
