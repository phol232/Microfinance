import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/user_profile.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_event.dart';
import '../bloc/profile/profile_state.dart';
import '../components/primary_button.dart';
import '../components/text_field_outlined.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _currentProfile;
  bool _isEditing = false;
  String? _photoBase64;
  Uint8List? _previewPhotoBytes;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileBloc>().add(
        ProfileLoadRequested(uid: authState.user.uid),
      );
    }
  }

  void _populateControllers(UserProfile profile) {
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _dniController.text = profile.dni ?? '';
    _phoneController.text = profile.phone ?? '';
    _photoUrlController.text = profile.photoUrl ?? '';
    _photoBase64 = profile.photoBase64;
    _previewPhotoBytes = _decodeBase64Image(profile.photoBase64);
  }

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              _loadUserProfile();
            } else if (state is AuthUnauthenticated) {
              setState(() {
                _currentProfile = null;
                _isEditing = false;
              });
            }
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.status == ProfileStatus.error &&
                state.errorMessage != null) {
              _showSnackBar(state.errorMessage!, isError: true);
            }

            final profile = state.profile;
            if (profile != null) {
              setState(() {
                _currentProfile = profile;
                _populateControllers(profile);
                if (state.status == ProfileStatus.success) {
                  _isEditing = false;
                }
              });

              if (state.status == ProfileStatus.success) {
                _showSnackBar(
                  'Perfil actualizado correctamente',
                  duration: const Duration(milliseconds: 250),
                );
              }
            }
          },
        ),
      ],
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final isLoading = state.isLoading;
          if (isLoading && _currentProfile == null) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.surfaceGradient,
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi Perfil'),
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              systemOverlayStyle: isDark
                  ? SystemUiOverlayStyle.light.copyWith(
                      statusBarColor: colorScheme.surface,
                      systemNavigationBarColor: colorScheme.surface,
                    )
                  : SystemUiOverlayStyle.dark.copyWith(
                      statusBarColor: colorScheme.surface,
                      systemNavigationBarColor: colorScheme.surface,
                    ),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Container(
              color: colorScheme.surface,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isCompact =
                        screenWidth <= 600; // Usando screenWidth
                    final double horizontalPadding = isCompact
                        ? screenWidth *
                              0.04 // 4% del ancho
                        : screenWidth * 0.08; // 8% del ancho

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: screenHeight * 0.03, // 3% de la altura
                      ),
                      child: Column(
                        children: [
                          // Header profesional con avatar y stats
                          _buildProfileHeader(),
                          SizedBox(
                            height: screenHeight * 0.04,
                          ), // 4% de la altura
                          // Información personal en cards elegantes
                          if (_isEditing)
                            _buildEditForm(isLoading: isLoading)
                          else
                            _buildProfileSections(),

                          SizedBox(
                            height: screenHeight * 0.06,
                          ), // 6% de la altura
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            floatingActionButton: _buildFloatingActions(isLoading: isLoading),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.01,
      ), // 1% del ancho
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.06), // 6% del ancho
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: screenWidth * 0.04, // 4% del ancho
            offset: Offset(0, screenHeight * 0.01), // 1% de la altura
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05), // 5% del ancho
        child: Column(
          children: [
            // Avatar con indicador de estado
            Stack(
              children: [
                Builder(
                  builder: (_) {
                    final Uint8List? displayBytes =
                        _previewPhotoBytes ??
                        _decodeBase64Image(_currentProfile?.photoBase64);
                    final String? photoUrl = _currentProfile?.photoUrl;
                    ImageProvider? avatarImage;

                    if (displayBytes != null) {
                      avatarImage = MemoryImage(displayBytes);
                    } else if (photoUrl != null && photoUrl.isNotEmpty) {
                      avatarImage = NetworkImage(photoUrl);
                    }

                    return CircleAvatar(
                      radius: screenWidth * 0.125, // 12.5% del ancho
                      backgroundColor: colorScheme.onPrimary.withValues(
                        alpha: 0.2,
                      ),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              _currentProfile?.firstName.isNotEmpty == true
                                  ? _currentProfile!.firstName[0].toUpperCase()
                                  : 'U',
                              style: AppTypography.headlineMedium.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.08, // 8% del ancho
                              ),
                            )
                          : null,
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.01), // 1% del ancho
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50), // Success green
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: colorScheme.onPrimary,
                      size: screenWidth * 0.04, // 4% del ancho
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.025), // 2.5% de la altura
            // Nombre completo
            Text(
              _currentProfile?.fullName ?? 'Usuario',
              style: AppTypography.headlineMedium.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.055, // 5.5% del ancho
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.005), // 0.5% de la altura
            // Email con icono
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  size: screenWidth * 0.04, // 4% del ancho
                ),
                SizedBox(width: screenWidth * 0.02), // 2% del ancho
                Flexible(
                  child: Text(
                    _currentProfile?.email ?? '',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: screenWidth * 0.035, // 3.5% del ancho
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.025), // 2.5% de la altura
            // Stats row
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, // 4% del ancho
        vertical: screenHeight * 0.015, // 1.5% de la altura
      ),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.04), // 4% del ancho
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Años', '2+', Icons.calendar_today_outlined),
          _buildVerticalDivider(),
          _buildStatItem(
            'Créditos',
            '5',
            Icons.account_balance_wallet_outlined,
          ),
          _buildVerticalDivider(),
          _buildStatItem('Estado', 'Activo', Icons.verified_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.onPrimary.withValues(alpha: 0.9),
          size: screenWidth * 0.05, // 5% del ancho
        ),
        SizedBox(height: screenHeight * 0.005), // 0.5% de la altura
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.035, // 3.5% del ancho
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.8),
            fontSize: screenWidth * 0.03, // 3% del ancho
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: screenHeight * 0.05, // 5% de la altura
      width: screenWidth * 0.002, // 0.2% del ancho
      color: colorScheme.onPrimary.withValues(alpha: 0.3),
    );
  }

  Widget _buildProfileSections() {
    return Column(
      children: [
        // Información Personal
        _buildInfoCard(
          title: 'Información Personal',
          icon: Icons.person_outline,
          children: [
            _buildModernInfoRow(
              icon: Icons.badge_outlined,
              label: 'Nombre completo',
              value:
                  '${_currentProfile?.firstName ?? ''} ${_currentProfile?.lastName ?? ''}',
              isEmpty: (_currentProfile?.firstName ?? '').isEmpty,
            ),
            _buildModernInfoRow(
              icon: Icons.credit_card_outlined,
              label: 'DNI/NIE',
              value: _currentProfile?.dni ?? 'No especificado',
              isEmpty: (_currentProfile?.dni ?? '').isEmpty,
            ),
            _buildModernInfoRow(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: _currentProfile?.phone ?? 'No especificado',
              isEmpty: (_currentProfile?.phone ?? '').isEmpty,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Configuración de cuenta
        _buildInfoCard(
          title: 'Configuración de Cuenta',
          icon: Icons.settings_outlined,
          children: [
            _buildModernInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _currentProfile?.email ?? 'No especificado',
              isEmpty: false,
            ),
            _buildModernInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Miembro desde',
              value: _currentProfile?.createdAt != null
                  ? _formatDate(_currentProfile!.createdAt!)
                  : 'No especificado',
              isEmpty: _currentProfile?.createdAt == null,
            ),
            _buildModernInfoRow(
              icon: Icons.update_outlined,
              label: 'Última actualización',
              value: _currentProfile?.updatedAt != null
                  ? _formatDate(_currentProfile!.updatedAt!)
                  : 'No especificado',
              isEmpty: _currentProfile?.updatedAt == null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la sección
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Contenido
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEmpty,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEmpty
                  ? colorScheme.outline.withValues(alpha: 0.1)
                  : colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isEmpty
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isEmpty
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                    fontStyle: isEmpty ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm({required bool isLoading}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del formulario
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Editar Perfil',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Nombres en fila
              Row(
                children: [
                  Expanded(
                    child: TextFieldOutlined(
                      label: 'Nombre *',
                      hint: 'Tu nombre',
                      controller: _firstNameController,
                      prefixIcon: const Icon(Icons.person_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFieldOutlined(
                      label: 'Apellido *',
                      hint: 'Tu apellido',
                      controller: _lastNameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu apellido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // DNI
              TextFieldOutlined(
                label: 'DNI/NIE',
                hint: 'Documento de identidad',
                controller: _dniController,
                prefixIcon: const Icon(Icons.credit_card_outlined),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 8 || value.trim().length > 12) {
                      return 'DNI debe tener entre 8 y 12 caracteres';
                    }
                    if (!RegExp(r'^[0-9]+[A-Z]?$').hasMatch(value.trim())) {
                      return 'Formato de DNI inválido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Teléfono
              TextFieldOutlined(
                label: 'Teléfono',
                hint: '+34 600 000 000',
                controller: _phoneController,
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      value.trim().length < 9) {
                    return 'Ingresa un teléfono válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // URL de foto (opcional)
              TextFieldOutlined(
                label: 'URL de foto (opcional)',
                hint: 'https://...',
                controller: _photoUrlController,
                prefixIcon: const Icon(Icons.photo_outlined),
                keyboardType: TextInputType.url,
                onChanged: (_) {
                  if (_photoBase64 != null || _previewPhotoBytes != null) {
                    setState(() {
                      _photoBase64 = null;
                      _previewPhotoBytes = null;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (isLoading || _isPickingImage)
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        _isPickingImage ? 'Abriendo cámara...' : 'Tomar foto',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (isLoading || _isPickingImage)
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _isPickingImage ? 'Cargando...' : 'Elegir de galería',
                      ),
                    ),
                  ),
                ],
              ),
              if (_previewPhotoBytes != null) ...[
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.memory(
                    _previewPhotoBytes!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _cancelEdit,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Guardar Cambios',
                      onPressed: isLoading ? null : _updateProfile,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions({required bool isLoading}) {
    if (_isEditing) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: isLoading ? null : _startEditing,
          heroTag: 'edit_profile',
          child: const Icon(Icons.edit_outlined),
        ),
        const SizedBox(height: AppSpacing.md),
        FloatingActionButton(
          onPressed: isLoading ? null : _logout,
          heroTag: 'logout',
          backgroundColor: AppColors.error,
          child: const Icon(Icons.logout_outlined),
        ),
      ],
    );
  }

  Future<bool> _ensurePermission(ImageSource source) async {
    final Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      if (Platform.isAndroid) {
        final statusPhotos = await Permission.photos.request();
        if (statusPhotos.isGranted) return true;
        final statusStorage = await Permission.storage.request();
        if (statusStorage.isGranted) return true;

        if (statusPhotos.isPermanentlyDenied ||
            statusStorage.isPermanentlyDenied ||
            statusPhotos.isRestricted) {
          _showSnackBar(
            'Habilita el permiso de galería en Ajustes para continuar.',
            isError: true,
          );
          await openAppSettings();
        }
        return false;
      } else {
        // iOS: solicitar lectura y, si aplica, escritura
        final statusPhotos = await Permission.photos.request();
        if (statusPhotos.isGranted) return true;
        final statusAddOnly = await Permission.photosAddOnly.request();
        if (statusAddOnly.isGranted) return true;

        if (statusPhotos.isPermanentlyDenied ||
            statusAddOnly.isPermanentlyDenied ||
            statusPhotos.isRestricted) {
          _showSnackBar(
            'Habilita el permiso de fotos en Ajustes para continuar.',
            isError: true,
          );
          await openAppSettings();
        }
        return false;
      }
    }

    final status = await permission.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showSnackBar(
        'Habilita el permiso desde Ajustes para continuar.',
        isError: true,
      );
      await openAppSettings();
    }
    return false;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
    });

    try {
      final hasPermission = await _ensurePermission(source);
      if (!hasPermission) return;

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _photoBase64 = base64Image;
        _previewPhotoBytes = bytes;
        _photoUrlController.clear();
      });
    } catch (_) {
      _showSnackBar(
        'No se pudo cargar la imagen de perfil. Intenta nuevamente.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _updateProfile() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final uid = authState.user.uid;
    final profile = _currentProfile;
    if (profile?.microfinancieraId == null || profile?.membershipId == null) {
      _showSnackBar(
        'No se encontró la microfinanciera asociada al usuario.',
        isError: true,
      );
      return;
    }

    // Verificar DNI duplicado solo si cambió
    final newDni = _dniController.text.trim();
    if (newDni.isNotEmpty && newDni != _currentProfile?.dni) {
      // Aquí podrías agregar un evento separado para verificar DNI
      // Por simplicidad, continuamos con la actualización
    }

    final updates = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'fullName':
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      'dni': newDni.isNotEmpty ? newDni : null,
      'phone': _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      'photoUrl': _photoUrlController.text.trim().isNotEmpty
          ? _photoUrlController.text.trim()
          : null,
    };
    if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      updates['photoBase64'] = _photoBase64;
      updates['fotoBase64'] = _photoBase64;
    }

    // Disparar evento BLoC
    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(
        uid: uid,
        microfinancieraId: profile!.microfinancieraId!,
        membershipId: profile.membershipId!,
        customerId: profile.customerId,
        updates: updates,
      ),
    );
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      if (_currentProfile != null) {
        _populateControllers(_currentProfile!);
      } else {
        _photoBase64 = null;
        _previewPhotoBytes = null;
      }
    });
  }

  void _logout() {
    // Disparar evento BLoC de logout
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  // ============== UI Helpers ==============

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}
