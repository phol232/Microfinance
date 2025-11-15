import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../domain/entities/loan_application.dart';

class LocationPermissionDialog extends StatefulWidget {
  final String message;
  final LocationStatus status;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const LocationPermissionDialog({
    super.key,
    required this.message,
    required this.status,
    this.onRetry,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required String message,
    required LocationStatus status,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LocationPermissionDialog(
          message: message,
          status: status,
          onRetry: onRetry,
          onCancel: onCancel,
        );
      },
    );
  }

  @override
  State<LocationPermissionDialog> createState() => _LocationPermissionDialogState();
}

class _LocationPermissionDialogState extends State<LocationPermissionDialog> with WidgetsBindingObserver {
  StreamSubscription<bool>? _locationStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationStatusSubscription?.cancel();
    super.dispose();
  }

  void _startLocationListener() {
    _locationStatusSubscription = LocationService.locationStatusStream.listen((isAvailable) {
      if (isAvailable && mounted) {
        Navigator.of(context).pop();
        widget.onRetry?.call();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // Cuando regresa del primer plano, verificar inmediatamente
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted) {
          LocationService.clearLocationCache();
          bool isAvailable = await LocationService.isLocationAvailable();
          if (isAvailable) {
            Navigator.of(context).pop();
            widget.onRetry?.call();
          }
        }
      });
    }
  }

  Future<void> _openLocationSettings() async {
    Navigator.of(context).pop();
    
    if (widget.status == LocationStatus.disabled) {
      await LocationService.openLocationSettings();
    } else if (widget.status == LocationStatus.permissionDeniedForever) {
      await LocationService.openAppSettings();
    } else if (widget.status == LocationStatus.permissionDenied) {
      bool granted = await LocationService.requestLocationActivation();
      if (granted && widget.onRetry != null) {
        widget.onRetry!();
      }
    }
    
    if (widget.onRetry != null) {
      // Esperar un momento antes de reintentar
      await Future.delayed(const Duration(seconds: 1));
      widget.onRetry!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            _getIconForStatus(),
            color: _getColorForStatus(),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTitleForStatus(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (widget.status == LocationStatus.disabled) ...[
            const Text(
              '• Ve a Configuración del dispositivo\n'
              '• Busca "Ubicación" o "Localización"\n'
              '• Activa los servicios de ubicación',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ] else if (widget.status == LocationStatus.permissionDeniedForever) ...[
            const Text(
              '• Ve a Configuración de la app\n'
              '• Busca "Permisos"\n'
              '• Activa el permiso de ubicación',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.onCancel != null)
          TextButton(
            onPressed: widget.onCancel,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            if (widget.status == LocationStatus.disabled ||
                widget.status == LocationStatus.permissionDeniedForever) {
              _openLocationSettings();
            } else {
              widget.onRetry?.call();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getColorForStatus(),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
              widget.status == LocationStatus.disabled ||
                      widget.status == LocationStatus.permissionDeniedForever
                  ? 'Ir a Configuración'
                  : 'Reintentar',
            ),
        ),
      ],
    );
  }

  IconData _getIconForStatus() {
    switch (widget.status) {
      case LocationStatus.disabled:
        return Icons.location_off;
      case LocationStatus.permissionDenied:
      case LocationStatus.permissionDeniedForever:
        return Icons.location_disabled;
      default:
        return Icons.warning;
    }
  }

  Color _getColorForStatus() {
    switch (widget.status) {
      case LocationStatus.disabled:
        return Colors.orange;
      case LocationStatus.permissionDenied:
      case LocationStatus.permissionDeniedForever:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTitleForStatus() {
    switch (widget.status) {
      case LocationStatus.disabled:
        return 'Ubicación Desactivada';
      case LocationStatus.permissionDenied:
        return 'Permiso Requerido';
      case LocationStatus.permissionDeniedForever:
        return 'Permiso Denegado';
      default:
        return 'Problema de Ubicación';
    }
  }

  String _getButtonTextForStatus() {
    switch (widget.status) {
      case LocationStatus.disabled:
        return 'Ir a Configuración';
      case LocationStatus.permissionDenied:
        return 'Conceder Permiso';
      case LocationStatus.permissionDeniedForever:
        return 'Abrir Configuración';
      default:
        return 'Reintentar';
    }
  }

  /// Método estático para mostrar el diálogo fácilmente
  static Future<void> show(
    BuildContext context, {
    required LocationStatus status,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LocationPermissionDialog(
          status: status,
          message: message,
          onRetry: onRetry,
          onCancel: onCancel,
        );
      },
    );
  }
}

/// Widget helper para verificar ubicación automáticamente
class LocationChecker extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLocationObtained;
  final Function(String)? onLocationError;

  const LocationChecker({
    super.key,
    required this.child,
    this.onLocationObtained,
    this.onLocationError,
  });

  @override
  State<LocationChecker> createState() => _LocationCheckerState();
}

class _LocationCheckerState extends State<LocationChecker> with WidgetsBindingObserver {
  bool _hasCheckedLocation = false;
  bool _isCheckingLocation = false;
  StreamSubscription<bool>? _locationStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationStatus();
      _startLocationStatusListener();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationStatusSubscription?.cancel();
    super.dispose();
  }

  void _startLocationStatusListener() {
    _locationStatusSubscription = LocationService.locationStatusStream.listen((isAvailable) {
      if (isAvailable && !_hasCheckedLocation && !_isCheckingLocation) {
        _checkLocationStatus();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Cuando la app regresa al primer plano, verificar ubicación con delays realistas
    if (state == AppLifecycleState.resumed && !_hasCheckedLocation) {
      // Limpiar cache para forzar verificación fresca
      LocationService.clearLocationCache();
      
      // Primera verificación después de un pequeño delay para que el sistema se estabilice
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_hasCheckedLocation && !_isCheckingLocation) {
          _checkLocationStatus();
        }
      });
      
      // Segunda verificación - los servicios nativos pueden tardar un poco más
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_hasCheckedLocation && !_isCheckingLocation) {
          LocationService.clearLocationCache();
          _checkLocationStatus();
        }
      });
      
      // Tercera verificación - para casos donde el sistema es más lento
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && !_hasCheckedLocation && !_isCheckingLocation) {
          LocationService.clearLocationCache();
          _checkLocationStatus();
        }
      });
    }
  }

  Future<void> _checkLocationStatus() async {
    if (_hasCheckedLocation || _isCheckingLocation) return;
    
    setState(() {
      _isCheckingLocation = true;
    });
    
    try {
      // Primero verificar rápidamente si está disponible
      bool isAvailable = await LocationService.isLocationAvailable();
      
      if (isAvailable) {
        // Si está disponible, obtener la ubicación completa
        LocationResult result = await LocationService.getCurrentLocationWithCheck();
        
        if (result.status == LocationStatus.enabled && result.data != null) {
          setState(() {
            _hasCheckedLocation = true;
            _isCheckingLocation = false;
          });
          widget.onLocationObtained?.call();
          return;
        }
      }
      
      // Si no está disponible o hay error, obtener el estado completo
      LocationResult result = await LocationService.getCurrentLocationWithCheck();
      
      if (result.status == LocationStatus.enabled && result.data != null) {
        setState(() {
          _hasCheckedLocation = true;
          _isCheckingLocation = false;
        });
        widget.onLocationObtained?.call();
      } else if (result.status != LocationStatus.enabled) {
        setState(() {
          _isCheckingLocation = false;
        });
        
        if (mounted) {
          await LocationPermissionDialog.show(
            context,
            status: result.status,
            message: result.message ?? 'Error desconocido',
            onRetry: () {
              setState(() {
                _hasCheckedLocation = false;
              });
              _checkLocationStatus();
            },
            onCancel: () {
              widget.onLocationError?.call('Ubicación requerida');
            },
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCheckingLocation = false;
      });
      widget.onLocationError?.call('Error al verificar ubicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}