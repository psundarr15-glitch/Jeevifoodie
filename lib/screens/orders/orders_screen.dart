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

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<OrderSummary>> _future;
  late final TabController _tabs = TabController(length: 4, vsync: this);
  static const _tabKeys = ['All', 'Ongoing', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _future = OrderService.myOrders();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = OrderService.myOrders());
    await _future;
  }

  String _label(String key) {
    final t = AppLocalizations.of(context)!;
    switch (key) {
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

  bool _matches(String status, String key) {
    switch (key) {
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

  _StatusMeta _statusMeta(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const _StatusMeta(
          'Delivered',
          Color(0xFF18A957),
          Color(0xFFE8F8EF),
          Icons.check_circle_rounded,
        );
      case 'cancelled':
        return const _StatusMeta(
          'Cancelled',
          Color(0xFFE53935),
          Color(0xFFFFECEB),
          Icons.cancel_rounded,
        );
      case 'out_for_delivery':
        return const _StatusMeta(
          'Out for delivery',
          AppTheme.gold,
          AppTheme.softOrange,
          Icons.delivery_dining_rounded,
        );
      case 'picked_up':
        return const _StatusMeta(
          'Picked up',
          AppTheme.gold,
          AppTheme.softOrange,
          Icons.local_shipping_rounded,
        );
      case 'preparing':
        return const _StatusMeta(
          'Preparing',
          AppTheme.primary,
          AppTheme.softRed,
          Icons.soup_kitchen_rounded,
        );
      case 'confirmed':
        return const _StatusMeta(
          'Confirmed',
          AppTheme.primary,
          AppTheme.softRed,
          Icons.check_circle_outline_rounded,
        );
      default:
        return const _StatusMeta(
          'Order placed',
          AppTheme.primary,
          AppTheme.softRed,
          Icons.receipt_long_rounded,
        );
    }
  }

  String _date(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
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
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.myOrdersTitle,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.1,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Track every bite from kitchen to doorstep',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoundButton(
                    icon: Icons.search_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDECEE),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabs,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.muted,
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: _tabKeys.map((key) => Tab(text: _label(key))).toList(),
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
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                t.errorLabel(snapshot.error.toString()),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final orders = snapshot.data ?? <OrderSummary>[];
                    return TabBarView(
                      controller: _tabs,
                      children: _tabKeys.map((key) {
                        final list = orders
                            .where((order) => _matches(order.status, key))
                            .toList();

                        if (list.isEmpty) {
                          return ListView(
                            children: [
                              const SizedBox(height: 110),
                              Center(
                                child: Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    color: AppTheme.softRed,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppTheme.primary,
                                    size: 34,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  t.noOrdersHereYet,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final order = list[index];
                            return _OrderCard(
                              order: order,
                              meta: _statusMeta(order.status),
                              date: _date(order.placedAt),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrderTrackScreen(
                                    orderCode: order.orderCode,
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderSummary order;
  final _StatusMeta meta;
  final String date;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.meta,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 7, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                _OrderImage(url: order.imageUrl, fallbackColor: meta.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '₹${order.total.toStringAsFixed(0)}  •  ${order.paymentMethod.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: AppTheme.muted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: meta.soft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(meta.icon, size: 14, color: meta.color),
                            const SizedBox(width: 5),
                            Text(
                              meta.label.toUpperCase(),
                              style: TextStyle(
                                color: meta.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                  color: AppTheme.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderImage extends StatelessWidget {
  final String? url;
  final Color fallbackColor;

  const _OrderImage({required this.url, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppTheme.softRed,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Icon(Icons.restaurant_rounded, size: 34, color: fallbackColor)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.restaurant_rounded,
                size: 34,
                color: fallbackColor,
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppTheme.ink),
        ),
      ),
    );
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  final Color soft;
  final IconData icon;

  const _StatusMeta(this.label, this.color, this.soft, this.icon);
}
