import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/app_user.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class PendingApprovalPage extends StatelessWidget {
  final AppUser user;
  final String message;

  const PendingApprovalPage({
    super.key,
    required this.user,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05), // 5% del ancho
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de reloj/pendiente
              Container(
                width: screenWidth * 0.3, // 30% del ancho
                height: screenWidth * 0.3, // 30% del ancho (mantener aspecto cuadrado)
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  size: screenWidth * 0.15, // 15% del ancho
                  color: Colors.orange,
                ),
              ),
              
              SizedBox(height: screenHeight * 0.04), // 4% de la altura
              
              // Título
              Text(
                'Cuenta Pendiente de Aprobación',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: screenWidth * 0.06, // 6% del ancho
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: screenHeight * 0.02), // 2% de la altura
              
              // Mensaje
              Text(
                message,
                style: AppTypography.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: screenWidth * 0.045, // 4.5% del ancho
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: screenHeight * 0.03), // 3% de la altura
              
              // Información del usuario
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03), // 3% del ancho
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          color: Theme.of(context).colorScheme.primary,
                          size: screenWidth * 0.05, // 5% del ancho
                        ),
                        SizedBox(width: screenWidth * 0.03), // 3% del ancho
                        Expanded(
                          child: Text(
                            user.email ?? 'Sin email',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: screenWidth * 0.04, // 4% del ancho
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user.displayName != null) ...[
                      SizedBox(height: screenHeight * 0.015), // 1.5% de la altura
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                            size: screenWidth * 0.05, // 5% del ancho
                          ),
                          SizedBox(width: screenWidth * 0.03), // 3% del ancho
                          Expanded(
                            child: Text(
                              user.displayName!,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: screenWidth * 0.04, // 4% del ancho
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: screenHeight * 0.04), // 4% de la altura
              
              // Botón de cerrar sesión
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                  child: Text(
                    'Cerrar Sesión',
                    style: TextStyle(fontSize: screenWidth * 0.04), // 4% del ancho
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02), // 2% de la altura
              
              // Texto informativo adicional
              Text(
                'Recibirás una notificación por email cuando tu cuenta sea aprobada.',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: screenWidth * 0.035, // 3.5% del ancho
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}