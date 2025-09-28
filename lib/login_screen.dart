import 'package:flutter/material.dart';

import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isLoginMode ? '¡Bienvenido de nuevo!' : 'Crea tu cuenta';
    final subtitle = _isLoginMode
        ? 'Ingresa tus datos de acceso.'
        : 'Completa tus datos personales para registrarte.';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E6), Colors.white],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompactHeight = constraints.maxHeight < 720;
              final bool isVeryCompactHeight = constraints.maxHeight < 640;
              final bool isNarrowWidth = constraints.maxWidth < 380;

              final double horizontalPadding = isNarrowWidth ? 16 : 24;
              final double verticalPadding = isVeryCompactHeight
                  ? 12
                  : (isCompactHeight ? 20 : 32);
              final double brandSpacing = isVeryCompactHeight
                  ? 20
                  : (isCompactHeight ? 28 : 40);
              final double subtitleSpacing = isVeryCompactHeight ? 6 : 8;
              final double sectionSpacing = isVeryCompactHeight
                  ? 20
                  : (isCompactHeight ? 24 : 32);
              final double fieldSpacing = isVeryCompactHeight
                  ? 12
                  : (isCompactHeight ? 14 : 16);
              final EdgeInsets cardPadding = EdgeInsets.fromLTRB(
                isVeryCompactHeight ? 18 : (isCompactHeight ? 20 : 24),
                isVeryCompactHeight ? 20 : (isCompactHeight ? 24 : 28),
                isVeryCompactHeight ? 18 : (isCompactHeight ? 20 : 24),
                isVeryCompactHeight ? 20 : (isCompactHeight ? 24 : 32),
              );

              final double contentWidth = constraints.maxWidth > 500
                  ? 450
                  : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBrand(theme),
                        SizedBox(height: brandSpacing),
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: subtitleSpacing),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: sectionSpacing),
                        _buildFormCard(
                          theme,
                          cardPadding: cardPadding,
                          sectionSpacing: sectionSpacing,
                          fieldSpacing: fieldSpacing,
                          stackNameFields: isNarrowWidth,
                        ),
                        SizedBox(height: sectionSpacing),
                        _buildModeSwitcher(theme),
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
  }

  Widget _buildBrand(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8C00),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Microfinance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Plataforma de gestión financiera',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(
    ThemeData theme, {
    required EdgeInsets cardPadding,
    required double sectionSpacing,
    required double fieldSpacing,
    required bool stackNameFields,
  }) {
    final formKey = _isLoginMode ? _loginFormKey : _registerFormKey;

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: cardPadding,
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSocialButtons(),
              SizedBox(height: sectionSpacing),
              _buildDivider(),
              SizedBox(height: sectionSpacing),
              if (_isLoginMode)
                ..._buildLoginFields(theme, fieldSpacing)
              else
                ..._buildRegisterFields(
                  theme,
                  fieldSpacing: fieldSpacing,
                  stackNameFields: stackNameFields,
                ),
              SizedBox(height: sectionSpacing),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _isLoginMode
                            ? _signInWithEmail()
                            : _registerWithEmail(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: const Color(0xFFFF8C00),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLoginMode ? 'Iniciar sesión' : 'Registrarme',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoginFields(ThemeData theme, double fieldSpacing) {
    final double helperSpacing = fieldSpacing * 0.75;

    return [
      _labeledField(
        label: 'Correo electrónico',
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('Correo electrónico'),
          validator: _validateEmail,
        ),
      ),
      SizedBox(height: fieldSpacing),
      _labeledField(
        label: 'Contraseña',
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscureLoginPassword,
          decoration: _inputDecoration('Contraseña').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.black45,
              ),
              onPressed: () => setState(
                () => _obscureLoginPassword = !_obscureLoginPassword,
              ),
            ),
          ),
          validator: _validateRequired,
        ),
      ),
      SizedBox(height: helperSpacing),
      Row(
        children: [
          Checkbox(
            value: _rememberMe,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (value) => setState(() => _rememberMe = value ?? false),
          ),
          const Text('Recordarme'),
          const Spacer(),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => _showInfo(
                    'La recuperación de contraseña estará disponible pronto.',
                  ),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildRegisterFields(
    ThemeData theme, {
    required double fieldSpacing,
    required bool stackNameFields,
  }) {
    final double helperSpacing = fieldSpacing * 0.6;

    final Widget firstNameField = _labeledField(
      label: 'Nombre',
      child: TextFormField(
        controller: _firstNameController,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration('Nombre'),
        validator: (value) => _validateName(value, 'nombre'),
      ),
    );

    final Widget lastNameField = _labeledField(
      label: 'Apellido',
      child: TextFormField(
        controller: _lastNameController,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration('Apellido'),
        validator: (value) => _validateName(value, 'apellido'),
      ),
    );

    return [
      if (stackNameFields) ...[
        firstNameField,
        SizedBox(height: fieldSpacing),
        lastNameField,
      ] else
        Row(
          children: [
            Expanded(child: firstNameField),
            SizedBox(width: fieldSpacing),
            Expanded(child: lastNameField),
          ],
        ),
      SizedBox(height: fieldSpacing),
      _labeledField(
        label: 'DNI/NIE',
        child: TextFormField(
          controller: _dniController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('DNI/NIE'),
          validator: _validateDni,
        ),
      ),
      SizedBox(height: fieldSpacing),
      _labeledField(
        label: 'Teléfono',
        child: TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('Teléfono'),
          validator: _validatePhone,
        ),
      ),
      SizedBox(height: fieldSpacing),
      _labeledField(
        label: 'Correo electrónico',
        child: TextFormField(
          controller: _regEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('Correo electrónico'),
          validator: _validateEmail,
        ),
      ),
      SizedBox(height: fieldSpacing),
      _labeledField(
        label: 'Contraseña',
        child: TextFormField(
          controller: _regPasswordController,
          obscureText: _obscureRegisterPassword,
          decoration: _inputDecoration('Contraseña').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegisterPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.black45,
              ),
              onPressed: () => setState(
                () => _obscureRegisterPassword = !_obscureRegisterPassword,
              ),
            ),
          ),
          validator: _validatePassword,
        ),
      ),
      SizedBox(height: helperSpacing),
      Text(
        'Debe contener al menos 6 caracteres.',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
      ),
    ];
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF8C00)),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('O'),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _socialButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            label: 'Google',
            icon: Image.asset(
              'assets/google_logo.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.g_mobiledata, color: Colors.red);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _socialButton(
            onPressed: _isLoading ? null : _signInWithFacebook,
            label: 'Facebook',
            icon: const Icon(Icons.facebook, color: Colors.white, size: 20),
            backgroundColor: const Color(0xFF1877F2),
            borderColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required VoidCallback? onPressed,
    required String label,
    required Widget icon,
    Color? backgroundColor,
    Color? borderColor,
    Color? foregroundColor,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: backgroundColor ?? Colors.white,
        foregroundColor: foregroundColor ?? Colors.black87,
        side: BorderSide(color: borderColor ?? const Color(0xFFE0E0E0)),
      ),
      icon: icon,
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? Colors.black87,
        ),
      ),
    );
  }

  Widget _buildModeSwitcher(ThemeData theme) {
    final question = _isLoginMode
        ? '¿No tienes cuenta? '
        : '¿Ya tienes cuenta? ';
    final action = _isLoginMode ? 'Regístrate' : 'Inicia sesión';

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(() => _isLoginMode = !_isLoginMode);
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    if (!value.contains('@')) {
      return 'Ingresa un correo electrónico válido';
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

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu $fieldName';
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
    if (!RegExp(r'^[0-9]+[A-Z]?$').hasMatch(cleanValue)) {
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

  Future<void> _signInWithEmail() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (credential != null && mounted) {
        // El AuthWrapper automáticamente detectará el cambio de estado
        // y navegará a MainScreen
      }
    } catch (e) {
      if (mounted) {
        _showInfo('Error al iniciar sesión: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithEmail() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmailAndPassword(
        email: _regEmailController.text.trim(),
        password: _regPasswordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dni: _dniController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        // El AuthWrapper automáticamente detectará el cambio de estado
        // y navegará a MainScreen
      }
    } catch (e) {
      if (mounted) {
        _showInfo('Error al registrarse: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithGoogle();

      if (credential != null && mounted) {
        // El AuthWrapper automáticamente detectará el cambio de estado
        // y navegará a MainScreen
      }
    } catch (e) {
      if (mounted) {
        _showInfo('Error al iniciar sesión con Google: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithFacebook();

      if (credential != null && mounted) {
        // El AuthWrapper automáticamente detectará el cambio de estado
        // y navegará a MainScreen
      }
    } catch (e) {
      if (mounted) {
        _showInfo('Error al iniciar sesión con Facebook: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInfo(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.black87,
      ),
    );
  }
}
