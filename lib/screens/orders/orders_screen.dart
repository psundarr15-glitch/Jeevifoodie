import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../theme.dart';
import 'order_track_screen.dart';
import '../search/search_screen.dart';
import '../../l10n/app_localizations.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late Future<List<OrderSummary>> _future;
  late final TabController _tabController = TabController(length: 4, vsync: this);
  static const _tabs = ['All', 'Ongoing', 'Completed', 'Cancelled'];

  String _tabLabel(String tab) {
    final t = AppLocalizations.of(context)!;
    switch (tab) {
      case 'Ongoing': return t.tabOngoing;
      case 'Completed': return t.tabCompleted;
      case 'Cancelled': return t.tabCancelled;
      default: return t.tabAll;
    }
  }

  @override
  void initState() {
    super.initState();
    _future = OrderService.myOrders();
  }

  Future<void> _refresh() async {
    setState(() => _future = OrderService.myOrders());
    await _future;
  }

  bool _matchesTab(String status, String tab) {
    switch (tab) {
      case 'Ongoing': return status != 'delivered' && status != 'cancelled';
      case 'Completed': return status == 'delivered';
      case 'Cancelled': return status == 'cancelled';
      default: return true;
    }
  }

  _StatusMeta _status(String value) {
    switch (value.toLowerCase()) {
      case 'delivered':
        return const _StatusMeta('Delivered', AppTheme.success, AppTheme.softGreen, Icons.check_circle_rounded);
      case 'cancelled':
        return const _StatusMeta('Cancelled', Color(0xFFE53935), Color(0xFFFFECEB), Icons.cancel_rounded);
      case 'out_for_delivery':
        return const _StatusMeta('Out for delivery', AppTheme.gold, AppTheme.softOrange, Icons.delivery_dining_rounded);
      case 'picked_up':
        return const _StatusMeta('Picked up', AppTheme.gold, AppTheme.softOrange, Icons.local_shipping_rounded);
      case 'preparing':
        return const _StatusMeta('Preparing', AppTheme.primary, AppTheme.softRed, Icons.soup_kitchen_rounded);
      case 'confirmed':
        return const _StatusMeta('Confirmed', AppTheme.primary, AppTheme.softRed, Icons.check_circle_outline_rounded);
      default:
        return const _StatusMeta('Order placed', AppTheme.primary, AppTheme.softRed, Icons.receipt_long_rounded);
    }
  }

  String _date(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Date unavailable';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
  }

  IconData _foodIcon(int index) {
    const icons = [Icons.ramen_dining_rounded, Icons.local_pizza_rounded, Icons.lunch_dining_rounded, Icons.icecream_rounded, Icons.breakfast_dining_rounded, Icons.local_cafe_rounded];
    return icons[index % icons.length];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CircleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.myOrdersTitle, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 2),
                        Text('Track your orders and stay updated', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  _CircleButton(icon: Icons.search_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())), soft: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFF0EFF0), borderRadius: BorderRadius.circular(28)),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(24)),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.muted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: _tabLabel('All')),
                    Tab(icon: const Icon(Icons.schedule_rounded, size: 18), text: _tabLabel('Ongoing')),
                    Tab(icon: const Icon(Icons.check_circle_outline_rounded, size: 18), text: _tabLabel('Completed')),
                    Tab(icon: const Icon(Icons.cancel_outlined, size: 18), text: _tabLabel('Cancelled')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppTheme.primary,
                child: FutureBuilder<List<OrderSummary>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                    if (snap.hasError) {
                      return ListView(children: [const SizedBox(height: 120), Center(child: Padding(padding: EdgeInsets.all(24), child: Text(t.errorLabel(snap.error.toString()))))]);
                    }
                    final orders = snap.data ?? <OrderSummary>[];
                    return TabBarView(
                      controller: _tabController,
                      children: _tabs.map((tab) {
                        final filtered = orders.where((o) => _matchesTab(o.status, tab)).toList();
                        if (filtered.isEmpty) {
                          return ListView(children: [const SizedBox(height: 120), Center(child: Padding(padding: EdgeInsets.all(24), child: Text(t.noOrdersHereYet))) ]);
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => _OrderCard(
                            order: filtered[i],
                            icon: _foodIcon(i),
                            meta: _status(filtered[i].status),
                            date: _date(filtered[i].placedAt),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderTrackScreen(orderCode: filtered[i].orderCode))),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderSummary order;
  final IconData icon;
  final _StatusMeta meta;
  final String date;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.icon, required this.meta, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.cardShadow),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(color: meta.soft, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, size: 38, color: meta.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${order.orderCode}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.ink)),
                      const SizedBox(height: 4),
                      Text('₹${order.total.toStringAsFixed(0)}  •  ${order.paymentMethod.toUpperCase()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                      const SizedBox(height: 7),
                      Row(children: [const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.muted), const SizedBox(width: 5), Expanded(child: Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.muted))) ]),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: meta.soft, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(meta.icon, size: 15, color: meta.color), const SizedBox(width: 5), Text(meta.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: meta.color))]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary(context), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool soft;
  const _CircleButton({required this.icon, required this.onTap, this.soft = false});
  @override
  Widget build(BuildContext context) => Material(
    color: soft ? AppTheme.softRed : AppTheme.surface(context),
    shape: const CircleBorder(),
    child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 24, color: AppTheme.ink))),
  );
}

class _StatusMeta {
  final String label;
  final Color color;
  final Color soft;
  final IconData icon;
  const _StatusMeta(this.label, this.color, this.soft, this.icon);
}
