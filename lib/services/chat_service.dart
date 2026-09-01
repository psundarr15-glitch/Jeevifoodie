import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../models/chat_message.dart';
import 'api_client.dart';

/// Real-time chat over Firestore. Replaces the old short-poll REST
/// service: instead of fetch()/send() hitting our own PHP backend, we
/// exchange our existing API bearer token for a Firebase custom token
/// (via [ApiConfig.chatFirebaseToken]) and then talk to Firestore
/// directly — messages arrive instantly via [messages], no more
/// 4-second poll delay and no more silently-dropped sends.
class ChatService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? _threadId;
  String? _customerName;
  String? _customerEmail;
  bool _signedIn = false;

  /// Must be called once before [messages]/[send] — signs this device in
  /// to Firebase with the role/ownership claims our backend decided are
  /// valid for [restaurantId] (falls back to the general admin thread if
  /// the customer doesn't actually have an order from that restaurant).
  Future<void> connect({int? restaurantId}) async {
    final res = await ApiClient.get(ApiConfig.chatFirebaseToken(restaurantId));
    final token = res['token'] as String;
    _threadId = res['thread_id'] as String;
    // From the backend (not local app state) so the thread doc always
    // gets a real name/email even if the profile wasn't loaded locally —
    // this is what the admin/manager inbox list displays per thread.
    _customerName = res['customer_name'] as String?;
    _customerEmail = res['customer_email'] as String?;

    if (!_signedIn) {
      await FirebaseAuth.instance.signInWithCustomToken(token);
      _signedIn = true;
    }
  }

  DocumentReference<Map<String, dynamic>> get _threadRef {
    if (_threadId == null) {
      throw StateError('ChatService.connect() must be called before use.');
    }
    return _db.collection('chat_threads').doc(_threadId);
  }

  CollectionReference<Map<String, dynamic>> get _messagesRef => _threadRef.collection('messages');

  /// Live stream of the thread's messages, oldest first.
  Stream<List<ChatMessage>> messages() {
    return _messagesRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  /// Live stream of just the thread's status ('open' | 'closed', or null
  /// if no conversation has started yet — treat that as open/new).
  Stream<String?> status() {
    return _threadRef.snapshots().map((snap) {
      if (!snap.exists) return null;
      return (snap.data()?['status'] as String?) ?? 'open';
    });
  }

  /// Live stream of the whole thread doc — used by the Chats list screen
  /// to show a last-message preview + unread badge without opening the
  /// conversation. Returns null if no conversation has started yet.
  Stream<Map<String, dynamic>?> threadData() {
    return _threadRef.snapshots().map((snap) => snap.exists ? snap.data() : null);
  }

  Future<void> send(String text) async {
    final threadSnap = await _threadRef.get();

    // Create/update the thread doc BEFORE adding the message (not after)
    // — a customer's very first message must not leave a message sitting
    // under a thread doc that doesn't exist yet, even briefly.
    if (threadSnap.exists) {
      final wasClosed = (threadSnap.data()?['status'] as String?) == 'closed';
      await _threadRef.update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadForStaff': FieldValue.increment(1),
        'unreadForCustomer': 0,
        // Sending a message after the chat ended naturally re-opens it —
        // no separate "reopen" step needed for the customer side.
        if (wasClosed) 'status': 'open',
        if (wasClosed) 'closedAt': null,
        if (wasClosed) 'closedBy': null,
      });
    } else {
      // First message in this thread — create it. userId/restaurantId/
      // recipientRole here must match what the backend's custom-token
      // claims allow, which firestore.rules re-checks on write.
      final parts = _threadId!.split('_');
      final isRestaurant = _threadId!.startsWith('restaurant_');
      await _threadRef.set({
        'userId': int.parse(FirebaseAuth.instance.currentUser!.uid),
        'restaurantId': isRestaurant ? int.parse(parts[1]) : null,
        'recipientRole': isRestaurant ? 'manager' : 'admin',
        'customerName': _customerName,
        'customerEmail': _customerEmail,
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadForStaff': 1,
        'unreadForCustomer': 0,
        'status': 'open',
      });
    }

    await _messagesRef.add({
      'sender': 'customer',
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Customer taps "End chat". Staff can still see the history; the
  /// customer sending another message re-opens it automatically (see
  /// [send]) rather than needing a separate "reopen" action.
  Future<void> closeChat() async {
    final snap = await _threadRef.get();
    if (!snap.exists) return;
    await _threadRef.update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': 'customer',
    });
  }

  /// Call when the thread is opened/visible to clear the customer's
  /// unread badge.
  Future<void> markRead() async {
    final snap = await _threadRef.get();
    if (snap.exists) {
      await _threadRef.update({'unreadForCustomer': 0});
    }
  }
}
