import 'package:flutter/material.dart';
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
  const ChatScreen({super.key, this.restaurantId, this.restaurantName});

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
      await _chatService.connect(restaurantId: widget.restaurantId);
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = widget.restaurantId != null ? (widget.restaurantName ?? t.chatWithRestaurant) : t.liveChat;
    final emptyText = widget.restaurantId != null ? t.chatRestaurantEmptyState : t.chatEmptyState;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
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
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: messages.length,
                            itemBuilder: (context, i) {
                              final m = messages[i];
                              return Align(
                                alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: m.isMine ? AppTheme.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    m.message,
                                    style: TextStyle(color: m.isMine ? Colors.white : Colors.black87, fontSize: 14.5),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
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
