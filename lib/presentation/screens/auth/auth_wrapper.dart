import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../main_screen.dart';
import 'login_page.dart';
import 'pending_approval_page.dart';
import 'unauthorized_access_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          return const MainScreen();
        }

        if (state is AuthPending) {
          return PendingApprovalPage(user: state.user, message: state.message);
        }

        if (state is AuthUnauthorized) {
          return UnauthorizedAccessScreen(
            reason: state.reason,
            message: state.message,
          );
        }

        return const LoginPage();
      },
    );
  }
}
