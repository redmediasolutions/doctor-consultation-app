import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/chat_message.dart';
import '../../data/models/rtc_credentials.dart';
import '../config/app_config.dart';

enum CallConnection { idle, connecting, connected, reconnecting, failed }

/// Wraps the Agora RTC engine for the whole app.
///
/// All audio/video goes through Agora's network. Our backend only signs a short-lived
/// token per consultation (see backend/src/agora.js); the App Certificate never ships
/// in the app.
///
/// Each consultation uses its own channel (channel name = consultation id) with fixed
/// uids: patient 1001, doctor 2001. In-call chat uses an Agora data stream.
class AgoraService extends ChangeNotifier {
  RtcEngine? _engine;
  Future<void>? _initFuture;

  String? _channel;
  int? _remoteUid;
  bool _remoteVideoOn = true;
  bool _joined = false;
  bool _previewing = false;
  bool _micOn = true;
  bool _camOn = true;
  CallConnection _connection = CallConnection.idle;
  String? _lastError;
  int? _dataStreamId;
  Future<RtcCredentials> Function()? _renew;
  bool _disposed = false;

  final StreamController<ChatMessage> _chat = StreamController<ChatMessage>.broadcast();
  final StreamController<int> _remoteLeft = StreamController<int>.broadcast();

  RtcEngine? get engine => _engine;
  String? get channel => _channel;
  int? get remoteUid => _remoteUid;
  bool get remoteVideoOn => _remoteVideoOn;
  bool get joined => _joined;
  bool get previewing => _previewing;
  bool get micOn => _micOn;
  bool get camOn => _camOn;
  CallConnection get connection => _connection;
  String? get lastError => _lastError;

  /// Messages received from the other side of the call.
  Stream<ChatMessage> get chatMessages => _chat.stream;

  /// Fires with the remote uid when the other side leaves or drops.
  Stream<int> get remoteLeft => _remoteLeft.stream;

  /// Creates the engine once. Safe to call many times.
  Future<void> initialize() {
    _initFuture ??= _createEngine().catchError((Object e) {
      _initFuture = null; // allow retry
      throw e;
    });
    return _initFuture!;
  }

  Future<void> _createEngine() async {
    if (!AppConfig.isAgoraConfigured) {
      throw StateError('Agora App ID is not set. Add it in lib/core/config/app_config.dart.');
    }
    final engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(
      appId: AppConfig.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _joined = true;
        _connection = CallConnection.connected;
        _notify();
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        _joined = false;
        _remoteUid = null;
        _notify();
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        _remoteUid = remoteUid;
        _remoteVideoOn = true;
        _notify();
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        if (_remoteUid == remoteUid) {
          _remoteUid = null;
          _notify();
        }
        if (!_remoteLeft.isClosed) _remoteLeft.add(remoteUid);
      },
      onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
        if (remoteUid == _remoteUid) {
          _remoteVideoOn = !muted;
          _notify();
        }
      },
      onConnectionStateChanged: (
        RtcConnection connection,
        ConnectionStateType state,
        ConnectionChangedReasonType reason,
      ) {
        if (state == ConnectionStateType.connectionStateConnecting) {
          _connection = CallConnection.connecting;
        } else if (state == ConnectionStateType.connectionStateConnected) {
          _connection = CallConnection.connected;
        } else if (state == ConnectionStateType.connectionStateReconnecting) {
          _connection = CallConnection.reconnecting;
        } else if (state == ConnectionStateType.connectionStateFailed) {
          _connection = CallConnection.failed;
          _lastError = 'Video connection failed ($reason).';
        } else {
          _connection = CallConnection.idle;
        }
        _notify();
      },
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        _renewToken();
      },
      onRequestToken: (RtcConnection connection) {
        _renewToken();
      },
      onStreamMessage: (
        RtcConnection connection,
        int remoteUid,
        int streamId,
        Uint8List data,
        int length,
        int sentTs,
      ) {
        final msg = ChatMessage.tryDecode(utf8.decode(data, allowMalformed: true));
        if (msg != null && !_chat.isClosed) _chat.add(msg);
      },
      onError: (ErrorCodeType err, String msg) {
        _lastError = 'Agora error: $err $msg';
        debugPrint(_lastError);
      },
    ));

    await engine.enableVideo();
    _engine = engine;
  }

  /// Shows the local camera (used for the kiosk camera check and the doctor's self view).
  Future<void> startPreview() async {
    await initialize();
    await _engine!.startPreview();
    _previewing = true;
    _notify();
  }

  Future<void> stopPreview() async {
    final e = _engine;
    if (e == null || !_previewing || _channel != null) return;
    await e.stopPreview();
    _previewing = false;
    _notify();
  }

  /// Joins the consultation channel with credentials signed by our backend.
  /// [renew] is called when the token is about to expire.
  Future<void> join(RtcCredentials creds, {Future<RtcCredentials> Function()? renew}) async {
    await initialize();
    final e = _engine!;
    if (creds.appId.isNotEmpty && creds.appId != AppConfig.agoraAppId) {
      throw StateError(
        'The Agora App ID in the app does not match AGORA_APP_ID on the server. '
        'Use the same App ID in both places.',
      );
    }
    if (_channel != null) await leave(stopCamera: false);

    _renew = renew;
    _channel = creds.channelName;
    _remoteUid = null;
    _remoteVideoOn = true;
    _dataStreamId = null;
    _lastError = null;
    _connection = CallConnection.connecting;
    _notify();

    await e.startPreview();
    _previewing = true;
    await e.joinChannel(
      token: creds.token,
      channelId: creds.channelName,
      uid: creds.uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
    await e.muteLocalAudioStream(!_micOn);
    await e.muteLocalVideoStream(!_camOn);
  }

  /// Leaves the channel. Resets mic/camera to "on" for the next call.
  Future<void> leave({bool stopCamera = true}) async {
    final e = _engine;
    if (e != null) {
      if (_channel != null) {
        try {
          await e.leaveChannel();
        } catch (_) {}
      }
      if (stopCamera && _previewing) {
        try {
          await e.stopPreview();
        } catch (_) {}
        _previewing = false;
      }
      if (!_micOn) await e.muteLocalAudioStream(false);
      if (!_camOn) await e.muteLocalVideoStream(false);
    }
    _channel = null;
    _remoteUid = null;
    _joined = false;
    _dataStreamId = null;
    _renew = null;
    _micOn = true;
    _camOn = true;
    _connection = CallConnection.idle;
    _notify();
  }

  Future<void> toggleMic() async {
    _micOn = !_micOn;
    await _engine?.muteLocalAudioStream(!_micOn);
    _notify();
  }

  Future<void> toggleCamera() async {
    _camOn = !_camOn;
    await _engine?.muteLocalVideoStream(!_camOn);
    _notify();
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  /// Sends a chat message to the other side over an Agora data stream.
  Future<bool> sendChat(ChatMessage message) async {
    final e = _engine;
    if (e == null || !_joined) return false;
    try {
      _dataStreamId ??= await e.createDataStream(
        const DataStreamConfig(syncWithAudio: false, ordered: true),
      );
      final bytes = Uint8List.fromList(utf8.encode(message.encode()));
      await e.sendStreamMessage(streamId: _dataStreamId!, data: bytes, length: bytes.length);
      return true;
    } catch (err) {
      debugPrint('Agora sendStreamMessage failed: $err');
      return false;
    }
  }

  Future<void> _renewToken() async {
    final renew = _renew;
    final e = _engine;
    if (renew == null || e == null) return;
    try {
      final creds = await renew();
      if (creds.token.isNotEmpty) await e.renewToken(creds.token);
    } catch (err) {
      debugPrint('Agora token renewal failed: $err');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _chat.close();
    _remoteLeft.close();
    final e = _engine;
    _engine = null;
    if (e != null) {
      e.leaveChannel().catchError((_) {});
      e.release();
    }
    super.dispose();
  }
}
