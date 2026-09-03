import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../services/notification_history_service.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppNotification>> _load() async {
    final items = await NotificationHistoryService.recent();
    // Mark everything up to the newest as seen so the bell's swing
    // animation doesn't fire again until a genuinely new broadcast
    // arrives after this point.
    if (items.isNotEmpty) {
      await NotificationHistoryService.setLastSeenId(items.first.id);
    }
    return items;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  String _dateHeading(DateTime dt) {
    final now = DateTime.now();
    final that = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return AppLocalizations.of(context)!.today;
    if (diff == 1) return AppLocalizations.of(context)!.yesterday;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  void _openDetail(AppNotification n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              if (n.imageUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    n.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 10),
                    Text(n.body, style: TextStyle(color: Colors.grey.shade700, fontSize: 14.5, height: 1.4)),
                    const SizedBox(height: 16),
                    Text(_time(n.createdAt), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.notifications)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                const SizedBox(height: 80),
                Center(child: Text(AppLocalizations.of(context)!.couldNotLoadNotifications(snap.error.toString()))),
              ]);
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 120),
                const Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Center(child: Text(AppLocalizations.of(context)!.noNotificationsYet)),
              ]);
            }

            // Group consecutive items under a date heading, same as the
            // day-separated layout in the reference design.
            final widgets = <Widget>[];
            String? lastHeading;
            for (final n in items) {
              final heading = _dateHeading(n.createdAt);
              if (heading != lastHeading) {
                widgets.add(Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Text(heading, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ));
                lastHeading = heading;
              }
              widgets.add(_NotificationTile(n: n, time: _time(n.createdAt), onTap: () => _openDetail(n)));
            }

            return ListView(padding: const EdgeInsets.only(bottom: 16), children: widgets);
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final String time;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.18), shape: BoxShape.circle),
              child: const Icon(Icons.notifications, color: AppTheme.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (n.imageUrl != null) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  n.imageUrl!,
                  width: 64,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
