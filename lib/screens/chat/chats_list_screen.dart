import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import '../orders/order_track_screen.dart';
import 'chat_screen.dart';

/// A single row in any of the Chats tabs — support/restaurant threads and
/// order entries all get normalized into this so they can share one list
/// tile design and (for "All Chats") be sorted together by recency.
/// [threadId] is only set for real chat_threads docs — that's what makes
/// a row swipe-to-delete-able; order entries (threadId == null) are just
/// a shortcut into order tracking, not a deletable conversation.
class _ChatEntry {
  final String? threadId;
  final Widget avatar;
  final String title;
  final String subtitle;
  final DateTime? time;
  final int unreadCount;
  final VoidCallback onTap;

  _ChatEntry({
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
    this.threadId,
    this.unreadCount = 0,
  });
}

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  final _searchController = TextEditingController();
  String _query = '';

  final _bootstrapChatService = ChatService();
  bool _connecting = true;
  String? _connectError;

  late Future<List<OrderSummary>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrderService.myOrders();
    _connect();
  }

  // A sign-in (any thread) is enough to authorize ChatService.myThreads(),
  // since the Firebase Auth session is shared app-wide.
  Future<void> _connect() async {
    try {
      await _bootstrapChatService.connect();
      if (mounted) setState(() => _connecting = false);
    } catch (e) {
      if (mounted) setState(() { _connecting = false; _connectError = e.toString(); });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _orderStatusMessage(String status) {
    switch (status) {
      case 'placed':
        return 'Your order has been placed.';
      case 'confirmed':
        return 'The restaurant confirmed your order.';
      case 'preparing':
        return 'Your order is being prepared.';
      case 'out_for_delivery':
        return 'Your order is on the way.';
      case 'delivered':
        return 'Your order has been delivered.';
      case 'cancelled':
        return 'This order was cancelled.';
      default:
        return status;
    }
  }

  _ChatEntry _threadEntry(Map<String, dynamic> data) {
    final isManager = data['recipientRole'] == 'manager';
    final ts = data['lastMessageAt'];
    return _ChatEntry(
      threadId: data['threadId'] as String,
      avatar: CircleAvatar(
        backgroundColor: isManager ? Colors.grey.shade200 : AppTheme.primary,
        child: Icon(
          isManager ? Icons.storefront : Icons.support_agent,
          color: isManager ? Colors.grey.shade700 : Colors.white,
        ),
      ),
      title: isManager ? ((data['restaurantName'] as String?) ?? 'Restaurant') : 'JEEVI Support',
      subtitle: (data['lastMessage'] as String?) ?? '',
      time: ts is Timestamp ? ts.toDate() : null,
      unreadCount: (data['unreadForCustomer'] as num?)?.toInt() ?? 0,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => isManager
            ? ChatScreen(restaurantId: data['restaurantId'] as int?, restaurantName: data['restaurantName'] as String?)
            : const ChatScreen(),
      )),
    );
  }

  List<_ChatEntry> _orderEntries(List<OrderSummary> orders) {
    return orders.map((o) {
      return _ChatEntry(
        avatar: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.receipt_long, color: Colors.grey.shade700),
        ),
        title: 'Order #${o.orderCode}',
        subtitle: _orderStatusMessage(o.status),
        time: o.placedAt != null ? DateTime.tryParse(o.placedAt!) : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderTrackScreen(orderCode: o.orderCode)),
        ),
      );
    }).toList();
  }

  String _relativeTime(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} Days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  List<_ChatEntry> _filtered(List<_ChatEntry> entries) {
    if (_query.trim().isEmpty) return entries;
    final q = _query.trim().toLowerCase();
    return entries.where((e) => e.title.toLowerCase().contains(q) || e.subtitle.toLowerCase().contains(q)).toList();
  }

  Future<void> _confirmDelete(_ChatEntry e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this chat?'),
        content: Text('This permanently deletes your conversation with ${e.title}. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && e.threadId != null) {
      try {
        await ChatService.deleteThread(e.threadId!);
      } catch (err) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $err')));
      }
    }
  }

  Widget _entryTile(_ChatEntry e) {
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: e.avatar,
      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(e.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_relativeTime(e.time), style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          if (e.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: Text('${e.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
        ],
      ),
      onTap: e.onTap,
    );

    // Only real chat threads (support/restaurant) are swipe-to-delete —
    // an order entry is just a shortcut into order tracking, not a
    // conversation of its own to delete.
    if (e.threadId == null) return tile;

    return Dismissible(
      key: ValueKey(e.threadId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(e);
        // We delete via Firestore ourselves above (which removes this
        // row from the underlying stream); returning false here just
        // stops Dismissible's own optimistic removal from racing it.
        return false;
      },
      child: tile,
    );
  }

  Widget _list(List<_ChatEntry> entries, String emptyText) {
    final filtered = _filtered(entries);
    if (filtered.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text(emptyText, style: TextStyle(color: Colors.grey.shade600))),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200, indent: 72),
      itemBuilder: (context, i) => _entryTile(filtered[i]),
    );
  }

  Widget _threadsStreamBuilder(Widget Function(List<Map<String, dynamic>> threads) builder) {
    if (_connecting) return const Center(child: CircularProgressIndicator());
    if (_connectError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_connectError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ChatService.myThreads(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        return builder(snap.data ?? []);
      },
    );
  }

  Widget _supportTab() {
    return _threadsStreamBuilder((threads) {
      final entries = threads.where((t) => t['recipientRole'] == 'admin').map(_threadEntry).toList();
      return _list(entries, 'No support conversations yet.');
    });
  }

  Widget _ordersTab() {
    return FutureBuilder<List<OrderSummary>>(
      future: _ordersFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        return _list(_orderEntries(snap.data ?? []), 'No orders yet.');
      },
    );
  }

  Widget _allTab() {
    return _threadsStreamBuilder((threads) {
      return FutureBuilder<List<OrderSummary>>(
        future: _ordersFuture,
        builder: (context, ordersSnap) {
          if (ordersSnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = <_ChatEntry>[
            ...threads.map(_threadEntry),
            ..._orderEntries(ordersSnap.data ?? []),
          ];
          entries.sort((a, b) {
            final at = a.time ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bt = b.time ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
          return _list(entries, 'No conversations yet.');
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.chatsListTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: t.chatsSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primary,
            indicatorColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: t.chatsTabAll),
              Tab(text: t.chatsTabOrders),
              Tab(text: t.chatsTabSupport),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _allTab(),
                _ordersTab(),
                _supportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
