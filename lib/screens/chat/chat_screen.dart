import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

/// Real-time live chat (Firestore-backed — see ChatService). Pass
/// [restaurantId] to open the thread with that restaurant's manager about
/// a specific order; leave it null for the general app-admin support
/// thread.
class ChatScreen extends StatefulWidget {
  final int? restaurantId;
  final String? restaurantName;
  final int? orderId;
  final String? orderCode;
  const ChatScreen({super.key, this.restaurantId, this.restaurantName, this.orderId, this.orderCode});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _chatService = ChatService();
  bool _connecting = true;
  String? _connectError;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _chatService.connect(restaurantId: widget.restaurantId, restaurantName: widget.restaurantName, orderId: widget.orderId, orderCode: widget.orderCode);
      await _chatService.markRead();
      if (mounted) setState(() => _connecting = false);
    } catch (e) {
      if (mounted) setState(() { _connecting = false; _connectError = e.toString(); });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _inputController.clear();
    try {
      await _chatService.send(text);
    } catch (e) {
      if (mounted) {
        _inputController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1600);
    if (picked == null || !mounted) return;

    setState(() => _sending = true);
    try {
      await _chatService.sendImage(File(picked.path));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send photo: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openImageViewer(String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: InteractiveViewer(child: Image.network(url))),
      ),
    ));
  }

  Future<void> _confirmEndChat(AppLocalizations t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.chatEndTitle),
        content: Text(t.chatEndConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.chatEndCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.chatEndConfirmAction)),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _chatService.closeChat();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// "Today" / "Yesterday" / a short date — used as the sticky-looking
  /// separator pill between groups of messages sent on different days.
  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final that = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _timeLabel(DateTime? d) {
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = widget.restaurantId != null ? (widget.restaurantName ?? t.chatWithRestaurant) : t.liveChat;
    final emptyText = widget.restaurantId != null ? t.chatRestaurantEmptyState : t.chatEmptyState;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Icon(widget.restaurantId != null ? Icons.storefront : Icons.support_agent, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16))),
                      if (widget.restaurantId == null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 15, color: AppTheme.primary),
                      ],
                    ],
                  ),
                  if (!_connecting && _connectError == null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Online', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!_connecting && _connectError == null)
            StreamBuilder<String?>(
              stream: _chatService.status(),
              builder: (context, statusSnap) {
                final isOpen = statusSnap.data != 'closed';
                if (!isOpen) return const SizedBox.shrink();
                return IconButton(
                  tooltip: t.chatEndAction,
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _confirmEndChat(t),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.restaurantId != null && widget.orderId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primary.withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order ${widget.orderCode != null && widget.orderCode!.isNotEmpty ? '#${widget.orderCode}' : '#${widget.orderId}'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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
                    : StreamBuilder<List<ChatMessage>>(
                        stream: _chatService.messages(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('${snapshot.error}'));
                          }
                          final messages = snapshot.data ?? [];
                          if (messages.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(emptyText, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                              ),
                            );
                          }
                          _scrollToBottomSoon();

                          // Flatten into a list of either a date-separator
                          // pill or a message bubble, one day-pill each
                          // time the calendar day changes going forward.
                          final rows = <Widget>[];
                          DateTime? lastDay;
                          for (final m in messages) {
                            final createdAt = m.createdAt;
                            if (createdAt != null) {
                              final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
                              if (lastDay == null || day != lastDay) {
                                rows.add(Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                                    child: Text(_dayLabel(createdAt), style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                                  ),
                                ));
                                lastDay = day;
                              }
                            }
                            rows.add(Align(
                              alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: m.isImage && m.imageUrl != null ? () => _openImageViewer(m.imageUrl!) : null,
                                child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                padding: m.isImage
                                    ? const EdgeInsets.all(6)
                                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: m.isMine ? AppTheme.primary : AppTheme.surface(context),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (m.isImage && m.imageUrl != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          m.imageUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            return const SizedBox(
                                              width: 160,
                                              height: 160,
                                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                            );
                                          },
                                          errorBuilder: (context, error, stack) => const SizedBox(
                                            width: 160,
                                            height: 160,
                                            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        m.message,
                                        style: TextStyle(color: m.isMine ? Colors.white : AppTheme.textPrimary(context), fontSize: 14.5),
                                      ),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _timeLabel(m.createdAt),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: m.isMine
                                                ? (m.isImage ? Colors.black45 : Colors.white70)
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        // Sent indicator — a real read-receipt
                                        // (double-tick turning blue once the
                                        // other side has actually seen it)
                                        // would need per-message read state,
                                        // which we don't track yet; this just
                                        // shows the message made it to the
                                        // server.
                                        if (m.isMine) ...[
                                          const SizedBox(width: 3),
                                          Icon(Icons.done_all, size: 13, color: m.isImage ? Colors.black45 : Colors.white70),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ),
                            ));
                          }

                          return ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            children: rows,
                          );
                        },
                      ),
          ),
          if (!_connecting && _connectError == null)
            StreamBuilder<String?>(
              stream: _chatService.status(),
              builder: (context, statusSnap) {
                if (statusSnap.data != 'closed') return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    t.chatEndedBanner,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                  ),
                );
              },
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 10, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey.shade500),
                    tooltip: 'Send a photo',
                    onPressed: (_connecting || _connectError != null || _sending) ? null : _pickAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !_connecting && _connectError == null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: t.chatInputHint,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
