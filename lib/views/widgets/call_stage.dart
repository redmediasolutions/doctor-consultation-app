import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/agora_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'video_views.dart';

/// Full video call surface: remote video, self view, timer and controls.
/// Reads the live call state from [AgoraService].
class VideoCallStage extends StatelessWidget {
  const VideoCallStage({
    super.key,
    required this.remoteLabel,
    this.remoteSubtitle,
    this.since,
    this.onHangUp,
    this.hangUpLabel = 'End',
    this.waitingText = 'Connecting…',
    this.onReconnect,
    this.large = false,
  });

  final String remoteLabel;
  final String? remoteSubtitle;
  final DateTime? since;
  final VoidCallback? onHangUp;
  final String hangUpLabel;
  final String waitingText;
  final VoidCallback? onReconnect;

  /// Bigger text and buttons for the kiosk.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final agora = context.watch<AgoraService>();
    final engine = agora.engine;
    final remoteUid = agora.remoteUid;
    final channel = agora.channel;
    final hasRemote = engine != null && remoteUid != null && channel != null;
    final problem = agora.connection == CallConnection.failed || agora.connection == CallConnection.reconnecting;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: AppColors.videoBackground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Remote video / placeholder
            if (hasRemote && agora.remoteVideoOn)
              RemoteVideoView(engine: engine, uid: remoteUid, channelId: channel)
            else
              _Placeholder(
                text: hasRemote ? '$remoteLabel turned the camera off' : waitingText,
                spinning: !hasRemote,
                large: large,
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xAA000000), Color(0x00000000)],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(remoteLabel,
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: large ? 20 : 16)),
                          if (remoteSubtitle != null)
                            Text(remoteSubtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white70, fontSize: large ? 15 : 12)),
                        ],
                      ),
                    ),
                    if (hasRemote) _CallTimer(since: since ?? DateTime.now()),
                  ],
                ),
              ),
            ),

            // Connection problem banner
            if (problem)
              Positioned(
                top: large ? 84 : 70,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.wifi_off, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        agora.connection == CallConnection.reconnecting ? 'Reconnecting…' : 'Connection lost',
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (onReconnect != null && agora.connection == CallConnection.failed) ...[
                        const SizedBox(width: 8),
                        TextButton(onPressed: onReconnect, child: const Text('Reconnect')),
                      ],
                    ]),
                  ),
                ),
              ),

            // Self view
            if (engine != null && agora.previewing)
              Positioned(
                right: 14,
                bottom: large ? 104 : 88,
                child: Container(
                  width: large ? 150 : 112,
                  height: large ? 200 : 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(fit: StackFit.expand, children: [
                      LocalVideoView(engine: engine),
                      if (!agora.camOn)
                        Container(
                          color: const Color(0xFF1F2933),
                          child: const Icon(Icons.videocam_off, color: Colors.white70),
                        ),
                    ]),
                  ),
                ),
              ),

            // Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: large ? 20 : 14, horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xB3000000), Color(0x00000000)],
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    _RoundButton(
                      icon: agora.micOn ? Icons.mic : Icons.mic_off,
                      active: agora.micOn,
                      tooltip: agora.micOn ? 'Mute' : 'Unmute',
                      onTap: agora.toggleMic,
                      large: large,
                    ),
                    _RoundButton(
                      icon: agora.camOn ? Icons.videocam : Icons.videocam_off,
                      active: agora.camOn,
                      tooltip: agora.camOn ? 'Turn camera off' : 'Turn camera on',
                      onTap: agora.toggleCamera,
                      large: large,
                    ),
                    _RoundButton(
                      icon: Icons.cameraswitch_outlined,
                      active: true,
                      tooltip: 'Switch camera',
                      onTap: agora.switchCamera,
                      large: large,
                    ),
                    if (onHangUp != null)
                      SizedBox(
                        height: large ? 60 : 52,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                          ),
                          onPressed: onHangUp,
                          icon: const Icon(Icons.call_end),
                          label: Text(hangUpLabel, style: TextStyle(fontSize: large ? 17 : 15)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text, required this.spinning, required this.large});

  final String text;
  final bool spinning;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (spinning)
            const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 3))
          else
            const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 40),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: large ? 19 : 15, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
    required this.large,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final Future<void> Function() onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 60.0 : 52.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? Colors.white.withValues(alpha: 0.92) : AppColors.danger,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onTap(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: active ? AppColors.text : Colors.white, size: large ? 28 : 24),
          ),
        ),
      ),
    );
  }
}

class _CallTimer extends StatefulWidget {
  const _CallTimer({required this.since});

  final DateTime since;

  @override
  State<_CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<_CallTimer> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.since);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          Fmt.clock(elapsed.isNegative ? Duration.zero : elapsed),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
