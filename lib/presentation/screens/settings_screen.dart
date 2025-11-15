import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_state.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import 'profile_screen.dart';
import 'location_map_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _biometrics = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              'Personaliza tu experiencia en la aplicación',
              style: TextStyle(
                fontSize: screenWidth * 0.04, // 4% del ancho
                color: Colors.grey,
              ),
            ),
            SizedBox(height: screenHeight * 0.03), // 3% de la altura

            // Perfil de Usuario
            _buildProfileSection(),

            SizedBox(height: screenHeight * 0.02), // 2% de la altura

            // Apariencia
            _buildSectionCard(
              title: 'Apariencia',
              icon: Icons.palette_outlined,
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
              ],
            ),

            SizedBox(height: screenHeight * 0.02), // 2% de la altura

            // Notificaciones
            _buildSectionCard(
              title: 'Notificaciones',
              icon: Icons.notifications_outlined,
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notificaciones Push',
                  subtitle: 'Recibe alertas de nuevas solicitudes',
                  value: _notifications,
                  onChanged: (value) {
                    setState(() => _notifications = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Notificaciones activadas'
                              : 'Notificaciones desactivadas',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.02), // 2% de la altura

            // Seguridad
            _buildSectionCard(
              title: 'Seguridad',
              icon: Icons.security_outlined,
              children: [
                _buildSwitchTile(
                  icon: Icons.fingerprint_outlined,
                  title: 'Autenticación Biométrica',
                  subtitle: 'Usa huella o Face ID',
                  value: _biometrics,
                  onChanged: (value) {
                    setState(() => _biometrics = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente disponible'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: 'Cambiar Contraseña',
                  subtitle: 'Actualiza tu contraseña',
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

            SizedBox(height: screenHeight * 0.02), // 2% de la altura

            // Acerca de
            _buildSectionCard(
              title: 'Acerca de',
              icon: Icons.info_outline,
              children: [
                _buildListTile(
                  icon: Icons.article_outlined,
                  title: 'Términos y Condiciones',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidad',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'Ayuda y Soporte',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.info_outlined,
                  title: 'Versión',
                  subtitle: '1.0.0',
                  trailing: null,
                  onTap: null,
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.03), // 3% de la altura

            // Botón de ver ubicación
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToLocationMap(),
                icon: const Icon(Icons.location_on, color: AppColors.primary),
                label: Text(
                  'Ver Ubicación',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: screenWidth * 0.04, // 4% del ancho
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02), // 2% de la altura

            // Botón de cerrar sesión
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: screenWidth * 0.04, // 4% del ancho
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar Perfil'),
                style: OutlinedButton.styleFrom(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon, 
                  color: AppColors.primary, 
                  size: screenWidth * 0.06, // 6% del ancho
                ),
                SizedBox(width: screenWidth * 0.03), // 3% del ancho
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // 4.5% del ancho
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02), // 2% de la altura
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.02), // 2% del ancho
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.02), // 2% del ancho
        ),
        child: Icon(
          icon, 
          color: AppColors.primary, 
          size: screenWidth * 0.06, // 6% del ancho
        ),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.04, // 4% del ancho
        ),
      ),
      subtitle: Text(
        subtitle, 
        style: TextStyle(fontSize: screenWidth * 0.032), // 3.2% del ancho
      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.02), // 2% del ancho
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.02), // 2% del ancho
        ),
        child: Icon(
          icon, 
          color: AppColors.primary, 
          size: screenWidth * 0.06, // 6% del ancho
        ),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.04, // 4% del ancho
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle, 
              style: TextStyle(fontSize: screenWidth * 0.032), // 3.2% del ancho
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _navigateToLocationMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationMapScreen(),
      ),
    );
  }

  Future<void> _openLocationInMaps() async {
    const String address = "Jr. Tacna 340, Huancayo 12004";
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}";
    
    try {
      final Uri uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir la ubicación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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