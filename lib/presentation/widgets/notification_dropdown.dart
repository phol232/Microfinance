// TODO: Implementar widget de dropdown de notificaciones más adelante
// Archivo completo comentado para implementación futura

/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../domain/entities/notification.dart';

class NotificationDropdown extends StatefulWidget {
  final Offset buttonOffset;
  final Size buttonSize;
  final VoidCallback onClose;

  const NotificationDropdown({
    super.key,
    required this.buttonOffset,
    required this.buttonSize,
    required this.onClose,
  });

  @override
  State<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<NotificationDropdown>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeDropdown() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const dropdownWidth = 380.0;
    const dropdownHeight = 500.0;
    const arrowSize = 12.0;

    // Calcular posición del dropdown
    double left = widget.buttonOffset.dx + widget.buttonSize.width / 2 - dropdownWidth / 2;
    double top = widget.buttonOffset.dy + widget.buttonSize.height + arrowSize;

    // Ajustar si se sale de la pantalla
    if (left < 16) left = 16;
    if (left + dropdownWidth > screenSize.width - 16) {
      left = screenSize.width - dropdownWidth - 16;
    }

    if (top + dropdownHeight > screenSize.height - 16) {
      top = widget.buttonOffset.dy - dropdownHeight - arrowSize;
    }

    // Calcular posición de la flecha
    final arrowLeft = widget.buttonOffset.dx + widget.buttonSize.width / 2 - left - arrowSize / 2;

    return Stack(
      children: [
        // Overlay para cerrar al tocar fuera
        Positioned.fill(
          child: GestureDetector(
            onTap: _closeDropdown,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        
        // Dropdown principal
        Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.transparent,
                      child: Container(
                        width: dropdownWidth,
                        height: dropdownHeight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.notifications_outlined,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Notificaciones',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  StreamBuilder<List<AppNotification>>(
                                    stream: NotificationService.notificationListStream,
                                    builder: (context, snapshot) {
                                      final unreadCount = snapshot.hasData 
                                          ? snapshot.data!.where((n) => !n.isRead).length
                                          : 0;
                                      
                                      if (unreadCount > 0) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.error,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            unreadCount.toString(),
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onError,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _closeDropdown,
                                    icon: Icon(
                                      Icons.close,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Lista de notificaciones
                            Expanded(
                              child: StreamBuilder<List<AppNotification>>(
                                stream: NotificationService.notificationListStream,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Error al cargar notificaciones',
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () {
                                              // Recargar notificaciones
                                            },
                                            child: const Text('Reintentar'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final notifications = snapshot.data ?? [];

                                  if (notifications.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.notifications_none_outlined,
                                            size: 64,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No hay notificaciones',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Te notificaremos cuando tengas algo nuevo',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: notifications.length,
                                    separatorBuilder: (context, index) => Divider(
                                      height: 1,
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    ),
                                    itemBuilder: (context, index) {
                                      final notification = notifications[index];
                                      return _NotificationItem(
                                        notification: notification,
                                        onTap: () => _handleNotificationTap(notification),
                                        onDismiss: () => _handleNotificationDismiss(notification),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            
                            // Footer con acciones
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        await NotificationService.markAllAsRead();
                                      },
                                      icon: const Icon(Icons.done_all, size: 18),
                                      label: const Text('Marcar todas como leídas'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      _closeDropdown();
                                      // Navegar a pantalla de notificaciones completa
                                    },
                                    icon: const Icon(Icons.open_in_new, size: 18),
                                    label: const Text('Ver todas'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Flecha indicadora
        Positioned(
          left: left + arrowLeft,
          top: top > widget.buttonOffset.dy ? top - arrowSize : top + dropdownHeight,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: CustomPaint(
                  size: const Size(arrowSize * 2, arrowSize),
                  painter: _ArrowPainter(
                    color: Theme.of(context).colorScheme.surface,
                    borderColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    pointingUp: top > widget.buttonOffset.dy,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Marcar como leída si no lo está
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
    }

    // Procesar acción de la notificación
    if (notification.actionUrl != null) {
      // Navegar según la URL de acción
      print('Navegando a: ${notification.actionUrl}');
    }

    _closeDropdown();
  }

  void _handleNotificationDismiss(AppNotification notification) async {
    await NotificationService.deleteNotification(notification.id);
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono de tipo de notificación
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(),
                  color: _getNotificationColor(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Contenido de la notificación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              color: notification.isRead 
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: notification.isRead 
                            ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatTime(notification.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notification.typeDisplayName,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getNotificationColor(context),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
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

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.accountActivated:
        return Icons.account_balance_outlined;
      case NotificationType.cardActivated:
        return Icons.credit_card_outlined;
      case NotificationType.loanApproved:
        return Icons.check_circle_outline;
      case NotificationType.loanRejected:
        return Icons.cancel_outlined;
      case NotificationType.paymentReminder:
        return Icons.schedule_outlined;
      case NotificationType.general:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(BuildContext context) {
    switch (notification.type) {
      case NotificationType.accountActivated:
        return Colors.green;
      case NotificationType.cardActivated:
        return Colors.blue;
      case NotificationType.loanApproved:
        return Colors.green;
      case NotificationType.loanRejected:
        return Colors.red;
      case NotificationType.paymentReminder:
        return Colors.orange;
      case NotificationType.general:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool pointingUp;

  _ArrowPainter({
    required this.color,
    required this.borderColor,
    required this.pointingUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();

    if (pointingUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
*/