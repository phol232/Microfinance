import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _photoUrlController = TextEditingController();

  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        final profile = await _authService.getUserProfile(user.uid);
        if (mounted && profile != null) {
          setState(() {
            _userProfile = profile;
            _firstNameController.text = profile.firstName;
            _lastNameController.text = profile.lastName;
            _dniController.text = profile.dni ?? '';
            _phoneController.text = profile.phone ?? '';
            _photoUrlController.text = profile.photoUrl ?? '';
          });
        }
      } catch (e) {
        _showSnackBar('Error cargando perfil: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Verificar DNI duplicado solo si cambió
      final newDni = _dniController.text.trim();
      if (newDni.isNotEmpty && newDni != _userProfile?.dni) {
        final dniExists = await _authService.checkDniExists(newDni);
        if (dniExists) {
          _showSnackBar(
            'Este DNI ya está registrado por otro usuario',
            isError: true,
          );
          return;
        }
      }

      final updates = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'fullName':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'dni': newDni.isNotEmpty ? newDni : null,
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'photoUrl': _photoUrlController.text.trim().isNotEmpty
            ? _photoUrlController.text.trim()
            : null,
      };

      await _authService.updateUserProfile(user.uid, updates);

      setState(() => _isEditing = false);
      _showSnackBar('Perfil actualizado correctamente');
      await _loadUserProfile();
    } catch (e) {
      _showSnackBar('Error actualizando perfil: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar y info básica
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Formulario de edición
            if (_isEditing) _buildEditForm() else _buildProfileInfo(),
          ],
        ),
      ),
      floatingActionButton: _isEditing
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "cancel",
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _loadUserProfile(); // Restaurar valores originales
                  },
                  backgroundColor: Colors.grey,
                  child: const Icon(Icons.close),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: "save",
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Icon(Icons.save),
                ),
              ],
            )
          : FloatingActionButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Icon(Icons.edit),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[300],
          backgroundImage:
              _userProfile?.photoUrl != null &&
                  _userProfile!.photoUrl!.isNotEmpty
              ? NetworkImage(_userProfile!.photoUrl!)
              : null,
          child:
              _userProfile?.photoUrl == null || _userProfile!.photoUrl!.isEmpty
              ? Text(
                  _getInitials(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Nombre completo
        Text(
          _userProfile?.fullName ?? 'Usuario',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          _userProfile?.email ?? '',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildInfoRow('Nombre:', _userProfile?.firstName ?? ''),
            _buildInfoRow('Apellido:', _userProfile?.lastName ?? ''),
            _buildInfoRow('DNI/NIE:', _userProfile?.dni ?? 'No especificado'),
            _buildInfoRow(
              'Teléfono:',
              _userProfile?.phone ?? 'No especificado',
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
                label: const Text('Editar Perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar Perfil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Nombres en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu apellido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // DNI
              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(
                  labelText: 'DNI/NIE',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 8 || value.trim().length > 12) {
                      return 'DNI debe tener entre 8 y 12 caracteres';
                    }
                    if (!RegExp(r'^[0-9]+[A-Z]?$').hasMatch(value.trim())) {
                      return 'Formato de DNI inválido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final cleanValue = value.trim().replaceAll(
                      RegExp(r'[^0-9+]'),
                      '',
                    );
                    if (cleanValue.length < 9 || cleanValue.length > 15) {
                      return 'Teléfono debe tener entre 9 y 15 dígitos';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // URL de foto
              TextFormField(
                controller: _photoUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL de Foto de Perfil',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _loadUserProfile();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (_userProfile != null) {
      final firstName = _userProfile!.firstName;
      final lastName = _userProfile!.lastName;
      return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();
    }
    return 'U';
  }
}
