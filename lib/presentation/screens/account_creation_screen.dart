import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/account/create_account_usecase.dart';
import '../bloc/account/account_bloc.dart';
import '../bloc/account/account_event.dart';
import '../bloc/account/account_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/profile/profile_bloc.dart';

class AccountCreationScreen extends StatefulWidget {
  final String userId;
  final String microfinancieraId;
  final List<Account> existingAccounts;

  const AccountCreationScreen({
    super.key,
    required this.userId,
    required this.microfinancieraId,
    required this.existingAccounts,
  });

  @override
  State<AccountCreationScreen> createState() => _AccountCreationScreenState();
}

class _AccountCreationScreenState extends State<AccountCreationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Controladores para todos los campos
  final _accountTypeController = TextEditingController();
  final _currencyController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _departmentController = TextEditingController();
  final _employerController = TextEditingController();
  final _positionController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _initialDepositController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _commentsController = TextEditingController();

  // Variables de estado
  AccountType _selectedAccountType = AccountType.savings;
  String _selectedCurrency = 'PEN';
  EmploymentType _selectedEmploymentType = EmploymentType.employed;
  bool _hasCreditHistory = false;
  bool _hasBankAccount = false;
  bool _hasUnsavedChanges = false;
  bool _showValidationErrors = false;

  @override
  void dispose() {
    _pageController.dispose();
    _accountTypeController.dispose();
    _currencyController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _departmentController.dispose();
    _employerController.dispose();
    _positionController.dispose();
    _monthlyIncomeController.dispose();
    _initialDepositController.dispose();
    _bankNameController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  // Métodos para validación de tipos de cuenta
  Set<AccountType> get _existingAccountTypes {
    return widget.existingAccounts
        .map((account) => account.accountType)
        .toSet();
  }

  List<AccountType> get _availableAccountTypes {
    return AccountType.values
        .where((type) => !_existingAccountTypes.contains(type))
        .toList();
  }

  bool _isAccountTypeAvailable(AccountType type) {
    return !_existingAccountTypes.contains(type);
  }

  @override
  void initState() {
    super.initState();
    if (_availableAccountTypes.isNotEmpty) {
      _selectedAccountType = _availableAccountTypes.first;
    }

    _populateUserData();

    _addChangeListeners();
  }

  void _addChangeListeners() {
    final controllers = [
      _accountTypeController,
      _currencyController,
      _firstNameController,
      _lastNameController,
      _dniController,
      _phoneController,
      _emailController,
      _addressController,
      _districtController,
      _provinceController,
      _departmentController,
      _employerController,
      _positionController,
      _monthlyIncomeController,
      _initialDepositController,
      _bankNameController,
      _commentsController,
    ];

    for (final controller in controllers) {
      controller.addListener(() {
        setState(() {
          if (!_hasUnsavedChanges) {
            _hasUnsavedChanges = true;
          }
        });
      });
    }
  }

  void _populateUserData() {
    final authState = context.read<AuthBloc>().state;
    final profileState = context.read<ProfileBloc>().state;

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final profile = profileState.profile;

      if (profile != null) {
        if (profile.firstName.isNotEmpty) {
          _firstNameController.text = profile.firstName;
        }
        if (profile.lastName.isNotEmpty) {
          _lastNameController.text = profile.lastName;
        }
        if (profile.dni != null && profile.dni!.isNotEmpty) {
          _dniController.text = profile.dni!;
        }
        if (profile.phone != null && profile.phone!.isNotEmpty) {
          _phoneController.text = profile.phone!;
        }
      }

      if (user.email != null && user.email!.isNotEmpty) {
        _emailController.text = user.email!;
      }
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _availableAccountTypes.isNotEmpty;
      case 1:
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _dniController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _isValidEmail(_emailController.text);
      case 2:
        return _addressController.text.isNotEmpty &&
            _districtController.text.isNotEmpty &&
            _provinceController.text.isNotEmpty &&
            _departmentController.text.isNotEmpty &&
            _employerController.text.isNotEmpty &&
            _positionController.text.isNotEmpty &&
            _monthlyIncomeController.text.isNotEmpty &&
            _isValidAmount(_monthlyIncomeController.text);
      case 3:
        return _initialDepositController.text.isNotEmpty &&
            _isValidAmount(_initialDepositController.text);
      case 4:
        return true;
      default:
        return false;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    if (!_isValidEmail(value)) {
      return 'Ingresa un correo electrónico válido (ejemplo@correo.com)';
    }
    return null;
  }

  bool _isValidAmount(String amount) {
    if (amount.isEmpty) return false;
    final value = double.tryParse(amount);
    return value != null && value > 0;
  }

  String? _validateAmount(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es obligatorio';
    }
    final numericValue = double.tryParse(value);
    if (numericValue == null) {
      return 'Ingresa solo números (ejemplo: 1500.50)';
    }
    if (numericValue <= 0) {
      return '$fieldName debe ser mayor a 0';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    if (value.length < 9) {
      return 'El teléfono debe tener al menos 9 dígitos';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'El teléfono solo debe contener números';
    }
    return null;
  }

  String? _validateDNI(String? value) {
    if (value == null || value.isEmpty) {
      return 'El DNI es obligatorio';
    }
    if (value.length != 8) {
      return 'El DNI debe tener exactamente 8 dígitos';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'El DNI solo debe contener números';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es obligatorio';
    }
    if (value.length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return '$fieldName solo debe contener letras';
    }
    return null;
  }

  void _showValidationError() {
    String message = '';
    switch (_currentStep) {
      case 0:
        message = 'No hay tipos de cuenta disponibles para crear';
        break;
      case 1:
        message =
            'Por favor completa todos los campos de información personal y de contacto';
        break;
      case 2:
        message =
            'Por favor completa todos los campos de dirección e información laboral';
        break;
      case 3:
        message =
            'Por favor completa todos los campos financieros con montos válidos';
        break;
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text(
          'Tienes cambios sin guardar. Si sales ahora, perderás toda la información ingresada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1 && _canProceedToNextStep()) {
      setState(() {
        _currentStep++;
        _showValidationErrors = false;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (!_canProceedToNextStep()) {
      setState(() {
        _showValidationErrors = true;
      });
      _showValidationError();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitForm() {
    final params = CreateAccountParams(
      userId: widget.userId,
      microfinancieraId: widget.microfinancieraId,
      accountType: _selectedAccountType,
      currency: _selectedCurrency,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      dni: _dniController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      district: _districtController.text,
      province: _provinceController.text,
      department: _departmentController.text,
      employmentType: _selectedEmploymentType,
      employer: _employerController.text.isNotEmpty
          ? _employerController.text
          : null,
      position: _positionController.text.isNotEmpty
          ? _positionController.text
          : null,
      monthlyIncome: double.tryParse(_monthlyIncomeController.text),
      initialDeposit: double.tryParse(_initialDepositController.text),
      hasCreditHistory: _hasCreditHistory,
      hasBankAccount: _hasBankAccount,
      bankName: _bankNameController.text.isNotEmpty
          ? _bankNameController.text
          : null,
      comments: _commentsController.text.isNotEmpty
          ? _commentsController.text
          : null,
    );

    context.read<AccountBloc>().add(AccountCreate(params));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crear Nueva Cuenta'),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: BlocListener<AccountBloc, AccountState>(
          listener: (context, state) {
            if (state is AccountCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cuenta creada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true);
            } else if (state is AccountError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paso ${_currentStep + 1} de $_totalSteps',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAccountTypeStep(),
                    _buildPersonalInfoStep(),
                    _buildAddressStep(),
                    _buildFinancialInfoStep(),
                    _buildReviewStep(),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      ElevatedButton(
                        onPressed: _previousStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Anterior'),
                      )
                    else
                      const SizedBox.shrink(),
                    BlocBuilder<AccountBloc, AccountState>(
                      builder: (context, state) {
                        final isLoading = state is AccountLoading;

                        if (_currentStep == _totalSteps - 1) {
                          return ElevatedButton(
                            onPressed: isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Crear Cuenta'),
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: _canProceedToNextStep()
                                ? _nextStep
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canProceedToNextStep()
                                  ? const Color(0xFF1E88E5)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Siguiente'),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Cuenta',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona el tipo de cuenta que deseas crear',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (_availableAccountTypes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ya tienes todos los tipos de cuenta disponibles.',
                style: TextStyle(color: Colors.orange),
              ),
            )
          else
            ..._availableAccountTypes.map(
              (type) => _buildAccountTypeOption(type),
            ),
          const SizedBox(height: 24),
          const Text(
            'Moneda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: const InputDecoration(
              labelText: 'Seleccionar moneda',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'PEN', child: Text('Soles (PEN)')),
              DropdownMenuItem(value: 'USD', child: Text('Dólares (USD)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCurrency = value;
                  _hasUnsavedChanges = true;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeOption(AccountType type) {
    final isSelected = _selectedAccountType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAccountType = type;
            _hasUnsavedChanges = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? const Color(0xFF1E88E5).withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              Icon(
                _getAccountTypeIcon(type),
                color: isSelected ? const Color(0xFF1E88E5) : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getAccountTypeName(type),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF1E88E5)
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAccountTypeDescription(type),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF1E88E5)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Icons.savings;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.fixedDeposit:
        return Icons.lock;
      case AccountType.microCredit:
        return Icons.monetization_on;
    }
  }

  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return 'Cuenta de Ahorros';
      case AccountType.checking:
        return 'Cuenta Corriente';
      case AccountType.fixedDeposit:
        return 'Depósito a Plazo Fijo';
      case AccountType.microCredit:
        return 'Cuenta de Microcrédito';
    }
  }

  String _getAccountTypeDescription(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return 'Para ahorrar dinero con intereses';
      case AccountType.checking:
        return 'Para transacciones diarias';
      case AccountType.fixedDeposit:
        return 'Inversión a plazo fijo con mayor rendimiento';
      case AccountType.microCredit:
        return 'Para solicitar microcréditos';
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tu información personal y de contacto',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Nombres *',
              border: const OutlineInputBorder(),
              helperText: 'Solo letras permitidas',
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorText:
                  _showValidationErrors && _firstNameController.text.isEmpty
                  ? 'Este campo es obligatorio'
                  : null,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
              ),
            ],
            validator: (value) => _validateName(value, 'Nombres'),
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Apellidos *',
              border: const OutlineInputBorder(),
              helperText: 'Solo letras permitidas',
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorText:
                  _showValidationErrors && _lastNameController.text.isEmpty
                  ? 'Este campo es obligatorio'
                  : null,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
              ),
            ],
            validator: (value) => _validateName(value, 'Apellidos'),
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dniController,
            decoration: InputDecoration(
              labelText: 'DNI *',
              border: const OutlineInputBorder(),
              helperText: 'Debe tener exactamente 8 dígitos',
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorText: _showValidationErrors && _dniController.text.isEmpty
                  ? 'Este campo es obligatorio'
                  : null,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: _validateDNI,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 32),
          const Text(
            'Información de Contacto',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Teléfono *',
              border: const OutlineInputBorder(),
              helperText: 'Solo números, mínimo 9 dígitos',
              prefixText: '+51 ',
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorText: _showValidationErrors && _phoneController.text.isEmpty
                  ? 'Este campo es obligatorio'
                  : null,
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            validator: _validatePhone,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico *',
              border: const OutlineInputBorder(),
              helperText: 'Formato: ejemplo@correo.com',
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorText: _showValidationErrors && _emailController.text.isEmpty
                  ? 'Este campo es obligatorio'
                  : null,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dirección',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tu dirección completa e información laboral',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Dirección *',
              border: const OutlineInputBorder(),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorText:
                  _showValidationErrors && _addressController.text.isEmpty
                  ? 'Este campo es obligatorio'
                  : null,
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _districtController,
            decoration: const InputDecoration(
              labelText: 'Distrito *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _provinceController,
            decoration: const InputDecoration(
              labelText: 'Provincia *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(
              labelText: 'Departamento *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Información Laboral',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<EmploymentType>(
            value: _selectedEmploymentType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Empleo *',
              border: OutlineInputBorder(),
            ),
            items: EmploymentType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getEmploymentTypeName(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedEmploymentType = value;
                  _hasUnsavedChanges = true;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _employerController,
            decoration: const InputDecoration(
              labelText: 'Empleador *',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _positionController,
            decoration: const InputDecoration(
              labelText: 'Cargo *',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.work),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _monthlyIncomeController,
            decoration: const InputDecoration(
              labelText: 'Ingresos Mensuales *',
              border: OutlineInputBorder(),
              prefixText: 'S/ ',
              helperText: 'Solo números y decimales (ej: 1500.50)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) => _validateAmount(value, 'Ingresos mensuales'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  String _getEmploymentTypeName(EmploymentType type) {
    switch (type) {
      case EmploymentType.employed:
        return 'Empleado';
      case EmploymentType.selfEmployed:
        return 'Trabajador Independiente';
      case EmploymentType.unemployed:
        return 'Desempleado';
      case EmploymentType.retired:
        return 'Jubilado';
      case EmploymentType.student:
        return 'Estudiante';
      case EmploymentType.business:
        return 'Empresario';
    }
  }

  Widget _buildFinancialInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Financiera',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Información adicional sobre tu situación financiera',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('¿Tienes historial crediticio?'),
            value: _hasCreditHistory,
            onChanged: (value) {
              setState(() {
                _hasCreditHistory = value;
                _hasUnsavedChanges = true;
              });
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('¿Tienes cuenta bancaria?'),
            value: _hasBankAccount,
            onChanged: (value) {
              setState(() {
                _hasBankAccount = value;
                _hasUnsavedChanges = true;
              });
            },
          ),
          if (_hasBankAccount) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Banco',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _initialDepositController,
            decoration: const InputDecoration(
              labelText: 'Depósito Inicial *',
              border: OutlineInputBorder(),
              prefixText: 'S/ ',
              helperText: 'Solo números y decimales (ej: 100.00)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) => _validateAmount(value, 'Depósito inicial'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _commentsController,
            decoration: const InputDecoration(
              labelText: 'Comentarios adicionales',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revisar Información',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisa toda la información antes de crear la cuenta',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildReviewSection('Tipo de Cuenta', [
            'Tipo: ${_getAccountTypeName(_selectedAccountType)}',
            'Moneda: $_selectedCurrency',
          ]),
          _buildReviewSection('Información Personal', [
            'Nombres: ${_firstNameController.text}',
            'Apellidos: ${_lastNameController.text}',
            'DNI: ${_dniController.text}',
          ]),
          _buildReviewSection('Contacto', [
            'Teléfono: ${_phoneController.text}',
            'Email: ${_emailController.text}',
          ]),
          _buildReviewSection('Dirección', [
            'Dirección: ${_addressController.text}',
            'Distrito: ${_districtController.text}',
            'Provincia: ${_provinceController.text}',
            'Departamento: ${_departmentController.text}',
          ]),
          _buildReviewSection('Información Laboral', [
            'Tipo de Empleo: ${_getEmploymentTypeName(_selectedEmploymentType)}',
            if (_employerController.text.isNotEmpty)
              'Empleador: ${_employerController.text}',
            if (_positionController.text.isNotEmpty)
              'Cargo: ${_positionController.text}',
            'Ingresos Mensuales: S/ ${_monthlyIncomeController.text}',
          ]),
          _buildReviewSection('Información Financiera', [
            'Historial Crediticio: ${_hasCreditHistory ? "Sí" : "No"}',
            'Cuenta Bancaria: ${_hasBankAccount ? "Sí" : "No"}',
            if (_hasBankAccount && _bankNameController.text.isNotEmpty)
              'Banco: ${_bankNameController.text}',
            'Depósito Inicial: S/ ${_initialDepositController.text}',
            if (_commentsController.text.isNotEmpty)
              'Comentarios: ${_commentsController.text}',
          ]),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item),
            ),
          ),
        ],
      ),
    );
  }
}
