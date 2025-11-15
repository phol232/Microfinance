import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/entities/loan_application.dart';

enum LocationStatus {
  enabled,
  disabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationResult {
  final LocationData? data;
  final LocationStatus status;
  final String? message;

  LocationResult({this.data, required this.status, this.message});
}

class LocationService {
  static const String _tag = 'LocationService';
  static bool? _lastLocationAvailableStatus;
  static DateTime? _lastLocationCheck;

  static Future<LocationResult> checkLocationStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          status: LocationStatus.disabled,
          message:
              'Los servicios de ubicación están desactivados. Por favor, actívalos en la configuración.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          status: LocationStatus.permissionDeniedForever,
          message:
              'Los permisos de ubicación han sido denegados permanentemente. Ve a configuración para habilitarlos.',
        );
      }

      if (permission == LocationPermission.denied) {
        return LocationResult(
          status: LocationStatus.permissionDenied,
          message: 'Se requieren permisos de ubicación para continuar.',
        );
      }

      return LocationResult(
        status: LocationStatus.enabled,
        message: 'Ubicación disponible',
      );
    } catch (e) {
      print('$_tag: Error verificando estado de ubicación: $e');
      return LocationResult(
        status: LocationStatus.unknown,
        message: 'Error al verificar el estado de ubicación: $e',
      );
    }
  }

  static Future<bool> requestLocationActivation() async {
    try {
      LocationResult status = await checkLocationStatus();

      switch (status.status) {
        case LocationStatus.disabled:
          await Geolocator.openLocationSettings();

          await Future.delayed(const Duration(seconds: 2));
          bool isNowEnabled = await Geolocator.isLocationServiceEnabled();
          return isNowEnabled;

        case LocationStatus.permissionDenied:
          LocationPermission permission = await Geolocator.requestPermission();
          return permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;

        case LocationStatus.permissionDeniedForever:
          await Geolocator.openAppSettings();
          return false;

        case LocationStatus.enabled:
          return true;

        default:
          return false;
      }
    } catch (e) {
      print('$_tag: Error solicitando activación de ubicación: $e');
      return false;
    }
  }

  static Future<LocationResult> getCurrentLocationWithCheck() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          status: LocationStatus.disabled,
          message: 'Los servicios de ubicación están desactivados. Por favor, actívalos en la configuración.',
        );
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            status: LocationStatus.permissionDenied,
            message: 'Los permisos de ubicación fueron denegados.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          status: LocationStatus.permissionDeniedForever,
          message: 'Los permisos de ubicación están permanentemente denegados. Ve a configuración para habilitarlos.',
        );
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      LocationData locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      return LocationResult(
        status: LocationStatus.enabled,
        data: locationData,
        message: 'Ubicación obtenida exitosamente',
      );
    } catch (e) {
      return LocationResult(
        status: LocationStatus.unknown,
        message: 'Error al obtener ubicación: $e',
      );
    }
  }

  /// Verifica rápidamente si los servicios de ubicación están disponibles
  static Future<bool> isLocationAvailable() async {
    try {
      // Cache por 500ms para evitar verificaciones excesivas
      final now = DateTime.now();
      if (_lastLocationCheck != null && 
          _lastLocationAvailableStatus != null &&
          now.difference(_lastLocationCheck!).inMilliseconds < 500) {
        return _lastLocationAvailableStatus!;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _lastLocationAvailableStatus = false;
        _lastLocationCheck = now;
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      bool isAvailable = permission == LocationPermission.whileInUse || 
                        permission == LocationPermission.always;
      
      _lastLocationAvailableStatus = isAvailable;
      _lastLocationCheck = now;
      return isAvailable;
    } catch (e) {
      _lastLocationAvailableStatus = false;
      _lastLocationCheck = DateTime.now();
      return false;
    }
  }

  /// Limpia el cache de estado de ubicación para forzar una verificación fresca
  static void clearLocationCache() {
    _lastLocationAvailableStatus = null;
    _lastLocationCheck = null;
  }

  /// Stream para escuchar cambios en el estado de ubicación
  static Stream<bool> get locationStatusStream {
    return Stream.periodic(const Duration(milliseconds: 1000))
        .asyncMap((_) => isLocationAvailable())
        .distinct();
  }

  static Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('$_tag: Servicio de ubicación deshabilitado');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('$_tag: Permisos de ubicación denegados');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('$_tag: Permisos de ubicación denegados permanentemente');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('$_tag: Error obteniendo ubicación: $e');
      return null;
    }
  }

  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
