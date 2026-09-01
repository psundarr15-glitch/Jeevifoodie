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
  bool _signedIn = false;

  /// Must be called once before [messages]/[send] — signs this device in
  /// to Firebase with the role/ownership claims our backend decided are
  /// valid for [restaurantId] (falls back to the general admin thread if
  /// the customer doesn't actually have an order from that restaurant).
  Future<void> connect({int? restaurantId}) async {
    final res = await ApiClient.get(ApiConfig.chatFirebaseToken(restaurantId));
    final token = res['token'] as String;
    _threadId = res['thread_id'] as String;

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

  Future<void> send(String text) async {
    final threadSnap = await _threadRef.get();

    // Create/update the thread doc BEFORE adding the message (not after)
    // — a customer's very first message must not leave a message sitting
    // under a thread doc that doesn't exist yet, even briefly.
    if (threadSnap.exists) {
      await _threadRef.update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadForStaff': FieldValue.increment(1),
        'unreadForCustomer': 0,
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
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadForStaff': 1,
        'unreadForCustomer': 0,
      });
    }

    await _messagesRef.add({
      'sender': 'customer',
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
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
