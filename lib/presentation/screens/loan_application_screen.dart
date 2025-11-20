import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/credit_product.dart';
import '../../domain/entities/loan_application.dart';
import '../../domain/usecases/loan_application/create_loan_application_usecase.dart';
import '../../data/datasources/loan_application_datasource.dart';
import '../../data/repositories/loan_application_repository_impl.dart';
import '../../infrastructure/services/credit_product_service.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/presentation/widgets/location_permission_dialog.dart';
import '../bloc/intake_request/intake_request_bloc.dart';
import '../bloc/intake_request/intake_request_event.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/profile/profile_bloc.dart';

class LoanApplicationScreen extends StatefulWidget {
  final String userId;
  final String microfinancieraId;
  final bool isWithoutAccount;

  const LoanApplicationScreen({
    super.key,
    required this.userId,
    required this.microfinancieraId,
    this.isWithoutAccount = false,
  });

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers para los campos de texto
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _documentNumberController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _mobilePhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _employerNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _monthlyIncomeController =
      TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _loanPurposeController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _cciController = TextEditingController();

  // Nuevos controllers para campos faltantes
  final TextEditingController _landlinePhoneController =
      TextEditingController();
  final TextEditingController _locationReferenceController =
      TextEditingController();
  final TextEditingController _workAddressController = TextEditingController();
  final TextEditingController _workPhoneController = TextEditingController();
  final TextEditingController _monthlyExpensesController =
      TextEditingController();
  final TextEditingController _otherIncomeController = TextEditingController();
  final TextEditingController _currentDebtsController = TextEditingController();
  final TextEditingController _personalReference1NameController =
      TextEditingController();
  final TextEditingController _personalReference1PhoneController =
      TextEditingController();
  final TextEditingController _personalReference2NameController =
      TextEditingController();
  final TextEditingController _personalReference2PhoneController =
      TextEditingController();
  final TextEditingController _commercialReference1NameController =
      TextEditingController();
  final TextEditingController _commercialReference1PhoneController =
      TextEditingController();
  final TextEditingController _commercialReference2NameController =
      TextEditingController();
  final TextEditingController _commercialReference2PhoneController =
      TextEditingController();

  // Variables de estado
  int _currentStep = 0;
  CreditProduct? _selectedProduct;
  List<CreditProduct> _availableProducts = [];
  bool _isLoadingProducts = true;
  String? _productsError;
  String _documentType = 'DNI';
  DateTime? _birthDate;
  String _nationality = 'Peruana';
  String _maritalStatus = 'soltero';
  String _gender = 'masculino';
  int _numberOfDependents = 0;
  String _employmentType = 'empleado';
  int _workExperienceMonths = 0;
  int _loanTermMonths = 12;
  bool _hasCreditHistory = false;
  bool _hasBankAccount = false;
  bool _acceptTerms = false;
  bool _authorizeCreditCheck = false;
  bool _confirmTruthfulness = false;

  // Variables para ubicación - usando el nuevo sistema
  LocationData? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;
  LocationStatus? _locationStatus;

  // Use case instances
  late final CreateLoanApplicationUseCase _createLoanApplicationUseCase;
  late final CreditProductService _creditProductService;

  @override
  void initState() {
    super.initState();
    // Initialize use case with dependencies
    final dataSource = LoanApplicationDataSource();
    final repository = LoanApplicationRepositoryImpl(dataSource: dataSource);
    _createLoanApplicationUseCase = CreateLoanApplicationUseCase(repository);
    _creditProductService = CreditProductService();

    // Auto-llenar datos del usuario autenticado
    _populateUserData();

    // Add listeners to text controllers for real-time validation
    _setupTextControllerListeners();

    // Load products from Firebase
    _loadProducts();
  }

  void _setupTextControllerListeners() {
    final controllers = [
      _firstNameController,
      _lastNameController,
      _documentNumberController,
      _addressController,
      _districtController,
      _provinceController,
      _departmentController,
      _mobilePhoneController,
      _emailController,
      _landlinePhoneController,
      _locationReferenceController,
      _employerNameController,
      _positionController,
      _workAddressController,
      _workPhoneController,
      _monthlyIncomeController,
      _monthlyExpensesController,
      _otherIncomeController,
      _currentDebtsController,
      _loanAmountController,
      _loanPurposeController,
      _bankNameController,
      _accountNumberController,
      _cciController,
      _personalReference1NameController,
      _personalReference1PhoneController,
      _personalReference2NameController,
      _personalReference2PhoneController,
      _commercialReference1NameController,
      _commercialReference1PhoneController,
      _commercialReference2NameController,
      _commercialReference2PhoneController,
    ];

    for (final controller in controllers) {
      controller.addListener(() {
        setState(() {
          // Trigger rebuild to update button state
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

      // Auto-llenar nombres y apellidos del perfil
      if (profile != null) {
        if (profile.firstName.isNotEmpty) {
          _firstNameController.text = profile.firstName;
        }
        if (profile.lastName.isNotEmpty) {
          _lastNameController.text = profile.lastName;
        }
        if (profile.dni != null && profile.dni!.isNotEmpty) {
          _documentNumberController.text = profile.dni!;
        }
        if (profile.phone != null && profile.phone!.isNotEmpty) {
          _mobilePhoneController.text = profile.phone!;
        }
      }

      // Auto-llenar email del usuario autenticado
      if (user.email != null && user.email!.isNotEmpty) {
        _emailController.text = user.email!;
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoadingProducts = true;
        _productsError = null;
      });

      final products = await _creditProductService.getProductsByMfId(
        widget.microfinancieraId,
      );

      setState(() {
        _availableProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
        _productsError = 'Error al cargar productos: $e';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _departmentController.dispose();
    _mobilePhoneController.dispose();
    _emailController.dispose();
    _employerNameController.dispose();
    _positionController.dispose();
    _monthlyIncomeController.dispose();
    _loanAmountController.dispose();
    _loanPurposeController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _cciController.dispose();
    super.dispose();
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Selección de producto
        return _selectedProduct != null;
      case 1: // Información personal
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _documentNumberController.text.isNotEmpty &&
            _birthDate != null &&
            _gender.isNotEmpty;
      case 2: // Información de contacto
        return _mobilePhoneController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _addressController.text.isNotEmpty &&
            _districtController.text.isNotEmpty &&
            _provinceController.text.isNotEmpty &&
            _departmentController.text.isNotEmpty &&
            _isValidEmail(_emailController.text);
      case 3: // Información laboral
        return _employerNameController.text.isNotEmpty &&
            _positionController.text.isNotEmpty &&
            _monthlyIncomeController.text.isNotEmpty &&
            _isValidAmount(_monthlyIncomeController.text);
      case 4: // Información financiera
        return _loanAmountController.text.isNotEmpty &&
            _loanPurposeController.text.isNotEmpty &&
            _isValidAmount(_loanAmountController.text) &&
            _isValidLoanAmount();
      case 5: // Información adicional
        if (widget.isWithoutAccount) {
          return _bankNameController.text.isNotEmpty &&
              _accountNumberController.text.isNotEmpty &&
              _cciController.text.isNotEmpty;
        }
        return true;
      case 6: // Consentimientos
        return _acceptTerms &&
            _authorizeCreditCheck &&
            _confirmTruthfulness &&
            _currentPosition != null;
      default:
        return false;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidAmount(String amount) {
    final value = double.tryParse(amount);
    return value != null && value > 0;
  }

  bool _isValidLoanAmount() {
    if (_selectedProduct == null) return true;

    final amount = double.tryParse(_loanAmountController.text);
    if (amount == null) return false;

    return amount >= _selectedProduct!.amountMin &&
        amount <= _selectedProduct!.amountMax;
  }

  Color _getLoanAmountValidationColor() {
    if (_selectedProduct == null || _loanAmountController.text.isEmpty) {
      return Colors.grey.shade600;
    }

    final amount = double.tryParse(_loanAmountController.text);
    if (amount == null) return Colors.red;

    if (amount < _selectedProduct!.amountMin ||
        amount > _selectedProduct!.amountMax) {
      return Colors.red;
    }

    return Colors.green;
  }

  String? _getLoanAmountErrorText() {
    if (_selectedProduct == null || _loanAmountController.text.isEmpty) {
      return null;
    }

    final amount = double.tryParse(_loanAmountController.text);
    if (amount == null) return null; // Let validator handle this

    if (amount < _selectedProduct!.amountMin) {
      return 'El monto mínimo es S/ ${_selectedProduct!.amountMin.toStringAsFixed(0)}';
    }

    if (amount > _selectedProduct!.amountMax) {
      return 'El monto máximo es S/ ${_selectedProduct!.amountMax.toStringAsFixed(0)}';
    }

    return null;
  }

  void _nextStep() {
    if (_currentStep < 7 && _canProceedToNextStep()) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (!_canProceedToNextStep()) {
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

  void _showValidationError() {
    String message = '';
    switch (_currentStep) {
      case 0:
        message = 'Por favor selecciona un tipo de crédito';
        break;
      case 1:
        message = 'Por favor completa todos los campos de información personal';
        break;
      case 2:
        message =
            'Por favor completa todos los campos de información de contacto';
        break;
      case 3:
        message = 'Por favor completa todos los campos de información laboral';
        break;
      case 4:
        message =
            'Por favor completa todos los campos de información financiera';
        break;
      case 5:
        if (widget.isWithoutAccount) {
          message = 'Por favor completa todos los campos bancarios';
        }
        break;
      case 6:
        message = 'Por favor acepta todos los términos y condiciones';
        break;
      case 7:
        message = 'Por favor comparte tu ubicación para continuar';
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

  Future<void> _showExitConfirmation() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la solicitud?'),
        content: const Text(
          'Si sales ahora, perderás toda la información ingresada. '
          '¿Estás seguro de que quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _showExitConfirmation();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Solicitud de Crédito'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitConfirmation,
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 7,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paso ${_currentStep + 1} de 7',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildProductSelectionStep(),
                    _buildPersonalInfoStep(),
                    _buildContactInfoStep(),
                    _buildEmploymentInfoStep(),
                    _buildFinancialInfoStep(),
                    _buildAdditionalInfoStep(),
                    _buildConsentsStep(),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _previousStep,
                      child: const Text('Anterior'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _currentStep == 6
                        ? (_canProceedToNextStep() ? _submitApplication : null)
                        : (_canProceedToNextStep() ? _nextStep : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canProceedToNextStep()
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    child: Text(
                      _currentStep == 6 ? 'Enviar Solicitud' : 'Siguiente',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Crédito',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona el tipo de crédito que necesitas:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          if (_isLoadingProducts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_productsError != null)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _productsError!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProducts,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (_availableProducts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No hay productos de crédito disponibles en este momento',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_availableProducts
                .map(
                  (product) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: RadioListTile<CreditProduct>(
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.description),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Colors.green[700],
                              ),
                              Text(
                                'Monto: S/ ${product.minAmount.toStringAsFixed(0)} - S/ ${product.maxAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              Text(
                                'Plazo: ${product.minTermMonths} - ${product.maxTermMonths} meses',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.percent,
                                size: 16,
                                color: Colors.orange[700],
                              ),
                              Text(
                                'Tasa: ${product.interestRate}% anual',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      value: product,
                      groupValue: _selectedProduct,
                      onChanged: (CreditProduct? value) {
                        setState(() {
                          _selectedProduct = value;
                        });
                      },
                    ),
                  ),
                )
                .toList()),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Personal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Nombres *',
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
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Apellidos *',
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

          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _documentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Documento',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                    DropdownMenuItem(
                      value: 'CE',
                      child: Text('Carné de Extranjería'),
                    ),
                    DropdownMenuItem(
                      value: 'PASSPORT',
                      child: Text('Pasaporte'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _documentType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _documentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Documento *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _birthDate ?? DateTime(1990),
                firstDate: DateTime(1920),
                lastDate: DateTime.now().subtract(
                  const Duration(days: 6570),
                ), // 18 años
              );
              if (date != null) {
                setState(() {
                  _birthDate = date;
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de Nacimiento *',
                border: const OutlineInputBorder(),
                errorText: _birthDate == null
                    ? 'Este campo es obligatorio'
                    : null,
              ),
              child: Text(
                _birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                    : 'Seleccionar fecha',
                style: TextStyle(
                  color: _birthDate != null ? null : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _nationality,
            decoration: const InputDecoration(
              labelText: 'Nacionalidad',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Peruana', child: Text('Peruana')),
              DropdownMenuItem(value: 'Extranjera', child: Text('Extranjera')),
            ],
            onChanged: (value) {
              setState(() {
                _nationality = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: const InputDecoration(
              labelText: 'Estado Civil',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'soltero', child: Text('Soltero(a)')),
              DropdownMenuItem(value: 'casado', child: Text('Casado(a)')),
              DropdownMenuItem(
                value: 'divorciado',
                child: Text('Divorciado(a)'),
              ),
              DropdownMenuItem(value: 'viudo', child: Text('Viudo(a)')),
              DropdownMenuItem(
                value: 'conviviente',
                child: Text('Conviviente'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _maritalStatus = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Género *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
              DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
              DropdownMenuItem(value: 'otro', child: Text('Otro')),
            ],
            onChanged: (value) {
              setState(() {
                _gender = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _numberOfDependents,
            decoration: const InputDecoration(
              labelText: 'Número de Dependientes',
              border: OutlineInputBorder(),
            ),
            items: List.generate(11, (index) => index)
                .map(
                  (number) => DropdownMenuItem(
                    value: number,
                    child: Text(
                      number == 0
                          ? 'Ninguno'
                          : '$number ${number == 1 ? 'dependiente' : 'dependientes'}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _numberOfDependents = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de Contacto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _mobilePhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono Móvil *',
              border: OutlineInputBorder(),
              prefixText: '+51 ',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              if (!value.contains('@')) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección *',
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
          const SizedBox(height: 16),

          TextFormField(
            controller: _landlinePhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono Fijo/Alternativo',
              border: OutlineInputBorder(),
              prefixText: '+51 ',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _locationReferenceController,
            decoration: const InputDecoration(
              labelText: 'Referencia de Ubicación',
              border: OutlineInputBorder(),
              hintText: 'Ej: Cerca al parque, frente a la farmacia...',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Laboral',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            value: _employmentType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Empleo',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'empleado', child: Text('Empleado')),
              DropdownMenuItem(
                value: 'independiente',
                child: Text('Independiente'),
              ),
              DropdownMenuItem(value: 'empresario', child: Text('Empresario')),
            ],
            onChanged: (value) {
              setState(() {
                _employmentType = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _employerNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Empleador/Empresa *',
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
            controller: _positionController,
            decoration: const InputDecoration(
              labelText: 'Cargo/Posición *',
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
            controller: _monthlyIncomeController,
            decoration: const InputDecoration(
              labelText: 'Ingresos Mensuales (S/) *',
              border: OutlineInputBorder(),
              prefixText: 'S/ ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _workExperienceMonths,
            decoration: const InputDecoration(
              labelText: 'Tiempo en el Trabajo Actual',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: 0, child: Text('Menos de 6 meses')),
              ...List.generate(60, (index) => index + 6)
                  .map(
                    (months) => DropdownMenuItem(
                      value: months,
                      child: Text('${months} ${months == 1 ? 'mes' : 'meses'}'),
                    ),
                  )
                  .toList(),
            ],
            onChanged: (value) {
              setState(() {
                _workExperienceMonths = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _workAddressController,
            decoration: const InputDecoration(
              labelText: 'Dirección del Trabajo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _workPhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono del Trabajo',
              border: OutlineInputBorder(),
              prefixText: '+51 ',
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del Crédito',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _loanAmountController,
            decoration: InputDecoration(
              labelText: 'Monto Solicitado (S/) *',
              border: const OutlineInputBorder(),
              prefixText: 'S/ ',
              helperText: _selectedProduct != null
                  ? 'Rango permitido: S/ ${_selectedProduct!.amountMin.toStringAsFixed(0)} - S/ ${_selectedProduct!.amountMax.toStringAsFixed(0)}'
                  : null,
              helperStyle: TextStyle(
                color: _getLoanAmountValidationColor(),
                fontWeight: FontWeight.w500,
              ),
              errorText: _getLoanAmountErrorText(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (value) {
              setState(() {
                // Trigger rebuild to update validation colors and messages
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              if (!_isValidAmount(value)) {
                return 'Ingrese un monto válido';
              }
              if (_selectedProduct != null && !_isValidLoanAmount()) {
                return 'El monto debe estar entre S/ ${_selectedProduct!.amountMin.toStringAsFixed(0)} y S/ ${_selectedProduct!.amountMax.toStringAsFixed(0)}';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _loanTermMonths,
            decoration: const InputDecoration(
              labelText: 'Plazo (meses)',
              border: OutlineInputBorder(),
            ),
            items: List.generate(36, (index) => index + 1)
                .map(
                  (months) => DropdownMenuItem(
                    value: months,
                    child: Text('$months ${months == 1 ? 'mes' : 'meses'}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _loanTermMonths = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _loanPurposeController,
            decoration: const InputDecoration(
              labelText: 'Propósito del Crédito *',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('¿Tienes historial crediticio?'),
            value: _hasCreditHistory,
            onChanged: (value) {
              setState(() {
                _hasCreditHistory = value;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _monthlyExpensesController,
            decoration: const InputDecoration(
              labelText: 'Gastos Mensuales (S/) *',
              border: OutlineInputBorder(),
              prefixText: 'S/ ',
              hintText: 'Incluye alimentación, servicios, transporte, etc.',
              suffixIcon: Icon(Icons.shopping_cart),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Ingrese un monto válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _otherIncomeController,
            decoration: const InputDecoration(
              labelText: 'Otros Ingresos (S/) *',
              border: OutlineInputBorder(),
              prefixText: 'S/ ',
              hintText: 'Ingresos adicionales, rentas, etc.',
              suffixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Ingrese un monto válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _currentDebtsController,
            decoration: const InputDecoration(
              labelText: 'Deudas Actuales (S/) *',
              border: OutlineInputBorder(),
              prefixText: 'S/ ',
              hintText: 'Suma total de deudas pendientes',
              suffixIcon: Icon(Icons.account_balance_wallet),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Ingrese un monto válido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Adicional',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          if (widget.isWithoutAccount) ...[
            Text(
              'Información Bancaria',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Banco *',
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
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Número de Cuenta *',
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
              controller: _cciController,
              decoration: const InputDecoration(
                labelText: 'CCI (Código de Cuenta Interbancaria) *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],

          SwitchListTile(
            title: const Text('¿Tienes cuenta bancaria?'),
            value: _hasBankAccount,
            onChanged: (value) {
              setState(() {
                _hasBankAccount = value;
              });
            },
          ),
          const SizedBox(height: 24),

          Text(
            'Referencias Personales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _personalReference1NameController,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo - Referencia 1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _personalReference1PhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono - Referencia 1',
              border: OutlineInputBorder(),
              prefixText: '+51 ',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _personalReference2NameController,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo - Referencia 2',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _personalReference2PhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono - Referencia 2',
              border: OutlineInputBorder(),
              prefixText: '+51 ',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          Text(
            'Referencias Comerciales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _commercialReference1NameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Negocio - Referencia 1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _commercialReference1PhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono - Referencia 1',
              border: OutlineInputBorder(),
              prefixText: '+51 ',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _commercialReference2NameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Negocio - Referencia 2',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _commercialReference2PhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono - Referencia 2',
              border: OutlineInputBorder(),
              prefixText: '+51 ',
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildConsentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consentimientos y Autorización',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Importante: Para procesar tu solicitud de crédito, necesitamos tu autorización explícita para los siguientes puntos. Lee cuidadosamente cada una de las condiciones antes de continuar.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          CheckboxListTile(
            title: const Text('Acepto los Términos y Condiciones *'),
            subtitle: const Text(
              'He leído y acepto los términos y condiciones del servicio de crédito. Entiendo las bases de tarifas, comisiones y condiciones de pago.',
            ),
            value: _acceptTerms,
            onChanged: (value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Autorizo Consulta en Centrales de Riesgo *'),
            subtitle: const Text(
              'Autorizo expresamente la identificación e consulta del historial crediticio en centrales de riesgo (Equifax, Experian, etc.) para evaluar mi capacidad de pago y comportamiento crediticio.',
            ),
            value: _authorizeCreditCheck,
            onChanged: (value) {
              setState(() {
                _authorizeCreditCheck = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Confirmo Veracidad de la Información *'),
            subtitle: const Text(
              'Declaro bajo juramento que toda la información proporcionada en esta solicitud es veraz, completa y exacta. Entiendo que proporcionar información falsa puede resultar en el rechazo de mi solicitud o acciones legales.',
            ),
            value: _confirmTruthfulness,
            onChanged: (value) {
              setState(() {
                _confirmTruthfulness = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),

          const SizedBox(height: 32),

          // Sección de Ubicación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Ubicación',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Para completar tu solicitud, necesitamos verificar tu ubicación actual. Esto nos ayuda a validar la información proporcionada.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                if (_currentPosition != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ubicación obtenida exitosamente',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Latitud: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Longitud: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ] else if (_locationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Error al obtener ubicación',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _locationError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation
                        ? null
                        : _getCurrentLocationWithAutoRequest,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _isLoadingLocation
                          ? 'Obteniendo ubicación...'
                          : 'Obtener mi ubicación',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Información importante',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu ubicación se utiliza únicamente para verificar la solicitud y se almacena de forma segura. Puedes revocar los permisos en cualquier momento desde la configuración.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ubicación', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),

          Text(
            'Para completar tu solicitud, necesitamos verificar tu ubicación actual. Esto nos ayuda a validar la información proporcionada.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          if (_currentPosition != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Ubicación obtenida exitosamente',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitud: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Longitud: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Timestamp: ${DateFormat('dd/MM/yyyy HH:mm').format(_currentPosition!.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ] else ...[
            if (_locationError != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Obtener ubicación',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón para compartir tu ubicación actual',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingLocation
                          ? null
                          : _getCurrentLocationWithAutoRequest,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _isLoadingLocation
                            ? 'Obteniendo ubicación...'
                            : 'Obtener mi ubicación',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Información importante',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Tu ubicación se utiliza únicamente para verificar la solicitud\n'
                  '• Los datos de ubicación se almacenan de forma segura\n'
                  '• Puedes revocar los permisos en cualquier momento desde la configuración',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Nuevo método que usa el sistema automático de ubicación
  Future<void> _getCurrentLocationWithAutoRequest() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
      _locationStatus = null;
    });

    try {
      LocationResult result =
          await LocationService.getCurrentLocationWithCheck();

      setState(() {
        _locationStatus = result.status;
        _isLoadingLocation = false;
      });

      if (result.status == LocationStatus.enabled && result.data != null) {
        setState(() {
          _currentPosition = result.data;
          _locationError = null;
        });
      } else if (result.status != LocationStatus.enabled) {
        // Mostrar diálogo automático para solicitar activación
        if (mounted) {
          await LocationPermissionDialog.show(
            context,
            status: result.status,
            message: result.message ?? 'Error desconocido',
            onRetry: _getCurrentLocationWithAutoRequest,
            onCancel: () {
              setState(() {
                _locationError =
                    'Ubicación requerida para procesar la solicitud';
              });
            },
          );
        }
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error al obtener ubicación: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_canProceedToNextStep()) {
      _showValidationError();
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Enviando solicitud...'),
            ],
          ),
        ),
      );

      // Crear la aplicación
      final application = LoanApplication(
        id: '',
        userId: widget.userId,
        microfinancieraId: widget.microfinancieraId,
        product: _selectedProduct != null
            ? ProductInfo(
                id: _selectedProduct!.id,
                code: _selectedProduct!.code,
                name: _selectedProduct!.name,
                rateNominal: _selectedProduct!.rateNominal,
                interestType: _selectedProduct!.interestType,
                termMin: _selectedProduct!.termMin,
                termMax: _selectedProduct!.termMax,
                amountMin: _selectedProduct!.amountMin,
                amountMax: _selectedProduct!.amountMax,
              )
            : null,
        personalInfo: PersonalInfo(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          documentType: _documentType,
          documentNumber: _documentNumberController.text,
          birthDate: _birthDate != null
              ? DateFormat('yyyy-MM-dd').format(_birthDate!)
              : '',
          nationality: _nationality,
          maritalStatus: _maritalStatus,
          gender: _gender,
          dependents: _numberOfDependents,
        ),
        contactInfo: ContactInfo(
          address: _addressController.text,
          district: _districtController.text,
          province: _provinceController.text,
          department: _departmentController.text,
          mobilePhone: _mobilePhoneController.text,
          email: _emailController.text,
          landlinePhone: _landlinePhoneController.text.isNotEmpty
              ? _landlinePhoneController.text
              : null,
          locationReference: _locationReferenceController.text.isNotEmpty
              ? _locationReferenceController.text
              : null,
        ),
        employmentInfo: EmploymentInfo(
          employmentType: _employmentType,
          employerName: _employerNameController.text,
          position: _positionController.text,
          workExperience: _workExperienceMonths.toString(),
          workAddress: _workAddressController.text.isNotEmpty
              ? _workAddressController.text
              : null,
          workPhone: _workPhoneController.text.isNotEmpty
              ? _workPhoneController.text
              : null,
        ),
        financialInfo: FinancialInfo(
          monthlyIncome: double.tryParse(_monthlyIncomeController.text) ?? 0,
          monthlyExpenses: _monthlyExpensesController.text.isNotEmpty
              ? double.tryParse(_monthlyExpensesController.text)
              : null,
          otherIncome: _otherIncomeController.text.isNotEmpty
              ? double.tryParse(_otherIncomeController.text)
              : null,
          currentDebts: _currentDebtsController.text.isNotEmpty
              ? double.tryParse(_currentDebtsController.text)
              : null,
          loanAmount: double.tryParse(_loanAmountController.text) ?? 0,
          loanTermMonths: _loanTermMonths,
          loanPurpose: _loanPurposeController.text,
        ),
        additionalInfo: AdditionalInfo(
          hasCreditHistory: _hasCreditHistory,
          hasBankAccount: _hasBankAccount,
          bankName: _hasBankAccount ? _bankNameController.text : null,
          hasGuarantee: false,
          accountNumber: widget.isWithoutAccount
              ? _accountNumberController.text
              : null,
          cci: widget.isWithoutAccount ? _cciController.text : null,
          personalReference1Name:
              _personalReference1NameController.text.isNotEmpty
              ? _personalReference1NameController.text
              : null,
          personalReference1Phone:
              _personalReference1PhoneController.text.isNotEmpty
              ? _personalReference1PhoneController.text
              : null,
          personalReference2Name:
              _personalReference2NameController.text.isNotEmpty
              ? _personalReference2NameController.text
              : null,
          personalReference2Phone:
              _personalReference2PhoneController.text.isNotEmpty
              ? _personalReference2PhoneController.text
              : null,
          commercialReference1Name:
              _commercialReference1NameController.text.isNotEmpty
              ? _commercialReference1NameController.text
              : null,
          commercialReference1Phone:
              _commercialReference1PhoneController.text.isNotEmpty
              ? _commercialReference1PhoneController.text
              : null,
          commercialReference2Name:
              _commercialReference2NameController.text.isNotEmpty
              ? _commercialReference2NameController.text
              : null,
          commercialReference2Phone:
              _commercialReference2PhoneController.text.isNotEmpty
              ? _commercialReference2PhoneController.text
              : null,
        ),
        consents: Consents(
          acceptTerms: _acceptTerms,
          authorizeCreditCheck: _authorizeCreditCheck,
          confirmTruthfulness: _confirmTruthfulness,
        ),
        location: _currentPosition != null
            ? LocationData(
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
                timestamp: DateTime.now(),
              )
            : null,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _createLoanApplicationUseCase.call(
        CreateLoanApplicationParams(
          microfinancieraId: widget.microfinancieraId,
          application: application,
        ),
      );

      // Actualizar el bloc
      if (mounted) {
        context.read<IntakeRequestBloc>().add(
          const IntakeRequestRefreshRequested(),
        );
      }

      // Cerrar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar éxito y cerrar
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¡Solicitud Enviada!'),
            content: const Text(
              'Tu solicitud de crédito ha sido enviada exitosamente. '
              'Recibirás una notificación cuando sea revisada.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
