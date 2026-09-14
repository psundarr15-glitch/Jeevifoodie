import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../theme.dart';
import 'order_track_screen.dart';
import '../../l10n/app_localizations.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late Future<List<OrderSummary>> _future;
  late final TabController _tabs = TabController(length: 4, vsync: this);
  static const keys = ['All', 'Ongoing', 'Completed', 'Cancelled'];

  @override void initState() { super.initState(); _future = OrderService.myOrders(); }
  Future<void> _refresh() async { setState(() => _future = OrderService.myOrders()); await _future; }
  @override void dispose() { _tabs.dispose(); super.dispose(); }

  String _label(String k) {
    final t = AppLocalizations.of(context)!;
    switch (k) { case 'Ongoing': return t.tabOngoing; case 'Completed': return t.tabCompleted; case 'Cancelled': return t.tabCancelled; default: return t.tabAll; }
  }
  bool _match(String s, String k) {
    switch (k) { case 'Ongoing': return s != 'delivered' && s != 'cancelled'; case 'Completed': return s == 'delivered'; case 'Cancelled': return s == 'cancelled'; default: return true; }
  }
  Color _color(String s) { if (s == 'delivered') return AppTheme.success; if (s == 'cancelled') return const Color(0xFFE5484D); return AppTheme.gold; }

  @override
  Widget build(BuildContext c) {
    final t = AppLocalizations.of(c)!;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(c),
      appBar: AppBar(
        title: Text(t.myOrdersTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabs, isScrollable: true, dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              labelColor: Colors.white, unselectedLabelColor: AppTheme.textSecondary(c),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              indicator: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.shadowColored(AppTheme.primary, opacity: 0.3, blur: 12, offset: const Offset(0, 4)),
              ),
              tabs: keys.map((k) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Tab(text: _label(k)))).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        child: FutureBuilder<List<OrderSummary>>(
          future: _future,
          builder: (c, s) {
            if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (s.hasError) return ListView(children: const [SizedBox(height: 100), Center(child: Text('Unable to load orders'))]);
            final orders = s.data ?? [];
            return TabBarView(
              controller: _tabs,
              children: keys.map((k) {
                final list = orders.where((o) => _match(o.status, k)).toList();
                if (list.isEmpty) {
                  return ListView(children: [
                    const SizedBox(height: 110),
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(child: Text(t.noOrdersHereYet, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary(c)))),
                  ]);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                  itemCount: list.length,
                  itemBuilder: (c, i) => _OrderCard(
                    order: list[i], color: _color(list[i].status),
                    onTap: () => Navigator.of(c).push(MaterialPageRoute(builder: (_) => OrderTrackScreen(orderCode: list[i].orderCode))),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderSummary order;
  final Color color;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.color, required this.onTap});

  @override
  Widget build(BuildContext c) {
    final status = order.status.replaceAll('_', ' ');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface(c),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowSoft(c),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary.withOpacity(0.14), AppTheme.primary.withOpacity(0.06)],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: (order.imageUrl?.trim().isNotEmpty ?? false)
                        ? Image.network(
                            order.imageUrl!.trim(),
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.restaurant_rounded,
                              color: AppTheme.primary,
                              size: 30,
                            ),
                          )
                        : const Icon(
                            Icons.restaurant_rounded,
                            color: AppTheme.primary,
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('#${order.orderCode}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary(c))),
                    const SizedBox(height: 5),
                    Text('₹${order.total.toStringAsFixed(0)}  •  ${order.paymentMethod.toUpperCase()}', style: TextStyle(color: AppTheme.textSecondary(c), fontSize: 12.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: .3)),
                    ),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, size: 28, color: AppTheme.textSecondary(c)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
