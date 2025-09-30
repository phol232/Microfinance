import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        final isLoading = state.isLoading && profile == null;
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  RepaintBoundary(
                    child: _WelcomeCard(
                      userName: profile?.firstName ?? 'Usuario',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const RepaintBoundary(child: _StatsCards()),
                  const SizedBox(height: 24),
                  const RepaintBoundary(child: _QuickActions()),
                  const SizedBox(height: 24),
                  const RepaintBoundary(child: _RecentActivity()),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : (hour < 18 ? 'Buenas tardes' : 'Buenas noches');

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $userName! 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bienvenido a CréditoExpress',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  const _StatsCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Expanded(child: _StatCard(title: 'Clientes activos', value: '128')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Solicitudes pendientes', value: '24')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Préstamos en seguimiento', value: '56')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rápidas',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _QuickActionChip(
              icon: Icons.person_add_alt,
              label: 'Nuevo cliente',
            ),
            _QuickActionChip(
              icon: Icons.assignment,
              label: 'Nueva solicitud',
            ),
            _QuickActionChip(
              icon: Icons.attach_money,
              label: 'Registrar pago',
            ),
            _QuickActionChip(
              icon: Icons.bar_chart,
              label: 'Ver reportes',
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {},
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    final items = List.generate(4, (index) {
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text('Cliente ${index + 1} actualizado'),
        subtitle: const Text('Hace 2 horas'),
        trailing: Chip(
          label: Text(index.isEven ? 'Aprobado' : 'En revisión'),
          backgroundColor:
              index.isEven ? Colors.green.withOpacity(0.1) : Colors.orange[50],
        ),
      );
    });

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Actividad reciente',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}
