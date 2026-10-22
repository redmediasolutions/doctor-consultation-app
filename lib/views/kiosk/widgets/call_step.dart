import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';
import '../../widgets/call_stage.dart';
import '../../widgets/chat_panel.dart';
import '../../widgets/common.dart';

/// Patient side of the live video consultation.
class CallStep extends StatelessWidget {
  const CallStep({super.key});

  Future<void> _confirmLeave(BuildContext context, KioskViewModel vm) async {
    final ok = await confirmDialog(
      context,
      title: 'Leave the consultation?',
      message: 'If you leave now the doctor cannot send your prescription. '
          'Stay on the call until the doctor finishes.',
      confirmLabel: 'Leave',
      cancelLabel: 'Stay on call',
      destructive: true,
    );
    if (ok) await vm.leaveCall();
  }

  void _openChat(BuildContext context, KioskViewModel vm) {
    vm.markChatRead();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: vm,
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Consumer<KioskViewModel>(
              builder: (_, v, __) => ChatPanel(messages: v.messages, me: 'patient', onSend: v.sendChat),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();
    final c = vm.consultation;
    final d = c?.doctor;

    final stage = VideoCallStage(
      large: true,
      remoteLabel: d?.name ?? 'Doctor',
      remoteSubtitle: d == null ? null : '${d.specialty} · ${d.qualification}',
      since: c?.acceptedAt,
      waitingText: vm.videoError ?? 'Connecting you to the doctor…',
      hangUpLabel: 'Leave',
      onHangUp: () => _confirmLeave(context, vm),
      onReconnect: vm.reconnect,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth > 900;
        if (wide) {
          return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: stage),
            const SizedBox(width: 16),
            SizedBox(
              width: 340,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const _InfoCard(),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      const ListTile(
                        leading: Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                        title: Text('Messages', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const Divider(height: 1),
                      Expanded(child: ChatPanel(messages: vm.messages, me: 'patient', onSend: vm.sendChat)),
                    ]),
                  ),
                ),
              ]),
            ),
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: stage),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openChat(context, vm),
            icon: Badge(isLabelVisible: vm.hasUnreadChat, child: const Icon(Icons.chat_bubble_outline)),
            label: const Text('Messages'),
          ),
        ]);
      }),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'The doctor writes your prescription during the call. It will appear here and at the counter '
          'when the call ends.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
      ),
    );
  }
}
