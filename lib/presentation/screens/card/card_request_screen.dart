import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/entities/card.dart' as domain;
import '../../../domain/entities/account.dart';
import '../../../domain/entities/loan_application.dart';
import '../../../domain/usecases/card/request_card_usecase.dart';
import '../../../services/location_service.dart';
import '../../../widgets/location_permission_dialog.dart';
import '../../bloc/card/card_bloc.dart';
import '../../bloc/card/card_event.dart';
import '../../bloc/card/card_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';

class CardRequestScreen extends StatefulWidget {
  final List<Account> userAccounts;
  final String userId;
  final String microfinancieraId;

  const CardRequestScreen({
    super.key,
    required this.userAccounts,
    required this.userId,
    required this.microfinancieraId,
  });

  @override
  State<CardRequestScreen> createState() => _CardRequestScreenState();
}

class _CardRequestScreenState extends State<CardRequestScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers para los campos de texto
  final TextEditingController _holderNameController = TextEditingController();
  final TextEditingController _requestReasonController = TextEditingController();
  final TextEditingController _deliveryAddressController = TextEditingController();
  final TextEditingController _deliveryDistrictController = TextEditingController();
  final TextEditingController _deliveryProvinceController = TextEditingController();
  final TextEditingController _deliveryDepartmentController = TextEditingController();
  final TextEditingController _deliveryPhoneController = TextEditingController();
  final TextEditingController _dailyLimitController = TextEditingController();
  final TextEditingController _monthlyLimitController = TextEditingController();
  final TextEditingController _atmLimitController = TextEditingController();
  final TextEditingController _onlineLimitController = TextEditingController();

  // Variables de estado
  int _currentStep = 0;
  Account? _selectedAccount;
  domain.CardType _selectedCardType = domain.CardType.debit;
  domain.CardBrand _selectedCardBrand = domain.CardBrand.visa;
  bool _isContactlessEnabled = true;
  bool _isOnlineEnabled = true;
  bool _isAtmEnabled = true;
  bool _isInternationalEnabled = false;

  // Variables para ubicación - usando el nuevo sistema
  LocationData? _userLocation;
  bool _isLoadingLocation = false;
  String? _locationError;
  LocationStatus? _locationStatus;

  // Variable para controlar si hay cambios sin guardar
  bool _hasUnsavedChanges = false;

  final List<String> _stepTitles = [
    'Seleccionar Cuenta',
    'Tipo de Tarjeta',
    'Límites',
    'Información de Entrega',
    'Configuración de Seguridad'
  ];

  @override
  void initState() {
    super.initState();
    // Valores por defecto para límites
    _dailyLimitController.text = '1000';
    _monthlyLimitController.text = '10000';
    _atmLimitController.text = '500';
    _onlineLimitController.text = '2000';
    
    // Auto-llenar datos del usuario autenticado
    _populateUserData();
    
    // Agregar listeners para validación en tiempo real
    _setupTextControllerListeners();
    
    // Cargar las tarjetas del usuario al inicializar
    context.read<CardBloc>().add(CardLoadUserCards(widget.userId, widget.microfinancieraId));
  }

  void _setupTextControllerListeners() {
    final controllers = [
      _holderNameController,
      _requestReasonController,
      _deliveryAddressController,
      _deliveryDistrictController,
      _deliveryProvinceController,
      _deliveryDepartmentController,
      _deliveryPhoneController,
      _dailyLimitController,
      _monthlyLimitController,
      _atmLimitController,
      _onlineLimitController,
    ];

    for (final controller in controllers) {
      controller.addListener(() {
        setState(() {
          if (!_hasUnsavedChanges) {
            _hasUnsavedChanges = true;
          }
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
      
      // Auto-llenar nombre del titular con firstName + lastName del perfil
      if (profile != null && profile.firstName.isNotEmpty && profile.lastName.isNotEmpty) {
        _holderNameController.text = '${profile.firstName} ${profile.lastName}';
      } else if (user.displayName != null && user.displayName!.isNotEmpty) {
        _holderNameController.text = user.displayName!;
      }
      
      // Auto-llenar teléfono de entrega si está disponible en el perfil
      if (profile?.phone != null && profile!.phone!.isNotEmpty) {
        _deliveryPhoneController.text = profile.phone!;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _holderNameController.dispose();
    _requestReasonController.dispose();
    _deliveryAddressController.dispose();
    _deliveryDistrictController.dispose();
    _deliveryProvinceController.dispose();
    _deliveryDepartmentController.dispose();
    _deliveryPhoneController.dispose();
    _dailyLimitController.dispose();
    _monthlyLimitController.dispose();
    _atmLimitController.dispose();
    _onlineLimitController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text(
          'Tienes información sin guardar. Si sales ahora, se perderán todos los datos ingresados. ¿Estás seguro de que quieres continuar?'
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
    if (_currentStep < 4 && _canProceedToNextStep()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else if (!_canProceedToNextStep()) {
      _showValidationError();
    }
  }

  void _showValidationError() {
    String message = '';
    switch (_currentStep) {
      case 0:
        message = 'Por favor selecciona una cuenta';
        break;
      case 1:
        message = 'Por favor completa el nombre del titular';
        break;
      case 2:
        message = 'Por favor completa todos los límites con valores válidos';
        break;
      case 3:
        message = 'Por favor completa todos los campos de información de entrega';
        break;
      case 4:
        message = 'Por favor revisa la configuración de seguridad';
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

  bool _isValidAmount(String amount) {
    if (amount.isEmpty) return false;
    final value = double.tryParse(amount);
    return value != null && value > 0;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate() && _selectedAccount != null) {
      final params = RequestCardParams(
        userId: widget.userId,
        accountId: _selectedAccount!.id,
        microfinancieraId: widget.microfinancieraId,
        cardType: _selectedCardType,
        cardBrand: _selectedCardBrand,
        holderName: _holderNameController.text,
        dailyLimit: double.tryParse(_dailyLimitController.text),
        monthlyLimit: double.tryParse(_monthlyLimitController.text),
        atmLimit: double.tryParse(_atmLimitController.text),
        onlineLimit: double.tryParse(_onlineLimitController.text),
        requestReason: _requestReasonController.text,
        deliveryAddress: _deliveryAddressController.text,
        deliveryDistrict: _deliveryDistrictController.text,
        deliveryProvince: _deliveryProvinceController.text,
        deliveryDepartment: _deliveryDepartmentController.text,
        deliveryPhone: _deliveryPhoneController.text,
        additionalComments: null,
        isContactlessEnabled: _isContactlessEnabled,
        isOnlineEnabled: _isOnlineEnabled,
        isAtmEnabled: _isAtmEnabled,
        isInternationalEnabled: _isInternationalEnabled,
      );

      context.read<CardBloc>().add(CardRequest(params));
      
      // Mostrar mensaje de éxito y volver
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de tarjeta enviada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Marcar como guardado para evitar la advertencia
      _hasUnsavedChanges = false;
      Navigator.of(context).pop();
    }
  }

  Future<void> _getCurrentLocationWithAutoRequest() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
      _locationStatus = null;
    });

    try {
      LocationResult result = await LocationService.getCurrentLocationWithCheck();
      
      setState(() {
        _locationStatus = result.status;
        _isLoadingLocation = false;
      });

      if (result.status == LocationStatus.enabled && result.data != null) {
        setState(() {
          _userLocation = result.data;
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
                _locationError = 'Ubicación requerida para procesar la solicitud';
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_stepTitles[_currentStep]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(8.0),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildAccountSelectionStep(),
              _buildCardTypeStep(),
              _buildLimitsStep(),
              _buildDeliveryStep(),
              _buildSecurityStep(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Anterior'),
                )
              else
                const SizedBox(),
              ElevatedButton(
                onPressed: _canProceedToNextStep() 
                    ? (_currentStep == 4 ? _submitRequest : _nextStep)
                    : null,
                child: Text(_currentStep == 4 ? 'Solicitar Tarjeta' : 'Siguiente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona la cuenta a la que deseas asociar la tarjeta:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_selectedAccount == null && _currentStep > 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Debes seleccionar una cuenta',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
          
          if (widget.userAccounts.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No tienes cuentas disponibles para asociar una tarjeta.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: widget.userAccounts.length,
                itemBuilder: (context, index) {
                  final account = widget.userAccounts[index];
                  final isActive = account.status == AccountStatus.active;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: RadioListTile<Account>(
                      title: Text('${account.accountType.displayName} - ${_maskAccountNumber(account.accountNumber, account.status)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo: ${account.currency} ${account.balance.toStringAsFixed(2)}'),
                          Text(
                            'Estado: ${account.status.displayName}',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isActive)
                            const Text(
                              'Solo las cuentas activas pueden tener tarjetas asociadas',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                        ],
                      ),
                      value: account,
                      groupValue: _selectedAccount,
                      onChanged: isActive
                          ? (Account? value) {
                              setState(() {
                                _selectedAccount = value;
                                _markAsChanged();
                              });
                            }
                          : null,
                      selected: _selectedAccount == account,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configura los detalles de tu tarjeta:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          
          // Nombre del titular
          TextFormField(
            controller: _holderNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del titular *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el nombre del titular';
              }
              return null;
            },
            onChanged: (_) {
              setState(() {});
              _markAsChanged();
            },
          ),
          const SizedBox(height: 24),

          // Tipo de tarjeta
          Text(
            'Tipo de Tarjeta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...domain.CardType.values.map((type) => RadioListTile<domain.CardType>(
            title: Text(type.displayName),
            subtitle: Text(_getCardTypeDescription(type)),
            value: type,
            groupValue: _selectedCardType,
            onChanged: (domain.CardType? value) {
              setState(() {
                _selectedCardType = value!;
                if (_selectedCardType == domain.CardType.debit) {
                  if (_selectedCardBrand != domain.CardBrand.visa && 
                      _selectedCardBrand != domain.CardBrand.mastercard) {
                    _selectedCardBrand = domain.CardBrand.visa;
                  }
                }
                _markAsChanged();
              });
            },
          )),
          
          const SizedBox(height: 16),
          
          // Marca de tarjeta
          Text(
            'Marca de Tarjeta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<domain.CardBrand>(
            value: _selectedCardBrand,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _getAvailableCardBrands().map((brand) => DropdownMenuItem(
              value: brand,
              child: Text(brand.displayName),
            )).toList(),
            onChanged: (domain.CardBrand? value) {
              setState(() {
                _selectedCardBrand = value!;
                _markAsChanged();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configura los límites para tu tarjeta:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _dailyLimitController,
            decoration: const InputDecoration(
              labelText: 'Límite diario (S/) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el límite diario';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Por favor ingresa un monto válido';
              }
              return null;
            },
            onChanged: (_) {
              setState(() {});
              _markAsChanged();
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _monthlyLimitController,
            decoration: const InputDecoration(
              labelText: 'Límite mensual (S/) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el límite mensual';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Por favor ingresa un monto válido';
              }
              return null;
            },
            onChanged: (_) {
              setState(() {});
              _markAsChanged();
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _atmLimitController,
            decoration: const InputDecoration(
              labelText: 'Límite ATM (S/) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el límite ATM';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Por favor ingresa un monto válido';
              }
              return null;
            },
            onChanged: (_) {
              setState(() {});
              _markAsChanged();
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _onlineLimitController,
            decoration: const InputDecoration(
              labelText: 'Límite compras online (S/) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el límite online';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Por favor ingresa un monto válido';
              }
              return null;
            },
            onChanged: (_) {
              setState(() {});
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información para la entrega de tu tarjeta:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          
          // Motivo de solicitud
          TextFormField(
            controller: _requestReasonController,
            decoration: const InputDecoration(
              labelText: 'Motivo de solicitud *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el motivo de solicitud';
              }
              return null;
            },
            onChanged: (_) => _markAsChanged(),
          ),
          const SizedBox(height: 16),
          
          // Dirección de entrega
          TextFormField(
            controller: _deliveryAddressController,
            decoration: const InputDecoration(
              labelText: 'Dirección de entrega *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa la dirección de entrega';
              }
              return null;
            },
            onChanged: (_) => _markAsChanged(),
          ),
          const SizedBox(height: 16),
          
          // Distrito y Provincia en fila
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _deliveryDistrictController,
                  decoration: const InputDecoration(
                    labelText: 'Distrito *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                  onChanged: (_) => _markAsChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _deliveryProvinceController,
                  decoration: const InputDecoration(
                    labelText: 'Provincia *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                  onChanged: (_) => _markAsChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Departamento y Teléfono en fila
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _deliveryDepartmentController,
                  decoration: const InputDecoration(
                    labelText: 'Departamento *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                  onChanged: (_) => _markAsChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _deliveryPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de contacto *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                  onChanged: (_) => _markAsChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sistema de ubicación mejorado
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
                      'Ubicación para entrega',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para procesar tu solicitud de tarjeta, necesitamos verificar tu ubicación actual.',
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
                    onPressed: _isLoadingLocation ? null : _getCurrentLocationWithAutoRequest,
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

  Widget _buildSecurityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configura las funcionalidades de tu tarjeta:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          
          SwitchListTile(
            title: const Text('Pagos sin contacto'),
            subtitle: const Text('Permite pagos por aproximación'),
            value: _isContactlessEnabled,
            onChanged: (bool value) {
              setState(() {
                _isContactlessEnabled = value;
                _markAsChanged();
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Compras online'),
            subtitle: const Text('Permite compras por internet'),
            value: _isOnlineEnabled,
            onChanged: (bool value) {
              setState(() {
                _isOnlineEnabled = value;
                _markAsChanged();
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Retiros en ATM'),
            subtitle: const Text('Permite retiros en cajeros automáticos'),
            value: _isAtmEnabled,
            onChanged: (bool value) {
              setState(() {
                _isAtmEnabled = value;
                _markAsChanged();
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Transacciones internacionales'),
            subtitle: const Text('Permite uso fuera del país'),
            value: _isInternationalEnabled,
            onChanged: (bool value) {
              setState(() {
                _isInternationalEnabled = value;
                _markAsChanged();
              });
            },
          ),
        ],
      ),
    );
  }

  String _getCardTypeDescription(domain.CardType type) {
    switch (type) {
      case domain.CardType.debit:
        return 'Tarjeta de débito vinculada a tu cuenta';
      case domain.CardType.credit:
        return 'Tarjeta de crédito con línea de crédito';
      case domain.CardType.prepaid:
        return 'Tarjeta prepago con saldo recargable';
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Account selection step
        return _selectedAccount != null;
        
      case 1: // Card type step
        if (_selectedAccount == null) return false;
        if (_holderNameController.text.isEmpty) return false;
        
        final cardBloc = context.read<CardBloc>();
        final cardState = cardBloc.state;
        
        if (cardState is! CardLoaded) return true;
        
        final existingCards = cardState.cards
            .where((card) => card.accountId == _selectedAccount!.id)
            .toList();

        int debitVisaCount = existingCards
            .where((card) => 
                card.cardType == domain.CardType.debit && 
                card.cardBrand == domain.CardBrand.visa &&
                card.status != domain.CardStatus.cancelled)
            .length;
        
        int debitMastercardCount = existingCards
            .where((card) => 
                card.cardType == domain.CardType.debit && 
                card.cardBrand == domain.CardBrand.mastercard &&
                card.status != domain.CardStatus.cancelled)
            .length;
        
        int totalDebitCount = debitVisaCount + debitMastercardCount;

        switch (_selectedCardType) {
          case domain.CardType.debit:
            if (totalDebitCount >= 2) return false;
            if (_selectedCardBrand == domain.CardBrand.visa && debitVisaCount > 0) {
              return false;
            }
            if (_selectedCardBrand == domain.CardBrand.mastercard && debitMastercardCount > 0) {
              return false;
            }
            return true;
          case domain.CardType.credit:
            return true;
          case domain.CardType.prepaid:
            return true;
        }
        
      case 2: // Limits step
        return _dailyLimitController.text.isNotEmpty &&
               _monthlyLimitController.text.isNotEmpty &&
               _atmLimitController.text.isNotEmpty &&
               _onlineLimitController.text.isNotEmpty &&
               double.tryParse(_dailyLimitController.text) != null &&
               double.tryParse(_monthlyLimitController.text) != null &&
               double.tryParse(_atmLimitController.text) != null &&
               double.tryParse(_onlineLimitController.text) != null &&
               double.parse(_dailyLimitController.text) > 0 &&
               double.parse(_monthlyLimitController.text) > 0 &&
               double.parse(_atmLimitController.text) > 0 &&
               double.parse(_onlineLimitController.text) > 0;
               
      case 3: // Delivery step
        return _requestReasonController.text.isNotEmpty &&
               _deliveryAddressController.text.isNotEmpty &&
               _deliveryDistrictController.text.isNotEmpty &&
               _deliveryProvinceController.text.isNotEmpty &&
               _deliveryDepartmentController.text.isNotEmpty &&
               _deliveryPhoneController.text.isNotEmpty;
               
      case 4: // Security step
        return true;
        
      default:
        return true;
    }
  }

  List<domain.CardBrand> _getAvailableCardBrands() {
    if (_selectedCardType == domain.CardType.debit) {
      return [domain.CardBrand.visa, domain.CardBrand.mastercard];
    } else {
      return domain.CardBrand.values;
    }
  }

  // Funciones para enmascarar números sensibles
  String _maskAccountNumber(String accountNumber, AccountStatus status) {
    if (status == AccountStatus.active) {
      return accountNumber;
    }
    return '*' * accountNumber.length;
  }
}