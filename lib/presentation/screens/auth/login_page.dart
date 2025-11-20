import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/microfinanciera.dart';
import '../../components/primary_button.dart';
import '../../components/text_field_outlined.dart';
import '../../components/app_card.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'register_page.dart';
import 'role_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Microfinanciera> _microfinancieras = [];
  Microfinanciera? _selectedMicrofinanciera;
  bool _isLoadingMicrofinancieras = false;

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadMicrofinancieras();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadMicrofinancieras() async {
    if (!mounted) return;

    if (_isLoadingMicrofinancieras) return;

    setState(() {
      _isLoadingMicrofinancieras = true;
    });

    try {
      context.read<AuthBloc>().add(const AuthLoadMicrofinancierasRequested());
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMicrofinancieras = false;
        });
        _showErrorSnackBar(
          'Error al cargar microfinancieras. Intenta nuevamente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthMicrofinancierasLoading) {
          setState(() {
            _isLoadingMicrofinancieras = true;
          });
        } else if (state is AuthMicrofinancierasLoaded) {
          setState(() {
            _microfinancieras = state.microfinancieras;
            if (state.microfinancieras.length == 1) {
              _selectedMicrofinanciera = state.microfinancieras.first;
            } else if (_selectedMicrofinanciera != null) {
              final exists = state.microfinancieras.any(
                (mf) => mf.id == _selectedMicrofinanciera!.id,
              );
              if (!exists) {
                _selectedMicrofinanciera = null;
              }
            }
            _isLoadingMicrofinancieras = false;
          });
        } else if (state is AuthError) {
          // Detener loading de microfinancieras si hay error relacionado
          if (state.errorCode == 'microfinancieras_load_error' ||
              state.errorCode == 'login_error' ||
              state.errorCode == 'registration_error') {
            setState(() => _isLoadingMicrofinancieras = false);
          }
          // Mostrar error después de que el frame se complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showErrorSnackBar(state.message);
            }
          });
        } else if (state is AuthAuthenticated || state is AuthPending) {
          // Asegurar que el loading se detenga al autenticarse
          if (_isLoadingMicrofinancieras) {
            setState(() => _isLoadingMicrofinancieras = false);
          }
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (state is AuthUnauthenticated || state is AuthInitial) {
          // Detener loading si vuelve a estado inicial o no autenticado
          if (_isLoadingMicrofinancieras) {
            setState(() => _isLoadingMicrofinancieras = false);
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
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
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;

                    final bool isVerySmall = constraints.maxWidth <= 360;
                    final bool isCompact =
                        constraints.maxWidth <= AppSpacing.mobileBreakpoint;
                    final bool isTablet =
                        constraints.maxWidth > AppSpacing.tabletBreakpoint;

                    final double maxWidth = isTablet
                        ? screenWidth *
                              0.6 // 60% en tablet
                        : (isVerySmall
                              ? screenWidth *
                                    0.9 // 90% en pantallas muy pequeñas
                              : screenWidth * 0.85); // 85% en móviles normales

                    return Center(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: screenWidth * 0.04, // 4% del ancho
                          right: screenWidth * 0.04, // 4% del ancho
                          top: screenHeight * 0.02, // 2% de la altura
                          bottom:
                              screenHeight * 0.02 +
                              MediaQuery.of(context).padding.bottom,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxWidth,
                            minHeight:
                                screenHeight * 0.8, // 80% de la altura mínima
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo removido para optimizar espacio
                              _buildWelcomeSection(isCompact: isVerySmall),
                              SizedBox(
                                height: screenHeight * 0.03,
                              ), // 3% de la altura
                              _buildLoginForm(isLoading: isLoading),
                              SizedBox(
                                height: screenHeight * 0.02,
                              ), // 2% de la altura
                              _buildSignUpPrompt(),
                              SizedBox(
                                height: screenHeight * 0.02,
                              ), // 2% de la altura
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
      ),
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
                  color: AppColors.primary.withValues(alpha: 0.3),
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
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: screenWidth * 0.03, // 3% del ancho
                offset: Offset(0, screenHeight * 0.008), // 0.8% de la altura
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance,
            color: AppColors.onPrimary,
            size: screenWidth * 0.1, // 10% del ancho
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
                fontSize: screenWidth * 0.08, // 8% del ancho
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
    return Column(
      children: [
        Text(
          'Bienvenido',
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Inicia sesión para continuar',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMicrofinancieraSelector() {
    if (_isLoadingMicrofinancieras) {
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
          menuMaxHeight: 200, // Limit dropdown height to prevent overflow
          decoration: InputDecoration(
            hintText: 'Selecciona una microfinanciera',
            prefixIcon: const Icon(Icons.business_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _microfinancieras.map((microfinanciera) {
            return DropdownMenuItem<Microfinanciera>(
              value: microfinanciera,
              child: Text(
                microfinanciera.name,
                style: AppTypography.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (Microfinanciera? microfinanciera) {
            setState(() {
              _selectedMicrofinanciera = microfinanciera;
            });
          },
          validator: (Microfinanciera? value) {
            if (value == null) {
              return 'Por favor selecciona una microfinanciera';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginForm({required bool isLoading}) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMicrofinancieraSelector(),
            const SizedBox(height: AppSpacing.lg),

            TextFieldOutlined(
              label: 'Email',
              hint: 'Ingresa tu email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFieldOutlined(
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              controller: _passwordController,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outlined),
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                ),
                const Text('Recordarme'),
                const Spacer(),
                TextButton(
                  onPressed: _showForgotPasswordInfo,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(
              text: 'Iniciar Sesión',
              onPressed: isLoading ? null : _signInWithEmail,
              isLoading: isLoading,
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildSocialButtons(isLoading: isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButtons({required bool isLoading}) {
    return Column(
      children: [
        _buildDivider(),
        const SizedBox(height: AppSpacing.lg),

        OutlinedButton.icon(
          onPressed: isLoading ? null : _signInWithGoogle,
          icon: const Icon(Icons.login, color: Colors.red),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.red),
          ),
        ),
        // Botón de Facebook removido
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'O continúa con',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: _navigateToRegister,
          child: const Text('Regístrate'),
        ),
      ],
    );
  }

  void _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMicrofinanciera == null) {
      _showErrorSnackBar('Por favor selecciona una microfinanciera');
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        microfinancieraId: _selectedMicrofinanciera!.id,
      ),
    );
  }

  void _signInWithGoogle() {
    if (_selectedMicrofinanciera == null) {
      _showErrorSnackBar('Por favor selecciona una microfinanciera');
      return;
    }

    context.read<AuthBloc>().add(
      AuthGoogleSignInRequested(
        microfinancieraId: _selectedMicrofinanciera!.id,
        roles: resolveDefaultRolesForMicrofinanciera(_selectedMicrofinanciera),
      ),
    );
  }

  void _signInWithFacebook() {
    // Facebook login temporalmente deshabilitado
    _showErrorSnackBar(
      'El inicio de sesión con Facebook estará disponible próximamente',
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterPage(
          selectedMicrofinanciera: _selectedMicrofinanciera,
          availableMicrofinancieras: _microfinancieras,
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    return null;
  }

  void _showForgotPasswordInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La recuperación de contraseña estará disponible próximamente',
        ),
        behavior: SnackBarBehavior.floating,
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
