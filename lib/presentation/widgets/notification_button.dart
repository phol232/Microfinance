// TODO: Implementar sistema de notificaciones en el futuro
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../services/notification_service.dart';
// import '../../domain/entities/notification.dart';
// import 'notification_dropdown.dart';

// class NotificationButton extends StatefulWidget {
//   const NotificationButton({super.key});

//   @override
//   State<NotificationButton> createState() => _NotificationButtonState();
// }

// class _NotificationButtonState extends State<NotificationButton>
//     with TickerProviderStateMixin {
//   final GlobalKey _buttonKey = GlobalKey();
//   OverlayEntry? _overlayEntry;
//   bool _isDropdownOpen = false;
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _rotationAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
    
//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.1,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.elasticOut,
//     ));
    
//     _rotationAnimation = Tween<double>(
//       begin: 0.0,
//       end: 0.1,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _closeDropdown();
//     super.dispose();
//   }

//   void _toggleDropdown() {
//     if (_isDropdownOpen) {
//       _closeDropdown();
//     } else {
//       _openDropdown();
//     }
//   }

//   void _openDropdown() {
//     if (_isDropdownOpen) return;

//     final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
//     final Offset offset = renderBox.localToGlobal(Offset.zero);
//     final Size size = renderBox.size;

//     _overlayEntry = OverlayEntry(
//       builder: (context) => NotificationDropdown(
//         buttonOffset: offset,
//         buttonSize: size,
//         onClose: _closeDropdown,
//       ),
//     );

//     Overlay.of(context).insert(_overlayEntry!);
//     setState(() {
//       _isDropdownOpen = true;
//     });
//     _animationController.forward();
//   }

//   void _closeDropdown() {
//     if (!_isDropdownOpen) return;

//     _overlayEntry?.remove();
//     _overlayEntry = null;
//     setState(() {
//       _isDropdownOpen = false;
//     });
//     _animationController.reverse();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<List<AppNotification>>(
//       stream: NotificationService.notificationListStream,
//       builder: (context, snapshot) {
//         final notifications = snapshot.data ?? [];
//         final unreadCount = notifications.where((n) => !n.isRead).length;

//         return AnimatedBuilder(
//           animation: _animationController,
//           builder: (context, child) {
//             return Transform.scale(
//               scale: _scaleAnimation.value,
//               child: Transform.rotate(
//                 angle: _rotationAnimation.value,
//                 child: Container(
//                   key: _buttonKey,
//                   margin: const EdgeInsets.only(right: 8.0),
//                   child: Stack(
//                     children: [
//                       // Botón principal
//                       Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(20),
//                           onTap: _toggleDropdown,
//                           child: Container(
//                             padding: const EdgeInsets.all(8.0),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(20),
//                               color: _isDropdownOpen 
//                                   ? Theme.of(context).primaryColor.withOpacity(0.1)
//                                   : Colors.transparent,
//                             ),
//                             child: Icon(
//                               _isDropdownOpen 
//                                   ? Icons.notifications_active
//                                   : Icons.notifications_outlined,
//                               color: _isDropdownOpen
//                                   ? Theme.of(context).primaryColor
//                                   : Theme.of(context).iconTheme.color,
//                               size: 24,
//                             ),
//                           ),
//                         ),
//                       ),
                      
//                       // Badge de notificaciones no leídas
//                       if (unreadCount > 0)
//                         Positioned(
//                           right: 6,
//                           top: 6,
//                           child: AnimatedContainer(
//                             duration: const Duration(milliseconds: 300),
//                             curve: Curves.elasticOut,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.red,
//                               borderRadius: BorderRadius.circular(10),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.red.withOpacity(0.3),
//                                   blurRadius: 4,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             constraints: const BoxConstraints(
//                               minWidth: 16,
//                               minHeight: 16,
//                             ),
//                             child: Text(
//                               unreadCount > 99 ? '99+' : unreadCount.toString(),
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ),
                      
//                       // Indicador de pulso para nuevas notificaciones
//                       if (unreadCount > 0)
//                         Positioned(
//                           right: 6,
//                           top: 6,
//                           child: AnimatedContainer(
//                             duration: const Duration(milliseconds: 1000),
//                             curve: Curves.easeInOut,
//                             width: 16,
//                             height: 16,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(
//                                 color: Colors.red.withOpacity(0.5),
//                                 width: 2,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

// /// Widget simplificado para usar en AppBars básicos
// class SimpleNotificationButton extends StatelessWidget {
//   final VoidCallback? onPressed;
  
//   const SimpleNotificationButton({
//     super.key,
//     this.onPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<List<AppNotification>>(
//       stream: NotificationService.notificationListStream,
//       builder: (context, snapshot) {
//         final notifications = snapshot.data ?? [];
//         final unreadCount = notifications.where((n) => !n.isRead).length;

//         return Stack(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.notifications_outlined),
//               onPressed: onPressed ?? () {
//                 // Navegación por defecto a pantalla de notificaciones
//                 Navigator.of(context).pushNamed('/notifications');
//               },
//             ),
//             if (unreadCount > 0)
//               Positioned(
//                 right: 8,
//                 top: 8,
//                 child: Container(
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     color: Colors.red,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   constraints: const BoxConstraints(
//                     minWidth: 16,
//                     minHeight: 16,
//                   ),
//                   child: Text(
//                     unreadCount > 99 ? '99+' : unreadCount.toString(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
// }