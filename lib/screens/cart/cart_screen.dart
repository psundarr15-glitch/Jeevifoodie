import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/quantity_stepper.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<CartSnapshot> _future;
  final Set<int> _busy = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = CartService.view();
  }

  Future<void> _qty(CartItem item, int delta) async {
    final nextQuantity = item.quantity + delta;

    setState(() {
      _busy.add(item.id);
    });

    try {
      await CartService.updateQuantity(
        cartItemId: item.id,
        quantity: nextQuantity,
      );

      if (!mounted) return;

      setState(_load);
      context.read<AppState>().refreshCartCount();
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorLabel(e.toString()))),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy.remove(item.id);
      });
    }
  }

  double _fee(double subtotal) => subtotal >= 199 ? 0 : 30;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: Text(
          t.myCart,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<CartSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(t.errorLabel(snapshot.error.toString())),
            );
          }

          final cart = snapshot.data!;

          if (cart.items.isEmpty) {
            return const _EmptyCart();
          }

          final fee = _fee(cart.subtotal);
          final total = cart.subtotal + fee;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                  children: [
                    _CartHeader(itemCount: cart.items.length),
                    const SizedBox(height: 14),
                    ...cart.items.map((item) => _CartItemCard(
                          item: item,
                          busy: _busy.contains(item.id),
                          onIncrease: () => _qty(item, 1),
                          onDecrease: () => _qty(item, -1),
                        )),
                    const SizedBox(height: 2),
                    _SummaryCard(
                      subtotalLabel: t.subtotal,
                      deliveryLabel: t.deliveryFee,
                      totalLabel: t.total,
                      subtotal: cart.subtotal,
                      deliveryFee: fee,
                      total: total,
                      freeDeliveryText: t.freeDeliveryAbove199,
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  subtotal: cart.subtotal,
                                ),
                              ),
                            )
                            .then((_) {
                          if (!mounted) return;
                          setState(_load);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        t.proceedToCheckout(total.toStringAsFixed(0)),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
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
}

class _CartHeader extends StatelessWidget {
  final int itemCount;

  const _CartHeader({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount items in your bag',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Review your items before checkout',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool busy;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _CartItemCard({
    required this.item,
    required this.busy,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.isVeg ? Colors.green : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              item.isVeg ? Icons.eco_rounded : Icons.restaurant_rounded,
              color: accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            QuantityStepper(
              quantity: item.quantity,
              compact: true,
              onIncrease: onIncrease,
              onDecrease: onDecrease,
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String subtotalLabel;
  final String deliveryLabel;
  final String totalLabel;
  final String freeDeliveryText;
  final double subtotal;
  final double deliveryFee;
  final double total;

  const _SummaryCard({
    required this.subtotalLabel,
    required this.deliveryLabel,
    required this.totalLabel,
    required this.freeDeliveryText,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _row(subtotalLabel, subtotal),
          const SizedBox(height: 10),
          _row(deliveryLabel, deliveryFee),
          if (deliveryFee == 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  freeDeliveryText,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          _row(totalLabel, total, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
            fontSize: bold ? 17 : 14,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your favourite food and come back here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
