import 'dart:convert';

import 'json_utils.dart';

/// In-call text message, sent over an Agora data stream (no server involved).
class ChatMessage {
  const ChatMessage({required this.from, required this.text, required this.at});

  /// "doctor" or "patient"
  final String from;
  final String text;
  final DateTime at;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        from: asString(j['from']),
        text: asString(j['text']),
        at: asDate(j['at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {'from': from, 'text': text, 'at': at.toUtc().toIso8601String()};

  String encode() => jsonEncode(toJson());

  static ChatMessage? tryDecode(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is Map<String, dynamic> && j['text'] is String) return ChatMessage.fromJson(j);
    } catch (_) {}
    return null;
  }
}
