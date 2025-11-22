import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../infrastructure/tenant/tenant_controller.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_state.dart';
import '../../theme/app_colors.dart';
import 'chatbot_sheet.dart';

class ChatBotLauncherButton extends StatelessWidget {
  const ChatBotLauncherButton({
    super.key,
    required this.heroTag,
  });

  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      onPressed: () => ChatBotLauncher.open(context),
      child: const Icon(Icons.smart_toy_outlined),
    );
  }
}

class ChatBotLauncher {
  static Future<void> open(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _notify(context, 'Inicia sesión para hablar con el asistente.');
      return;
    }

    final profileState = context.read<ProfileBloc>().state;
    final tenantController = context.read<TenantController>();

    final microId =
        profileState.profile?.microfinancieraId ?? tenantController.tenantId;
    if (microId == null || microId.isEmpty) {
      _notify(context, 'Selecciona una microfinanciera para usar el asistente.');
      return;
    }

    final userName =
        profileState.profile?.fullName ?? authState.user.displayName ?? 'Usuario';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ChatBotSheet(
          userId: authState.user.uid,
          microfinancieraId: microId,
          userName: userName,
        );
      },
    );
  }

  static void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
