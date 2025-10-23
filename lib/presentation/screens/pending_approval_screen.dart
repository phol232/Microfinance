import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../components/primary_button.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              // Header con logo/icono
              const SizedBox(height: AppSpacing.xxl),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  size: 60,
                  color: AppColors.warning,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Título principal
              Text(
                'Cuenta Pendiente de Aprobación',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Descripción
              Text(
                'Tu cuenta ha sido creada exitosamente, pero necesita ser aprobada por un administrador antes de que puedas acceder a todas las funcionalidades.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '¿Qué sigue?',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• Se ha enviado una notificación al administrador\n'
                      '• Recibirás un email cuando tu cuenta sea aprobada\n'
                      '• El proceso puede tomar entre 24-48 horas',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Botones de acción
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      onPressed: () {
                        // Refrescar estado del usuario
                        context.read<AuthBloc>().add(AuthCheckRequested());
                      },
                      text: 'Verificar Estado',
                      icon: Icons.refresh,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(const AuthLogoutRequested());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        side: BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Cerrar Sesión',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}