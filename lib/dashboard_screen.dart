import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'login_screen.dart';

class DatabaseSetupScreen extends StatefulWidget {
  const DatabaseSetupScreen({super.key});

  @override
  State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
}

class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  Map<String, dynamic>? _profileData;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToAuth() {
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      setState(() {
        _currentUser = user;
      });
      _subscribeToProfile(user);
    });

    final initialUser = _authService.currentUser;
    if (initialUser != null) {
      setState(() {
        _currentUser = initialUser;
      });
      _subscribeToProfile(initialUser);
    }
  }

  void _subscribeToProfile(User? user) {
    _profileSubscription?.cancel();

    if (user == null) {
      setState(() {
        _profileData = null;
      });
      return;
    }

    _profileSubscription = FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _profileData = snapshot.data();
      });
    }, onError: (error) {
      debugPrint('Error listening to user profile: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final profilePhoto = (_profileData?['photoUrl'] as String?)?.trim();
    final fullName = (_profileData?['fullName'] as String?)?.trim();
    final firstName = (_profileData?['firstName'] as String?)?.trim();
    final lastName = (_profileData?['lastName'] as String?)?.trim();

    final computedName = () {
      if (fullName != null && fullName.isNotEmpty) return fullName;
      final parts = <String>[];
      if (firstName != null && firstName.isNotEmpty) parts.add(firstName);
      if (lastName != null && lastName.isNotEmpty) parts.add(lastName);
      if (parts.isNotEmpty) return parts.join(' ');
      return null;
    }();

    final displayName = computedName ??
        (_currentUser?.displayName?.trim().isNotEmpty == true
            ? _currentUser?.displayName
            : _currentUser?.email) ??
        'Usuario';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                            ? NetworkImage(profilePhoto)
                            : (_currentUser?.photoURL != null
                                ? NetworkImage(_currentUser!.photoURL!)
                                : null),
                        child: (profilePhoto == null || profilePhoto.isEmpty) &&
                                _currentUser?.photoURL == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Bienvenido!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Menu Cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    children: [
                      // Clientes
                      _buildMenuCard(
                        icon: Icons.people,
                        title: 'Clientes',
                        subtitle: 'Gestionar clientes',
                        color: Colors.blue,
                        onTap: () => _comingSoon('Gestión de Clientes'),
                      ),

                      // Préstamos
                      _buildMenuCard(
                        icon: Icons.account_balance_wallet,
                        title: 'Préstamos',
                        subtitle: 'Administrar préstamos',
                        color: Colors.green,
                        onTap: () => _comingSoon('Gestión de Préstamos'),
                      ),

                      // Solicitudes
                      _buildMenuCard(
                        icon: Icons.assignment,
                        title: 'Solicitudes',
                        subtitle: 'Ver solicitudes',
                        color: Colors.orange,
                        onTap: () => _comingSoon('Gestión de Solicitudes'),
                      ),

                      // Reportes
                      _buildMenuCard(
                        icon: Icons.analytics,
                        title: 'Reportes',
                        subtitle: 'Análisis y reportes',
                        color: Colors.purple,
                        onTap: () => _comingSoon('Reportes y Análisis'),
                      ),
                    ],
                  ),
                ),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Próximamente disponible'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
