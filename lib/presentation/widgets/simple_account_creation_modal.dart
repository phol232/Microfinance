import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/account/create_account_usecase.dart';
import '../bloc/account/account_bloc.dart';
import '../bloc/account/account_event.dart';
import '../bloc/account/account_state.dart';

class SimpleAccountCreationModal extends StatefulWidget {
  final String userId;
  final String microfinancieraId;

  const SimpleAccountCreationModal({
    super.key,
    required this.userId,
    required this.microfinancieraId,
  });

  @override
  State<SimpleAccountCreationModal> createState() => _SimpleAccountCreationModalState();
}

class _SimpleAccountCreationModalState extends State<SimpleAccountCreationModal> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Controladores para los campos básicos
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _departmentController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();

  // Variables de estado
  AccountType _selectedAccountType = AccountType.savings;
  String _selectedCurrency = 'PEN';
  EmploymentType _selectedEmploymentType = EmploymentType.employed;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _departmentController.dispose();
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

  bool _canContinue() {
    switch (_currentStep) {
      case 0: // Tipo de cuenta
        return _selectedAccountType != null; // Requiere selección de tipo de cuenta
      case 1: // Información personal
        return _firstNameController.text.isNotEmpty &&
               _lastNameController.text.isNotEmpty &&
               _dniController.text.isNotEmpty &&
               _phoneController.text.isNotEmpty &&
               _emailController.text.isNotEmpty;
      case 2: // Dirección
        return _addressController.text.isNotEmpty &&
               _districtController.text.isNotEmpty &&
               _provinceController.text.isNotEmpty &&
               _departmentController.text.isNotEmpty;
      case 3: // Información laboral
        return _selectedEmploymentType != null && // Requiere selección de tipo de empleo
               _monthlyIncomeController.text.isNotEmpty;
      default:
        return false;
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
      monthlyIncome: double.tryParse(_monthlyIncomeController.text),
    );

    context.read<AccountBloc>().add(AccountCreate(params));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountCreated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProgressIndicator(),
              const SizedBox(height: 24),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAccountTypeStep(),
                    _buildPersonalInfoStep(),
                    _buildAddressStep(),
                    _buildEmploymentStep(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Crear Nueva Cuenta',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAccountTypeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso 1: Tipo de Cuenta',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Selecciona el tipo de cuenta que deseas crear: *',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Mostrar error si no se ha seleccionado tipo de cuenta
          if (_selectedAccountType == null && _currentStep > 0)
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
                    'Debes seleccionar un tipo de cuenta',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Account type selection
          ...AccountType.values.map((type) => RadioListTile<AccountType>(
            title: Text(_getAccountTypeDisplayName(type)),
            subtitle: Text(_getAccountTypeDescription(type)),
            value: type,
            groupValue: _selectedAccountType,
            onChanged: (value) {
              setState(() {
                _selectedAccountType = value!;
              });
            },
          )),
          
          const SizedBox(height: 24),
          
          Text(
            'Moneda: *',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Moneda',
            ),
            items: const [
              DropdownMenuItem(value: 'PEN', child: Text('Soles (PEN)')),
              DropdownMenuItem(value: 'USD', child: Text('Dólares (USD)')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCurrency = value!;
              });
            },
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
            'Paso 2: Información Personal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Nombres *',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Apellidos *',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _dniController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'DNI *',
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Teléfono *',
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email *',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso 3: Dirección',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Dirección *',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _districtController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Distrito *',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _provinceController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Provincia *',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Departamento *',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso 4: Información Laboral',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Tipo de empleo: *',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Mostrar error si no se ha seleccionado tipo de empleo
          if (_selectedEmploymentType == null && _currentStep > 3)
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
                    'Debes seleccionar un tipo de empleo',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
          
          DropdownButtonFormField<EmploymentType>(
            value: _selectedEmploymentType,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Tipo de empleo',
              errorText: _selectedEmploymentType == null && _currentStep > 3 
                  ? 'Campo requerido' 
                  : null,
            ),
            items: EmploymentType.values.map((type) => DropdownMenuItem(
              value: type,
              child: Text(_getEmploymentTypeDisplayName(type)),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEmploymentType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _monthlyIncomeController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Ingresos mensuales *',
              prefixText: 'S/ ',
              errorText: _monthlyIncomeController.text.isEmpty && _currentStep > 3
                  ? 'Campo requerido'
                  : null,
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        final isLoading = state is AccountCreating;
        
        return Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : _previousStep,
                  child: const Text('Anterior'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : (_currentStep == _totalSteps - 1 
                  ? (_canContinue() ? _submitForm : null)
                  : (_canContinue() ? _nextStep : null)),
                child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == _totalSteps - 1 ? 'Crear Cuenta' : 'Siguiente'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getAccountTypeDisplayName(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return 'Cuenta de Ahorros';
      case AccountType.checking:
        return 'Cuenta Corriente';
      case AccountType.fixedDeposit:
        return 'Depósito a Plazo Fijo';
      case AccountType.microCredit:
        return 'Microcrédito';
    }
  }

  String _getAccountTypeDescription(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return 'Para ahorrar dinero con intereses';
      case AccountType.checking:
        return 'Para transacciones diarias';
      case AccountType.fixedDeposit:
        return 'Para inversiones a largo plazo';
      case AccountType.microCredit:
        return 'Para solicitar microcréditos';
    }
  }

  String _getEmploymentTypeDisplayName(EmploymentType type) {
    switch (type) {
      case EmploymentType.employed:
        return 'Empleado';
      case EmploymentType.selfEmployed:
        return 'Independiente';
      case EmploymentType.business:
        return 'Empresario';
      case EmploymentType.unemployed:
        return 'Desempleado';
      case EmploymentType.retired:
        return 'Jubilado';
      case EmploymentType.student:
        return 'Estudiante';
    }
  }
}