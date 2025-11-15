import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/loan_application.dart';
import '../../domain/entities/credit_product.dart';
import '../../domain/usecases/loan_application/create_loan_application_usecase.dart';
import '../../data/repositories/loan_application_repository_impl.dart';
import '../../data/datasources/loan_application_datasource.dart';
import '../../infrastructure/services/credit_product_service.dart';
import '../bloc/intake_request/intake_request_bloc.dart';
import '../bloc/intake_request/intake_request_event.dart';

class LoanApplicationModal extends StatefulWidget {
  final String userId;
  final String microfinancieraId;
  final bool isWithoutAccount;

  const LoanApplicationModal({
    super.key,
    required this.userId,
    required this.microfinancieraId,
    this.isWithoutAccount = false,
  });

  @override
  State<LoanApplicationModal> createState() => _LoanApplicationModalState();
}

class _LoanApplicationModalState extends State<LoanApplicationModal> {
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
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _cciController = TextEditingController();
  
  // Controladores para información adicional
  final TextEditingController _collateralDescriptionController = TextEditingController();
  final TextEditingController _reference1NameController = TextEditingController();
  final TextEditingController _reference1PhoneController = TextEditingController();
  final TextEditingController _reference2NameController = TextEditingController();
  final TextEditingController _reference2PhoneController = TextEditingController();
  final TextEditingController _additionalCommentsController = TextEditingController();

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
  String _employmentType = 'empleado';
  int _loanTermMonths = 12;
  bool _hasCreditHistory = false;
  bool _hasBankAccount = false;
  bool _hasCollateral = false;
  bool _acceptTerms = false;
  bool _authorizeCreditCheck = false;
  bool _confirmTruthfulness = false;
  
  // Variables para ubicación
  Position? _userLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

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
    
    // Load products from Firebase
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoadingProducts = true;
        _productsError = null;
      });

      final products = await _creditProductService.getProductsByMfId(widget.microfinancieraId);
      
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
    _collateralDescriptionController.dispose();
    _reference1NameController.dispose();
    _reference1PhoneController.dispose();
    _reference2NameController.dispose();
    _reference2PhoneController.dispose();
    _additionalCommentsController.dispose();
    super.dispose();
  }

  List<int> _getAvailableTerms() {
    if (_selectedProduct == null) {
      return [6, 12, 18, 24, 36, 48]; 
    }
    
    List<int> availableTerms = [];
    for (int term = _selectedProduct!.termMin; 
         term <= _selectedProduct!.termMax; 
         term += 6) {
      availableTerms.add(term);
    }
    
    if (!availableTerms.contains(_selectedProduct!.termMin)) {
      availableTerms.insert(0, _selectedProduct!.termMin);
    }
    if (!availableTerms.contains(_selectedProduct!.termMax)) {
      availableTerms.add(_selectedProduct!.termMax);
    }
    
    availableTerms.sort();
    return availableTerms;
  }

  void _nextStep() {
    if (_currentStep < 6) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permisos de ubicación denegados';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permisos de ubicación denegados permanentemente. Ve a configuración para habilitarlos.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Servicio de ubicación deshabilitado. Habilítalo en configuración.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = position;
        _isLoadingLocation = false;
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación obtenida exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error al obtener ubicación: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Producto
        return _selectedProduct != null;
      case 1: // Datos Personales
        return _formKey.currentState?.validate() ?? false;
      case 2: // Contacto
        return _formKey.currentState?.validate() ?? false;
      case 3: // Información Laboral
        return _formKey.currentState?.validate() ?? false;
      case 4: // Información Financiera
        bool isFormValid = _formKey.currentState?.validate() ?? false;
        if (widget.isWithoutAccount) {
          // Validar campos adicionales para usuarios sin cuenta
          bool isAccountNumberValid = _accountNumberController.text.isNotEmpty;
          bool isCciValid = _cciController.text.isNotEmpty;
          return isFormValid && isAccountNumberValid && isCciValid;
        }
        return isFormValid;
      case 5: // Información Adicional
        bool isFormValid = _formKey.currentState?.validate() ?? false;
        // Validar que al menos una referencia personal esté completa
        bool hasReference1 = _reference1NameController.text.isNotEmpty && 
                             _reference1PhoneController.text.isNotEmpty;
        bool hasReference2 = _reference2NameController.text.isNotEmpty && 
                             _reference2PhoneController.text.isNotEmpty;
        bool hasAtLeastOneReference = hasReference1 || hasReference2;
        
        // Si tiene garantías, debe describir las garantías
        bool collateralValid = !_hasCollateral || 
                              _collateralDescriptionController.text.isNotEmpty;
        
        return isFormValid && hasAtLeastOneReference && collateralValid;
      case 6: // Consentimientos
        return _acceptTerms && _authorizeCreditCheck && _confirmTruthfulness;
      default:
        return true;
    }
  }

  void _submitApplication() async {
    if (!_validateCurrentStep()) return;

    try {
      final application = LoanApplication(
        id: '',
        userId: widget.userId,
        microfinancieraId: widget.microfinancieraId,
        product: ProductInfo(
          id: _selectedProduct!.id,
          name: _selectedProduct!.name,
          code: _selectedProduct!.code,
          rateNominal: _selectedProduct!.rateNominal / 100,
          interestType: _selectedProduct!.interestType,
          termMin: _selectedProduct!.termMin,
          termMax: _selectedProduct!.termMax,
          amountMin: _selectedProduct!.amountMin,
          amountMax: _selectedProduct!.amountMax,
        ),
        personalInfo: PersonalInfo(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          documentType: _documentType,
          documentNumber: _documentNumberController.text,
          birthDate: DateFormat('yyyy-MM-dd').format(_birthDate!),
          nationality: _nationality,
          maritalStatus: _maritalStatus,
          dependents: 0,
        ),
        contactInfo: ContactInfo(
          address: _addressController.text,
          district: _districtController.text,
          province: _provinceController.text,
          department: _departmentController.text,
          mobilePhone: _mobilePhoneController.text,
          email: _emailController.text,
        ),
        employmentInfo: EmploymentInfo(
          employmentType: _employmentType,
          employerName: _employerNameController.text,
          position: _positionController.text,
          yearsEmployed: 1,
          monthsEmployed: 0,
          contractType: 'indefinido',
          workPhone: '',
        ),
        financialInfo: FinancialInfo(
          monthlyIncome: double.tryParse(_monthlyIncomeController.text) ?? 0,
          loanAmount: double.tryParse(_loanAmountController.text) ?? 0,
          loanTermMonths: _loanTermMonths,
          loanPurpose: _loanPurposeController.text,
        ),
        additionalInfo: AdditionalInfo(
          hasCreditHistory: _hasCreditHistory,
          hasBankAccount: _hasBankAccount,
          bankName: _hasBankAccount ? _bankNameController.text : null,
          hasGuarantee: false,
          accountNumber: widget.isWithoutAccount ? _accountNumberController.text : null,
          cci: widget.isWithoutAccount ? _cciController.text : null,
        ),
        consents: Consents(
          acceptTerms: _acceptTerms,
          authorizeCreditCheck: _authorizeCreditCheck,
          confirmTruthfulness: _confirmTruthfulness,
        ),
        location: _userLocation != null 
          ? LocationData(
              latitude: _userLocation!.latitude,
              longitude: _userLocation!.longitude,
              timestamp: DateTime.now(),
            )
          : null,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Usar el use case para crear la aplicación
      final applicationId = await _createLoanApplicationUseCase.call(
        CreateLoanApplicationParams(
          microfinancieraId: widget.microfinancieraId,
          application: application,
        ),
      );

      // Emitir evento para refrescar la lista
      context.read<IntakeRequestBloc>().add(
        const IntakeRequestRefreshRequested(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitud enviada exitosamente (ID: $applicationId)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.98,
        height: MediaQuery.of(context).size.height * 0.92,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitud de Crédito',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress indicator
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
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),
            Row(
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
                  onPressed: _currentStep == 6 ? _submitApplication : _nextStep,
                  child: Text(
                    _currentStep == 6 ? 'Enviar Solicitud' : 'Siguiente',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelectionStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tipo de Crédito', style: Theme.of(context).textTheme.titleLarge),
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
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _productsError!,
                    style: TextStyle(color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProducts,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else if (_availableProducts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No hay productos de crédito disponibles',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._availableProducts.map((product) => _buildProductCard(product)),
        ],
      ),
    );
  }

  Widget _buildProductCard(CreditProduct product) {
    final isSelected = _selectedProduct?.id == product.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? product.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedProduct = product;
              // Resetear el plazo si está fuera del rango del nuevo producto
              if (_loanTermMonths < product.termMin || 
                  _loanTermMonths > product.termMax) {
                _loanTermMonths = product.termMin;
              }
              // Limpiar el campo de monto para que el usuario vea los nuevos límites
              _loanAmountController.clear();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isSelected 
                ? LinearGradient(
                    colors: [
                      product.backgroundColor,
                      product.backgroundColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: product.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        product.icon,
                        color: product.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? product.primaryColor : null,
                            ),
                          ),
                          Text(
                            product.code,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: product.primaryColor,
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.trending_up,
                        'Tasa de interés',
                        product.formattedInterestRate,
                        product.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.attach_money,
                        'Rango de monto',
                        product.formattedAmountRange,
                        product.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoChip(
                  Icons.schedule,
                  'Plazo',
                  product.formattedTermRange,
                  product.primaryColor,
                  fullWidth: true,
                ),
                if (product.features.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: product.features.map((feature) => 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: product.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: product.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos Personales',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _documentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de documento',
                    border: OutlineInputBorder(),
                  ),
                  items: ['DNI', 'CE', 'Pasaporte']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _documentType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _documentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Número de documento',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
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
                initialDate: DateTime.now().subtract(
                  const Duration(days: 365 * 25),
                ),
                firstDate: DateTime.now().subtract(
                  const Duration(days: 365 * 80),
                ),
                lastDate: DateTime.now().subtract(
                  const Duration(days: 365 * 18),
                ),
              );
              if (date != null) {
                setState(() {
                  _birthDate = date;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de nacimiento',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                    : 'Seleccionar fecha',
              ),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: const InputDecoration(
              labelText: 'Estado civil',
              border: OutlineInputBorder(),
            ),
            items: ['soltero', 'casado', 'divorciado', 'viudo', 'conviviente']
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _maritalStatus = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de Contacto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'Distrito',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _provinceController,
                  decoration: const InputDecoration(
                    labelText: 'Provincia',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(
              labelText: 'Departamento',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _mobilePhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono móvil',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              if (!value.contains('@')) {
                return 'Correo inválido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Laboral',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _employmentType,
            decoration: const InputDecoration(
              labelText: 'Tipo de empleo',
              border: OutlineInputBorder(),
            ),
            items: ['empleado', 'independiente', 'empresario', 'jubilado']
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _employmentType = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _employerNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del empleador/negocio',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _positionController,
            decoration: const InputDecoration(
              labelText: 'Cargo/Puesto',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Financiera',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _monthlyIncomeController,
            decoration: const InputDecoration(
              labelText: 'Ingreso mensual (S/)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _loanAmountController,
            decoration: const InputDecoration(
              labelText: 'Monto del préstamo solicitado (S/)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              
              if (_selectedProduct == null) {
                return 'Selecciona un tipo de crédito primero';
              }
              
              final amount = double.tryParse(value);
              if (amount == null) {
                return 'Ingresa un monto válido';
              }
              
              if (amount < _selectedProduct!.amountMin) {
                return 'El monto mínimo es S/ ${_selectedProduct!.amountMin.toStringAsFixed(0)}';
              }
              
              if (amount > _selectedProduct!.amountMax) {
                return 'El monto máximo es S/ ${_selectedProduct!.amountMax.toStringAsFixed(0)}';
              }
              
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedProduct != null && 
                   (_loanTermMonths < _selectedProduct!.termMin || 
                    _loanTermMonths > _selectedProduct!.termMax)
                ? _selectedProduct!.termMin 
                : _loanTermMonths,
            decoration: const InputDecoration(
              labelText: 'Plazo deseado (meses)',
              border: OutlineInputBorder(),
            ),
            items: _getAvailableTerms()
                .map(
                  (months) => DropdownMenuItem(
                    value: months,
                    child: Text('$months meses'),
                  ),
                )
                .toList(),
            onChanged: (int? value) {
              setState(() {
                _loanTermMonths = value!;
              });
            },
            validator: (value) {
              if (_selectedProduct == null) {
                return 'Selecciona un tipo de crédito primero';
              }
              if (value == null) {
                return 'Selecciona un plazo';
              }
              if (value < _selectedProduct!.termMin || 
                  value > _selectedProduct!.termMax) {
                return 'Plazo fuera del rango permitido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _loanPurposeController,
            decoration: const InputDecoration(
              labelText: 'Propósito del préstamo',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          
          // Campos adicionales para usuarios sin cuenta
          if (widget.isWithoutAccount) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Información Bancaria',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Como no tienes una cuenta en nuestra plataforma, necesitamos tu información bancaria para procesar el crédito.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de cuenta bancaria',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Número de cuenta requerido';
                      }
                      if (value.length < 10) {
                        return 'Número de cuenta debe tener al menos 10 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _cciController,
                    decoration: const InputDecoration(
                      labelText: 'CCI (Código de Cuenta Interbancario)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                      helperText: '20 dígitos del CCI de tu cuenta',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 20,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CCI requerido';
                      }
                      if (value.length != 20) {
                        return 'El CCI debe tener exactamente 20 dígitos';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Adicional',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Historial crediticio
          SwitchListTile(
            title: const Text('¿Posee historial crediticio?'),
            subtitle: const Text('¿Ha tenido préstamos anteriormente?'),
            value: _hasCreditHistory,
            onChanged: (bool value) {
              setState(() {
                _hasCreditHistory = value;
              });
            },
          ),

          // Información bancaria
          SwitchListTile(
            title: const Text('¿Tiene cuenta bancaria?'),
            subtitle: const Text('¿Posee cuenta en algún banco?'),
            value: _hasBankAccount,
            onChanged: (bool value) {
              setState(() {
                _hasBankAccount = value;
              });
            },
          ),

          if (_hasBankAccount) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del banco',
                border: OutlineInputBorder(),
                hintText: 'Ej: Banco Nacional, BAC, etc.',
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Garantías
          Text(
            'Garantías',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          SwitchListTile(
            title: const Text('¿Posee garantías?'),
            subtitle: const Text('Propiedades, vehículos u otros bienes'),
            value: _hasCollateral,
            onChanged: (bool value) {
              setState(() {
                _hasCollateral = value;
              });
            },
          ),

          if (_hasCollateral) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _collateralDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción de garantías',
                border: OutlineInputBorder(),
                hintText: 'Describa brevemente sus garantías',
              ),
              maxLines: 2,
            ),
          ],

          const SizedBox(height: 24),

          // Referencias personales
          Text(
            'Referencias Personales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _reference1NameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de referencia 1',
              border: OutlineInputBorder(),
              hintText: 'Nombre completo',
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _reference1PhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono de referencia 1',
              border: OutlineInputBorder(),
              hintText: 'Número de teléfono',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _reference2NameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de referencia 2',
              border: OutlineInputBorder(),
              hintText: 'Nombre completo',
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _reference2PhoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono de referencia 2',
              border: OutlineInputBorder(),
              hintText: 'Número de teléfono',
            ),
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 24),

          // Comentarios adicionales
          Text(
            'Información Adicional',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _additionalCommentsController,
            decoration: const InputDecoration(
              labelText: 'Comentarios adicionales (opcional)',
              border: OutlineInputBorder(),
              hintText: 'Información adicional que considere relevante',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildConsentsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consentimientos y Autorización',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Importante: Para procesar tu solicitud de crédito, necesitamos tu autorización explícita para los siguientes puntos.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),

          CheckboxListTile(
            title: const Text('Acepto los Términos y Condiciones'),
            subtitle: const Text(
              'He leído y acepto los términos y condiciones del servicio de crédito.',
            ),
            value: _acceptTerms,
            onChanged: (bool? value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),

          CheckboxListTile(
            title: const Text('Autorizo consulta crediticia'),
            subtitle: const Text(
              'Autorizo la consulta de mi historial crediticio en centrales de riesgo.',
            ),
            value: _authorizeCreditCheck,
            onChanged: (bool? value) {
              setState(() {
                _authorizeCreditCheck = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),

          CheckboxListTile(
            title: const Text('Confirmo veracidad de la información'),
            subtitle: const Text(
              'Confirmo que toda la información proporcionada es veraz y completa.',
            ),
            value: _confirmTruthfulness,
            onChanged: (bool? value) {
              setState(() {
                _confirmTruthfulness = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          const SizedBox(height: 24),
          
          // Sección de ubicación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Ubicación para verificación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para procesar tu solicitud, necesitamos verificar tu ubicación actual. Esto nos ayuda a validar la información proporcionada.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                if (_userLocation != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubicación obtenida',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'Lat: ${_userLocation!.latitude.toStringAsFixed(6)}, Lng: ${_userLocation!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_locationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationError!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                    label: Text(_isLoadingLocation 
                      ? 'Obteniendo ubicación...' 
                      : _userLocation != null 
                        ? 'Actualizar ubicación'
                        : 'Obtener mi ubicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProductDescription(String product) {
    switch (product) {
      case 'Microcrédito':
        return 'Para pequeños negocios y emprendimientos';
      case 'Capital de trabajo':
        return 'Para financiar operaciones comerciales';
      case 'Consumo':
        return 'Para gastos personales y familiares';
      case 'Vivienda':
        return 'Para compra, construcción o mejora de vivienda';
      default:
        return '';
    }
  }
}
