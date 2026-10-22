import 'json_utils.dart';

/// Agora credentials for one user in one consultation channel, signed by our backend.
class RtcCredentials {
  const RtcCredentials({
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.token,
    required this.expiresAt,
  });

  final String appId;
  final String channelName;
  final int uid;

  /// Empty only when the Agora project is in Testing mode (no App Certificate).
  final String token;
  final DateTime? expiresAt;

  factory RtcCredentials.fromJson(Map<String, dynamic> j) => RtcCredentials(
        appId: asString(j['appId']),
        channelName: asString(j['channelName']),
        uid: asInt(j['uid']),
        token: asString(j['token']),
        expiresAt: asDate(j['expiresAt']),
      );
}
