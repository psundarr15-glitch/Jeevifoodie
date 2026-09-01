import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../theme.dart';
import 'order_track_screen.dart';
import '../../l10n/app_localizations.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late Future<List<OrderSummary>> _future;
  late final TabController _tabController = TabController(length: 4, vsync: this);

  // Internal keys used for filtering logic - NOT shown to the user;
  // see _tabLabel() below for the translated display text.
  static const _tabs = ['All', 'Ongoing', 'Completed', 'Cancelled'];

  String _tabLabel(String tab) {
    final t = AppLocalizations.of(context)!;
    switch (tab) {
      case 'Ongoing':
        return t.tabOngoing;
      case 'Completed':
        return t.tabCompleted;
      case 'Cancelled':
        return t.tabCancelled;
      default:
        return t.tabAll;
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
      case 'Ongoing':
        return status != 'delivered' && status != 'cancelled';
      case 'Completed':
        return status == 'delivered';
      case 'Cancelled':
        return status == 'cancelled';
      default:
        return true;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.success;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.gold;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myOrdersTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          indicatorColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((tab) => Tab(text: _tabLabel(tab))).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<OrderSummary>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                const SizedBox(height: 80),
                Center(child: Text(AppLocalizations.of(context)!.errorLabel(snap.error.toString()))),
              ]);
            }
            final orders = snap.data!;
            return TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = orders.where((o) => _matchesTab(o.status, tab)).toList();
                if (filtered.isEmpty) {
                  return ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text(AppLocalizations.of(context)!.noOrdersHereYet)),
                  ]);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final o = filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('#${o.orderCode}'),
                        subtitle: Text('₹${o.total.toStringAsFixed(0)} • ${o.paymentMethod.toUpperCase()}'),
                        trailing: Chip(
                          label: Text(o.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: _statusColor(o.status),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => OrderTrackScreen(orderCode: o.orderCode)),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
