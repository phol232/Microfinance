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
    try {
      context.read<AuthBloc>().add(const AuthLoadMicrofinancierasRequested());
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al cargar microfinancieras. Intenta nuevamente.');
      }
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          // Detener cualquier estado de loading cuando hay error
          if (state.errorCode == 'microfinancieras_load_error' || 
              state.errorCode == 'login_error' ||
              state.errorCode == 'registration_error') {
            // El estado de microfinancieras se maneja en el builder
          }
          _showErrorSnackBar(state.message);
        } else if (state is AuthRegistrationSuccess ||
            state is AuthAuthenticated) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (state is AuthPending) {
          // El AuthWrapper se encargará de mostrar la página de pending
          // No necesitamos hacer nada aquí, solo asegurar que no navegamos
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
        } else if (state is AuthUnauthenticated || state is AuthInitial) {
          // Resetear estado si vuelve a inicial
          setState(() {
            if (_microfinancieras.isEmpty) {
              _microfinancieras = const [];
              _selectedMicrofinanciera = null;
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

                  final double maxWidth = isTablet
                      ? screenWidth * 0.65
                      : constraints.maxWidth; // 65% del ancho en tablet
                  final double horizontalPadding = isVerySmall
                      ? screenWidth *
                            0.02 // 2% del ancho
                      : (isCompact
                            ? screenWidth * 0.03
                            : screenWidth * 0.05); // 3% o 5% del ancho

                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: screenHeight * 0.015, // Reducido de 3% a 1.5%
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo removido para optimizar espacio
                            _buildWelcomeSection(isCompact: isVerySmall),
                            SizedBox(
                              height: screenHeight * 0.015,
                            ), // Reducido significativamente
                            _buildRegisterForm(isLoading),
                            SizedBox(
                              height: screenHeight * 0.01,
                            ), // Reducido de 2% a 1%
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isCompact) {
      return Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(
                screenWidth * 0.04,
              ), // 4% del ancho
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: screenWidth * 0.02, // 2% del ancho
                  offset: Offset(0, screenHeight * 0.005), // 0.5% de la altura
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance,
              color: AppColors.onPrimary,
              size: screenWidth * 0.07, // 7% del ancho
            ),
          ),
          SizedBox(height: screenHeight * 0.02), // 2% de la altura
          Column(
            children: [
              Text(
                'Microfinance',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: screenWidth * 0.06, // 6% del ancho
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Gestión financiera inteligente',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: screenWidth * 0.035, // 3.5% del ancho
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
          padding: EdgeInsets.all(screenWidth * 0.05), // 5% del ancho
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(
              screenWidth * 0.04,
            ), // 4% del ancho
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: screenWidth * 0.02, // 2% del ancho
                offset: Offset(0, screenHeight * 0.005), // 0.5% de la altura
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance,
            color: AppColors.onPrimary,
            size: screenWidth * 0.08, // 8% del ancho
          ),
        ),
        SizedBox(width: screenWidth * 0.05), // 5% del ancho
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Microfinance',
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: screenWidth * 0.07, // 7% del ancho
              ),
            ),
            Text(
              'Gestión financiera inteligente',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: screenWidth * 0.04, // 4% del ancho
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection({bool isCompact = false}) {
    return Text(
      'Crea tu cuenta',
      style: AppTypography.headlineLarge.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
      textAlign: TextAlign.center,
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
          initialValue: _selectedMicrofinanciera,
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
        horizontal: AppSpacing.md, // Reducido de lg a md
        vertical: AppSpacing.lg, // Reducido de xl a lg
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de Microfinanciera
            _buildMicrofinancieraSelector(),
            const SizedBox(height: AppSpacing.md), // Reducido de lg a md
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
            const SizedBox(height: AppSpacing.sm), // Reducido de md a sm
            TextFieldOutlined(
              controller: _dniController,
              label: 'Documento de Identidad',
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: _validateDni,
            ),
            const SizedBox(height: AppSpacing.sm), // Reducido de md a sm
            TextFieldOutlined(
              controller: _phoneController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _validatePhone,
            ),
            const SizedBox(height: AppSpacing.sm), // Reducido de md a sm
            TextFieldOutlined(
              controller: _emailController,
              label: 'Correo electrónico',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.sm), // Reducido de md a sm
            TextFieldOutlined(
              controller: _passwordController,
              label: 'Contraseña',

              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validatePassword,
              onFieldSubmitted: (_) => _registerWithEmail(),
            ),
            const SizedBox(height: AppSpacing.md), // Reducido de lg a md
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
            const SizedBox(height: AppSpacing.md), // Reducido de lg a md
            PrimaryButton(
              text: 'Crear cuenta',
              onPressed: isLoading ? null : _registerWithEmail,
              isLoading: isLoading,
            ),
            // Botón de Google removido
            // Botón de Facebook removido
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
    if (value.length < 9) {
      return 'La contraseña debe tener al menos 9 caracteres';
    }

    // Verificar que tenga al menos una letra mayúscula
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra mayúscula';
    }

    // Verificar que tenga al menos una letra minúscula
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una letra minúscula';
    }

    // Verificar que tenga al menos un número
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }

    // Verificar que tenga al menos un carácter especial
    if (!RegExp(r'[!@#\$%\^&\*\(\),\.\?":{}|<>]').hasMatch(value)) {
      return 'Debe contener al menos un carácter especial (!@#\$%^&*(),.?":{}|<>)';
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
        roles: resolveDefaultRolesForMicrofinanciera(_selectedMicrofinanciera),
      ),
    );
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
