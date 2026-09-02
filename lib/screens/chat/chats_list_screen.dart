import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import 'chat_screen.dart';

/// A single row in the Chats list — support/restaurant threads, all
/// backed by a real chat_threads doc (that's what makes a row
/// swipe-to-delete-able).
class _ChatEntry {
  final String threadId;
  final Widget avatar;
  final String title;
  final String subtitle;
  final DateTime? time;
  final int unreadCount;
  final VoidCallback onTap;

  _ChatEntry({
    required this.threadId,
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
    this.unreadCount = 0,
  });
}

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  final _bootstrapChatService = ChatService();
  bool _connecting = true;
  String? _connectError;

  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    super.dispose();
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
    if (confirmed == true) {
      try {
        await ChatService.deleteThread(e.threadId);
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
          Expanded(
            child: _connecting
                ? const Center(child: CircularProgressIndicator())
                : _connectError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_connectError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      )
                    : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: ChatService.myThreads(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snap.hasError) {
                            return Center(child: Text('${snap.error}'));
                          }
                          final entries = _filtered((snap.data ?? []).map(_threadEntry).toList());
                          if (entries.isEmpty) {
                            return ListView(children: [
                              const SizedBox(height: 120),
                              Center(child: Text('No conversations yet.', style: TextStyle(color: Colors.grey.shade600))),
                            ]);
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200, indent: 72),
                            itemBuilder: (context, i) => _entryTile(entries[i]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
