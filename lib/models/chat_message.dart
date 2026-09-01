import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String sender; // 'customer' or 'support'
  final String message;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    this.createdAt,
  });

  bool get isMine => sender == 'customer';

  factory ChatMessage.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final ts = data['createdAt'];
    return ChatMessage(
      id: doc.id,
      sender: data['sender']?.toString() ?? 'support',
      message: data['message']?.toString() ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
