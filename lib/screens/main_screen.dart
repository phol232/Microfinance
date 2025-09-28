import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../login_screen.dart';
import 'home_screen.dart';
import 'clients_screen.dart';
import 'loans_screen.dart';
import 'applications_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  String _appBarTitle = 'Inicio';
  UserProfile? _userProfile;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ClientsScreen(),
    const LoansScreen(),
    const ApplicationsScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _screenTitles = [
    'Inicio',
    'Clientes',
    'Préstamos',
    'Solicitudes',
    'Reportes',
    'Configuración',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Header del drawer
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[600]!, Colors.blue[800]!],
              ),
            ),
            child: DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar del usuario
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: _userProfile?.photoUrl != null
                        ? NetworkImage(_userProfile!.photoUrl!)
                        : null,
                    child: _userProfile?.photoUrl == null
                        ? Text(
                            _getInitials(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Nombre del usuario
                  Text(
                    _userProfile?.fullName ?? user?.displayName ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email del usuario
                  Text(
                    _userProfile?.email ?? user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Opciones del menú
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(icon: Icons.home, title: 'Inicio', index: 0),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Clientes',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Préstamos',
                  index: 2,
                ),
                _buildDrawerItem(
                  icon: Icons.description,
                  title: 'Solicitudes',
                  index: 3,
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Reportes',
                  index: 4,
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Configuración',
                  index: 5,
                ),
              ],
            ),
          ),

          // Botón de cerrar sesión
          const Divider(),
          Container(
            margin: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue[600] : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue[600] : Colors.grey[800],
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _appBarTitle = _screenTitles[index];
        });
        Navigator.pop(context);
      },
    );
  }

  String _getInitials() {
    if (_userProfile != null) {
      final firstName = _userProfile!.firstName;
      final lastName = _userProfile!.lastName;
      return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null) {
      final parts = user!.displayName!.split(' ');
      return '${parts.isNotEmpty ? parts[0][0] : ''}${parts.length > 1 ? parts[1][0] : ''}'
          .toUpperCase();
    }

    return user?.email?[0].toUpperCase() ?? 'U';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
