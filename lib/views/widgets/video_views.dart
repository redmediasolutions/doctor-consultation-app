import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

/// Local camera via Agora. The controller is created once per widget.
class LocalVideoView extends StatefulWidget {
  const LocalVideoView({super.key, required this.engine});

  final RtcEngine engine;

  @override
  State<LocalVideoView> createState() => _LocalVideoViewState();
}

class _LocalVideoViewState extends State<LocalVideoView> {
  late VideoViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoViewController(
      rtcEngine: widget.engine,
      canvas: const VideoCanvas(uid: 0, renderMode: RenderModeType.renderModeHidden),
    );
  }

  @override
  Widget build(BuildContext context) => AgoraVideoView(controller: _controller);
}

/// Remote participant's video in a channel.
class RemoteVideoView extends StatefulWidget {
  const RemoteVideoView({super.key, required this.engine, required this.uid, required this.channelId});

  final RtcEngine engine;
  final int uid;
  final String channelId;

  @override
  State<RemoteVideoView> createState() => _RemoteVideoViewState();
}

class _RemoteVideoViewState extends State<RemoteVideoView> {
  late VideoViewController _controller;

  VideoViewController _create() => VideoViewController.remote(
        rtcEngine: widget.engine,
        canvas: VideoCanvas(uid: widget.uid, renderMode: RenderModeType.renderModeHidden),
        connection: RtcConnection(channelId: widget.channelId),
      );

  @override
  void initState() {
    super.initState();
    _controller = _create();
  }

  @override
  void didUpdateWidget(covariant RemoteVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid || oldWidget.channelId != widget.channelId) {
      _controller = _create();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgoraVideoView(
      key: ValueKey('${widget.channelId}-${widget.uid}'),
      controller: _controller,
    );
  }
}
