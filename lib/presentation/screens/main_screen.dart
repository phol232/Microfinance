import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_event.dart';
import '../bloc/profile/profile_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'applications_screen.dart';
import 'clients_screen.dart';
import 'home_screen.dart';
import 'loans_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ClientsScreen(),
    const LoansScreen(),
    const ApplicationsScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _screenTitles = const [
    'Inicio',
    'Clientes',
    'Préstamos',
    'Solicitudes',
    'Reportes',
    'Configuración',
  ];

  String get _currentTitle => _screenTitles[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _requestProfile();
  }

  void _requestProfile() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final profileBloc = context.read<ProfileBloc>();
      final profileState = profileBloc.state;
      final bool alreadyLoading =
          profileState.isLoading && profileState.profile?.uid == authState.user.uid;
      final bool alreadyLoaded =
          profileState.profile?.uid == authState.user.uid &&
          profileState.status != ProfileStatus.error;

      if (alreadyLoading || alreadyLoaded) {
        return;
      }

      profileBloc.add(ProfileLoadRequested(uid: authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final AppUser? user =
        authState is AuthAuthenticated ? authState.user : null;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _requestProfile();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWideScreen =
              constraints.maxWidth > AppSpacing.tabletBreakpoint;

          if (isWideScreen) {
            return _buildWideScreenLayout(context, user);
          } else {
            return _buildMobileLayout(context, user);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppUser? user) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTitle,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.outline.withOpacity(0.1),
      ),
      drawer: _buildDrawer(context, user),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar:
          _selectedIndex < 5 ? _buildBottomNavigation() : null,
    );
  }

  Widget _buildWideScreenLayout(BuildContext context, AppUser? user) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(user),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currentTitle,
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _buildUserActions(user),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withOpacity(0.1),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        const NavigationDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people),
          label: 'Clientes',
        ),
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Préstamos',
        ),
        const NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Solicitudes',
        ),
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Reportes',
        ),
      ],
    );
  }

  Widget _buildNavigationRail(AppUser? user) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withOpacity(0.1),
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: BlocSelector<ProfileBloc, ProfileState, UserProfile?>(
          selector: (state) => state.profile,
          builder: (context, profile) => _buildUserAvatar(
            user,
            profile,
            radius: 24,
          ),
        ),
      ),
      trailing: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 5; // Configuración
                  });
                },
                icon: Icon(
                  _selectedIndex == 5 ? Icons.settings : Icons.settings_outlined,
                  color: _selectedIndex == 5
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                tooltip: 'Configuración',
              ),
            ],
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Inicio'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people),
          label: Text('Clientes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text('Préstamos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: Text('Solicitudes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Reportes'),
        ),
      ],
    );
  }

  Widget _buildUserActions(AppUser? user) {
    return Row(
      children: [
        BlocSelector<ProfileBloc, ProfileState, UserProfile?>(
          selector: (state) => state.profile,
          builder: (context, profile) => _buildUserAvatar(user, profile),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          onPressed: _showLogoutDialog,
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildUserAvatar(
    AppUser? user,
    UserProfile? profile, {
    double radius = 20,
  }) {
    final String initials = _getInitials(user, profile: profile);
    final String? photoUrl = profile?.photoUrl;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage:
          photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: (photoUrl == null || photoUrl.isEmpty)
          ? Text(
              initials,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context, AppUser? user) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => previous.profile != current.profile,
      builder: (context, state) {
        final profile = state.profile;
        final displayName = profile?.fullName ?? user?.displayName ?? 'Usuario';
        final email = profile?.email ?? user?.email ?? '';

        return Drawer(
          backgroundColor: AppColors.surface,
          child: Column(
            children: [
              // Header section with profile info
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: 120,
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppSpacing.radiusXl),
                    bottomRight: Radius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: SafeArea(
                  top: true,
                  left: true,
                  right: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.onPrimary.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: _buildUserAvatar(
                                user,
                                profile,
                                radius: 25,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    style: AppTypography.titleLarge.copyWith(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    email,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.onPrimary.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.onPrimary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                              ),
                              child: Text(
                                'Asesor financiero',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() => _selectedIndex = 5);
                              },
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Navigation items - flexible height
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      title: 'Inicio',
                      index: 0,
                    ),
                    _buildDrawerItem(
                      icon: Icons.people_outlined,
                      selectedIcon: Icons.people,
                      title: 'Clientes',
                      index: 1,
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance_wallet_outlined,
                      selectedIcon: Icons.account_balance_wallet,
                      title: 'Préstamos',
                      index: 2,
                    ),
                    _buildDrawerItem(
                      icon: Icons.description_outlined,
                      selectedIcon: Icons.description,
                      title: 'Solicitudes',
                      index: 3,
                    ),
                    _buildDrawerItem(
                      icon: Icons.analytics_outlined,
                      selectedIcon: Icons.analytics,
                      title: 'Reportes',
                      index: 4,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(
                      color: AppColors.outline.withOpacity(0.5),
                      thickness: 1,
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDrawerItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      title: 'Configuración',
                      index: 5,
                    ),
                  ],
                ),
              ),

              // Bottom logout section
              Container(
                margin: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                ),
                child: Material(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: _showLogoutDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_outlined,
                            color: AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Text(
                            'Cerrar Sesión',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    IconData? selectedIcon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Material(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () {
            if (_selectedIndex != index) {
              setState(() => _selectedIndex = index);
            }
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    isSelected ? (selectedIcon ?? icon) : icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(AppUser? user, {UserProfile? profile}) {
    final firstName = profile?.firstName;
    final lastName = profile?.lastName;
    if (firstName != null && firstName.isNotEmpty) {
      final secondLetter = (lastName != null && lastName.isNotEmpty)
          ? lastName[0]
          : (firstName.length > 1 ? firstName[1] : '');
      return '${firstName[0]}$secondLetter'.toUpperCase();
    }

    final displayName = user?.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      final first = parts.isNotEmpty ? parts[0] : '';
      final second = parts.length > 1 ? parts[1] : '';
      final initials =
          '${first.isNotEmpty ? first[0] : ''}${second.isNotEmpty ? second[0] : ''}';
      if (initials.trim().isNotEmpty) {
        return initials.toUpperCase();
      }
    }

    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return 'U';
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
                context
                    .read<AuthBloc>()
                    .add(const AuthLogoutRequested());
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
