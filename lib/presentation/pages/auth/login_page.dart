import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../splash/splash_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showErrorSnackBar(state.message);
        } else if (state is AuthAuthenticated) {
          // Navegar al main screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SplashPage()),
          );
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
                    final bool isVerySmall = constraints.maxWidth <= 360;
                    final bool isCompact =
                        constraints.maxWidth <= AppSpacing.mobileBreakpoint;
                    final bool isTablet =
                        constraints.maxWidth > AppSpacing.tabletBreakpoint;

                    final double maxWidth = isTablet
                        ? 450
                        : (isVerySmall
                              ? constraints.maxWidth - 32
                              : constraints.maxWidth * 0.9);

                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? AppSpacing.md : AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBrandSection(isCompact: isVerySmall),
                              if (!isVerySmall)
                                const SizedBox(height: AppSpacing.xl),
                              _buildWelcomeSection(isCompact: isVerySmall),
                              const SizedBox(height: AppSpacing.xxxl),

                              // Formulario principal
                              _buildLoginForm(isLoading: isLoading),
                              const SizedBox(height: AppSpacing.lg),
                              _buildSignUpPrompt(),
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
    if (isCompact) {
      // Layout vertical para pantallas muy pequeñas
      return Column(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
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

    // Layout horizontal para pantallas normales
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
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance,
            color: AppColors.onPrimary,
            size: 40,
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

  Widget _buildLoginForm({required bool isLoading}) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            TextFieldOutlined(
              label: 'Email',
              hint: 'Ingresa tu email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Password
            TextFieldOutlined(
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              controller: _passwordController,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outlined),
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.md),

            // Remember me & Forgot password
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

            // Login button
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

        // Google button
        OutlinedButton.icon(
          onPressed: isLoading ? null : _signInWithGoogle,
          icon: const Icon(Icons.login, color: Colors.red),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.red),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Facebook button
        OutlinedButton.icon(
          onPressed: isLoading ? null : _signInWithFacebook,
          icon: const Icon(Icons.facebook, color: Colors.blue),
          label: const Text('Continuar con Facebook'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.blue),
          ),
        ),
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

  // ============== BLoC Event Handlers ==============

  void _signInWithEmail() {
    if (!_formKey.currentState!.validate()) return;

    // Disparar evento BLoC
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _signInWithGoogle() {
    // Disparar evento BLoC
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  void _signInWithFacebook() {
    // Disparar evento BLoC
    context.read<AuthBloc>().add(const AuthFacebookSignInRequested());
  }

  // ============== Navigation ==============

  void _navigateToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RegisterPage()));
  }

  // ============== Validation ==============

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
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // ============== UI Helpers ==============

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
