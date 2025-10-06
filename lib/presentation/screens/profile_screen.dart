import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  UserProfile? _currentProfile;
  bool _isEditing = false;

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
  }

  @override
  Widget build(BuildContext context) {
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
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.surfaceGradient,
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isCompact =
                        constraints.maxWidth <= AppSpacing.mobileBreakpoint;
                    final double horizontalPadding = isCompact
                        ? AppSpacing.md
                        : AppSpacing.screenPadding;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          // Header profesional con avatar y stats
                          _buildProfileHeader(),
                          const SizedBox(height: AppSpacing.xl),

                          // Información personal en cards elegantes
                          if (_isEditing)
                            _buildEditForm(isLoading: isLoading)
                          else
                            _buildProfileSections(),

                          const SizedBox(height: AppSpacing.xxxl),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Avatar con indicador de estado
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                  backgroundImage:
                      _currentProfile?.photoUrl != null &&
                          _currentProfile!.photoUrl!.isNotEmpty
                      ? NetworkImage(_currentProfile!.photoUrl!)
                      : null,
                  child:
                      _currentProfile?.photoUrl == null ||
                          _currentProfile!.photoUrl!.isEmpty
                      ? Text(
                          _currentProfile?.firstName.isNotEmpty == true
                              ? _currentProfile!.firstName[0].toUpperCase()
                              : 'U',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nombre completo
            Text(
              _currentProfile?.fullName ?? 'Usuario',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),

            // Email con icono
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  color: AppColors.onPrimary.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    _currentProfile?.email ?? '',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Stats row
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Años', '2+', Icons.calendar_today_outlined),
          _buildVerticalDivider(),
          _buildStatItem(
            'Préstamos',
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
    return Column(
      children: [
        Icon(icon, color: AppColors.onPrimary.withValues(alpha: 0.9), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.onPrimary.withValues(alpha: 0.3),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.1),
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
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.onSurface,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEmpty
                  ? AppColors.outline.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isEmpty ? AppColors.onSurfaceVariant : AppColors.primary,
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
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isEmpty
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.1),
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
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.onSurfaceVariant,
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
              ),
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

  // ============== BLoC Event Handlers ==============

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
    setState(() => _isEditing = false);
    if (_currentProfile != null) {
      _populateControllers(_currentProfile!);
    }
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
