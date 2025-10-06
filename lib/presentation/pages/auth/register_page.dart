import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../components/app_card.dart';
import '../../components/primary_button.dart';
import '../../components/text_field_outlined.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'login_page.dart';
import 'role_utils.dart';
import '../../../domain/entities/microfinanciera.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.selectedMicrofinanciera,
    this.availableMicrofinancieras = const [],
  });

  final Microfinanciera? selectedMicrofinanciera;
  final List<Microfinanciera> availableMicrofinancieras;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptTerms = false;

  List<Microfinanciera> _microfinancieras = [];
  Microfinanciera? _selectedMicrofinanciera;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.availableMicrofinancieras.isNotEmpty) {
      _microfinancieras = widget.availableMicrofinancieras;
      _selectedMicrofinanciera = widget.selectedMicrofinanciera;
    } else {
      _loadMicrofinancieras();
    }
  }

  Future<void> _loadMicrofinancieras() async {
    if (!mounted) return;
    context.read<AuthBloc>().add(const AuthLoadMicrofinancierasRequested());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showErrorSnackBar(state.message);
        } else if (state is AuthRegistrationSuccess ||
            state is AuthAuthenticated) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (state is AuthMicrofinancierasLoading) {
          setState(() {
            _microfinancieras = const [];
            _selectedMicrofinanciera = null;
          });
        } else if (state is AuthMicrofinancierasLoaded) {
          setState(() {
            _microfinancieras = state.microfinancieras;
            // Auto-select if there's only one
            if (state.microfinancieras.length == 1) {
              _selectedMicrofinanciera = state.microfinancieras.first;
            }
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.surfaceGradient,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isVerySmall = constraints.maxWidth <= 360;
                  final bool isCompact =
                      constraints.maxWidth <= AppSpacing.mobileBreakpoint;
                  final bool isTablet =
                      constraints.maxWidth > AppSpacing.tabletBreakpoint;

                  final double maxWidth = isTablet ? 520 : constraints.maxWidth;
                  final double horizontalPadding = isVerySmall
                      ? AppSpacing.xs
                      : (isCompact ? AppSpacing.sm : AppSpacing.screenPadding);

                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: AppSpacing.lg,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBrandSection(isCompact: isVerySmall),
                            SizedBox(
                              height: isVerySmall
                                  ? AppSpacing.lg
                                  : AppSpacing.xl,
                            ),
                            _buildWelcomeSection(isCompact: isVerySmall),
                            SizedBox(
                              height: isVerySmall
                                  ? AppSpacing.lg
                                  : AppSpacing.sectionSpacing,
                            ),
                            _buildRegisterForm(isLoading),
                            const SizedBox(height: AppSpacing.sectionSpacing),
                            _buildSignInPrompt(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandSection({bool isCompact = false}) {
    if (isCompact) {
      return Column(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance,
              color: AppColors.onPrimary,
              size: isCompact ? 28 : 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              Text(
                'Microfinance',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Gestión financiera inteligente',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance,
            color: AppColors.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Microfinance',
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Gestión financiera inteligente',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection({bool isCompact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Crea tu cuenta',
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: 360,
          child: Text(
            'Te ayudará a administrar tus finanzas de manera eficiente y segura, con acceso a productos y servicios personalizados.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMicrofinancieraSelector() {
    if (_microfinancieras.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Microfinanciera',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppSpacing.md),
                Text('Cargando microfinancieras...'),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Microfinanciera',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<Microfinanciera>(
          value: _selectedMicrofinanciera,
          decoration: InputDecoration(
            hintText: 'Selecciona una microfinanciera',
            prefixIcon: const Icon(Icons.business_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          items: _microfinancieras.map((microfinanciera) {
            return DropdownMenuItem<Microfinanciera>(
              value: microfinanciera,
              child: Text(
                microfinanciera.name,
                style: AppTypography.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: (microfinanciera) {
            setState(() {
              _selectedMicrofinanciera = microfinanciera;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor selecciona una microfinanciera';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de Microfinanciera
            _buildMicrofinancieraSelector(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextFieldOutlined(
                    controller: _firstNameController,
                    label: 'Nombre',
                    autofillHints: const [AutofillHints.givenName],
                    textInputAction: TextInputAction.next,
                    validator: _validateRequired,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFieldOutlined(
                    controller: _lastNameController,
                    label: 'Apellido',
                    autofillHints: const [AutofillHints.familyName],
                    textInputAction: TextInputAction.next,
                    validator: _validateRequired,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFieldOutlined(
              controller: _dniController,
              label: 'Documento de Identidad',
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: _validateDni,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFieldOutlined(
              controller: _phoneController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _validatePhone,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFieldOutlined(
              controller: _emailController,
              label: 'Correo electrónico',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFieldOutlined(
              controller: _passwordController,
              label: 'Contraseña',
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validatePassword,
              onFieldSubmitted: (_) => _registerWithEmail(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() => _acceptTerms = value ?? false);
                        },
                ),
                Expanded(
                  child: Text(
                    'Acepto los términos y condiciones y declaro que la información proporcionada es correcta.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'Crear cuenta',
              onPressed: isLoading ? null : _registerWithEmail,
              isLoading: isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'Continuar con Google',
              icon: Icons.g_mobiledata,
              onPressed: isLoading ? null : _signUpWithGoogle,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _signUpWithFacebook,
              icon: const Icon(Icons.facebook_outlined),
              label: const Text('Continuar con Facebook'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.minButtonHeight),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          child: const Text('Inicia sesión'),
        ),
      ],
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Correo inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateDni(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu DNI/NIE';
    }
    final cleanValue = value.trim();
    if (cleanValue.length < 8 || cleanValue.length > 12) {
      return 'DNI debe tener entre 8 y 12 caracteres';
    }
    if (!RegExp(
      r'^[0-9XYZ]+[A-Z]?$',
      caseSensitive: false,
    ).hasMatch(cleanValue)) {
      return 'Formato de DNI inválido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu teléfono';
    }
    final cleanValue = value.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanValue.length < 9 || cleanValue.length > 15) {
      return 'Teléfono debe tener entre 9 y 15 dígitos';
    }
    return null;
  }

  void _registerWithEmail() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        _showErrorSnackBar('Debes aceptar los términos y condiciones.');
      }
      return;
    }

    if (_selectedMicrofinanciera == null) {
      _showErrorSnackBar('Por favor selecciona una microfinanciera');
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dni: _dniController.text.trim(),
        phone: _phoneController.text.trim(),
        microfinancieraId: _selectedMicrofinanciera!.id,
        roles: resolveDefaultRolesForMicrofinanciera(
          _selectedMicrofinanciera,
        ),
      ),
    );
  }

  void _signUpWithGoogle() {
    if (_selectedMicrofinanciera == null) {
      _showErrorSnackBar('Por favor selecciona una microfinanciera');
      return;
    }

    context.read<AuthBloc>().add(
      AuthGoogleSignInRequested(
        microfinancieraId: _selectedMicrofinanciera!.id,
        roles: resolveDefaultRolesForMicrofinanciera(
          _selectedMicrofinanciera,
        ),
      ),
    );
  }

  void _signUpWithFacebook() {
    context.read<AuthBloc>().add(const AuthFacebookSignInRequested());
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: AppColors.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
