import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_state.dart';
import '../providers/theme_provider.dart';
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
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        final version = info.version;
        final build = info.buildNumber;
        final display = build.isNotEmpty && build != version
            ? '$version+$build'
            : version;
        setState(() {
          _appVersion = display;
        });
      }
    } catch (_) {
      // Ignorar error
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                color: colorScheme.onSurfaceVariant,
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
                  onTap: () => _showSupportSheet(context),
                ),
                _buildListTile(
                  icon: Icons.info_outlined,
                  title: 'Versión',
                  subtitle: _appVersion.isEmpty ? null : _appVersion,
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
                icon: Icon(Icons.location_on, color: colorScheme.primary),
                label: Text(
                  'Ver Ubicación',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: screenWidth * 0.04, // 4% del ancho
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02), // 2% de la altura
            // Botón de cerrar sesión
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: Icon(Icons.logout, color: colorScheme.error),
                label: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: colorScheme.error,
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
    final colorScheme = Theme.of(context).colorScheme;
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
                Builder(
                  builder: (_) {
                    final Uint8List? photoBytes = _decodeBase64Image(
                      profile?.photoBase64,
                    );
                    final String? photoUrl = profile?.photoUrl;
                    ImageProvider? avatarImage;

                    if (photoBytes != null) {
                      avatarImage = MemoryImage(photoBytes);
                    } else if (photoUrl != null && photoUrl.isNotEmpty) {
                      avatarImage = NetworkImage(photoUrl);
                    }

                    return CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              profile?.firstName.isNotEmpty == true
                                  ? profile!.firstName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            )
                          : null,
                    );
                  },
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
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
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
    final colorScheme = Theme.of(context).colorScheme;

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
                  color: colorScheme.primary,
                  size: screenWidth * 0.06, // 6% del ancho
                ),
                SizedBox(width: screenWidth * 0.03), // 3% del ancho
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // 4.5% del ancho
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.02), // 2% del ancho
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            screenWidth * 0.02,
          ), // 2% del ancho
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: screenWidth * 0.06, // 6% del ancho
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.04, // 4% del ancho
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: screenWidth * 0.032, // 3.2% del ancho
          color: colorScheme.onSurfaceVariant,
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.02), // 2% del ancho
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            screenWidth * 0.02,
          ), // 2% del ancho
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: screenWidth * 0.06, // 6% del ancho
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.04, // 4% del ancho
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: screenWidth * 0.032, // 3.2% del ancho
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _navigateToLocationMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationMapScreen()),
    );
  }

  void _showSupportSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.support_agent,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Soporte Técnico',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _supportRow(
                icon: Icons.person_outline,
                label: 'Nombre',
                value: 'Phol Edwin Taquiri Rojas',
                colorScheme: colorScheme,
              ),
              _supportRow(
                icon: Icons.email_outlined,
                label: 'Correo',
                value: 'edwinrojastaquiri@gmail.com',
                colorScheme: colorScheme,
              ),
              _supportRow(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: '934866486',
                colorScheme: colorScheme,
              ),
              if (_appVersion.isNotEmpty)
                _supportRow(
                  icon: Icons.info_outline,
                  label: 'Versión',
                  value: _appVersion,
                  colorScheme: colorScheme,
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _supportRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocationInMaps() async {
    const String address = "Jr. Tacna 340, Huancayo 12004";
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}";

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

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }
}
