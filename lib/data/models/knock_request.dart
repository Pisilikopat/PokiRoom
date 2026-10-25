// lib/data/models/knock_request.dart

class KnockRequest {
  const KnockRequest({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    required this.createdAt,
    this.message,
  });

  final String id;
  final String senderId;
  final String senderNickname;
  final String? message;
  final DateTime createdAt;

  factory KnockRequest.fromMap(Map<String, dynamic> m) {
    final sender = m['sender'] as Map<String, dynamic>?;
    return KnockRequest(
      id: m['id'] as String,
      senderId: m['sender_id'] as String,
      senderNickname: (sender?['nickname'] as String?) ?? 'Biri',
      message: m['knock_message'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
