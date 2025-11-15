import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_state.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // TODO: Implementar notificaciones más adelante
  // bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Configuración',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestiona tu perfil y preferencias',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Perfil de Usuario
            _buildProfileSection(),

            const SizedBox(height: 16),

            // Preferencias
            _buildSectionCard(
              title: 'Preferencias',
              icon: Icons.settings_outlined,
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Modo Oscuro',
                      subtitle: 'Activa el tema oscuro',
                      value: themeProvider.isDarkMode,
                      onChanged: (value) async {
                        await themeProvider.toggleTheme();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Modo oscuro activado'
                                    : 'Modo claro activado',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                // TODO: Implementar notificaciones más adelante
                // _buildSwitchTile(
                //   icon: Icons.notifications_active_outlined,
                //   title: 'Notificaciones',
                //   subtitle: 'Recibe alertas importantes',
                //   value: _notifications,
                //   onChanged: (value) {
                //     setState(() => _notifications = value);
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       SnackBar(
                //         content: Text(
                //           value
                //               ? 'Notificaciones activadas'
                //               : 'Notificaciones desactivadas',
                //         ),
                //         duration: const Duration(seconds: 2),
                //       ),
                //     );
                //   },
                // ),
              ],
            ),

            const SizedBox(height: 16),

            // Ayuda y Soporte
            _buildSectionCard(
              title: 'Ayuda y Soporte',
              icon: Icons.help_outline,
              children: [
                _buildListTile(
                  icon: Icons.chat_outlined,
                  title: 'Chat de Ayuda',
                  subtitle: 'Habla con nuestro equipo',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente disponible'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.phone_outlined,
                  title: 'Llamar al Soporte',
                  subtitle: 'Contacto directo',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente disponible'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.article_outlined,
                  title: 'Preguntas Frecuentes',
                  subtitle: 'Encuentra respuestas rápidas',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente disponible'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información
            _buildSectionCard(
              title: 'Información',
              icon: Icons.info_outline,
              children: [
                _buildListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidad',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente disponible'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y Condiciones',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente disponible'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.info_outlined,
                  title: 'Versión de la App',
                  subtitle: '1.0.0',
                  trailing: null,
                  onTap: null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botón de cerrar sesión
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final profile = profileState.profile;
        final authState = context.watch<AuthBloc>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;

        return _buildSectionCard(
          title: 'Mi Perfil',
          icon: Icons.person_outline,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage:
                      profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty
                      ? NetworkImage(profile.photoUrl!)
                      : null,
                  child: profile?.photoUrl == null || profile!.photoUrl!.isEmpty
                      ? Text(
                          profile?.firstName.isNotEmpty == true
                              ? profile!.firstName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? user?.displayName ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.email ?? user?.email ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (profile?.dni != null && profile!.dni!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'DNI: ${profile.dni}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar Datos Personales'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 13))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}