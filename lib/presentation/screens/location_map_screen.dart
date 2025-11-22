import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'package:mobile/infrastructure/services/location_service.dart';
import 'package:mobile/infrastructure/services/directions_service.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  GoogleMapController? mapController;
  bool _isMapLoading = true;
  String? _errorMessage;
  Position? _currentUserLocation;
  bool _isLoadingUserLocation = false;
  bool _showingRoute = false;
  DirectionsResult? _currentRoute;
  String _selectedMode = 'driving'; // driving | walking | transit | bicycling

  static const LatLng _companyLocation = LatLng(-12.0653, -75.2049);

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _createMarker();
    print('LocationMapScreen: Inicializando pantalla de mapa');
  }

  void _createMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('company_location'),
        position: _companyLocation,
        infoWindow: const InfoWindow(
          title: 'Nuestra Ubicación',
          snippet: 'Jr. Tacna 340, Huancayo 12004',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    print('LocationMapScreen: Mapa creado exitosamente');
    mapController = controller;
    setState(() {
      _isMapLoading = false;
    });
  }

  void _goToLocation() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: _companyLocation, zoom: 18.0),
      ),
    );
  }

  Future<void> _getCurrentLocationAndShowRoute() async {
    setState(() {
      _isLoadingUserLocation = true;
      _errorMessage = null;
    });

    try {
      LocationResult result =
          await LocationService.getCurrentLocationWithCheck();

      if (result.status == LocationStatus.enabled && result.data != null) {
        final locationData = result.data!;
        _currentUserLocation = Position(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        await _showRouteOnMap();
      } else {
        setState(() {
          _errorMessage = result.message ?? 'No se pudo obtener la ubicación';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener ubicación: $e';
      });
    } finally {
      setState(() {
        _isLoadingUserLocation = false;
      });
    }
  }

  Future<void> _showRouteOnMap() async {
    if (_currentUserLocation == null) return;

    _polylines.removeWhere((p) => p.polylineId.value == 'route');
    _markers.removeWhere((marker) => marker.markerId.value == 'user_location');

    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          _currentUserLocation!.latitude,
          _currentUserLocation!.longitude,
        ),
        infoWindow: const InfoWindow(
          title: 'Tu ubicación',
          snippet: 'Ubicación actual',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Obtener la ruta real usando Google Directions API
    try {
      final directionsResult = await DirectionsService.getDirectionsWithDetails(
        origin: LatLng(
          _currentUserLocation!.latitude,
          _currentUserLocation!.longitude,
        ),
        destination: _companyLocation,
        travelMode: _selectedMode,
      );

      if (directionsResult != null && directionsResult.points.isNotEmpty) {
        _currentRoute = directionsResult;

        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: directionsResult.points,
            color: AppColors.primary,
            width: 5,
            patterns: [],
          ),
        );

        double minLat = directionsResult.points.first.latitude;
        double maxLat = directionsResult.points.first.latitude;
        double minLng = directionsResult.points.first.longitude;
        double maxLng = directionsResult.points.first.longitude;

        for (LatLng point in directionsResult.points) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100.0),
        );

        setState(() {
          _showingRoute = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ruta calculada: ${directionsResult.distance} - ${directionsResult.duration}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(
                _currentUserLocation!.latitude,
                _currentUserLocation!.longitude,
              ),
              _companyLocation,
            ],
            color: AppColors.primary,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            _currentUserLocation!.latitude < _companyLocation.latitude
                ? _currentUserLocation!.latitude
                : _companyLocation.latitude,
            _currentUserLocation!.longitude < _companyLocation.longitude
                ? _currentUserLocation!.longitude
                : _companyLocation.longitude,
          ),
          northeast: LatLng(
            _currentUserLocation!.latitude > _companyLocation.latitude
                ? _currentUserLocation!.latitude
                : _companyLocation.latitude,
            _currentUserLocation!.longitude > _companyLocation.longitude
                ? _currentUserLocation!.longitude
                : _companyLocation.longitude,
          ),
        );

        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100.0),
        );

        setState(() {
          _showingRoute = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ruta directa mostrada (no se pudo calcular ruta por calles)',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error al obtener direcciones: $e');
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(
              _currentUserLocation!.latitude,
              _currentUserLocation!.longitude,
            ),
            _companyLocation,
          ],
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );

      setState(() {
        _showingRoute = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al calcular ruta, mostrando línea directa'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearRoute() {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'user_location',
      );
      _polylines.clear();
      _showingRoute = false;
      _currentUserLocation = null;
      _currentRoute = null;
    });
    _goToLocation();
  }

  void _onModeSelected(String mode) async {
    if (_selectedMode == mode) return;
    setState(() => _selectedMode = mode);
    if (_currentUserLocation != null) {
      await _showRouteOnMap();
    }
  }

  void _openNavigationInGoogleMaps() async {
    if (_currentUserLocation == null) {
      const String address = "Jr. Tacna 340, Huancayo 12004";
      final String googleMapsUrl =
          "https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}&travelmode=$_selectedMode";

      try {
        final Uri uri = Uri.parse(googleMapsUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al abrir Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Si tenemos ubicación actual, abrir con navegación completa
      final String googleMapsUrl =
          "https://www.google.com/maps/dir/${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}/${_companyLocation.latitude},${_companyLocation.longitude}?travelmode=$_selectedMode";

      try {
        final Uri uri = Uri.parse(googleMapsUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al abrir navegación'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuestra Ubicación',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_showingRoute)
            IconButton(
              onPressed: _clearRoute,
              icon: const Icon(Icons.clear, color: Colors.white),
              tooltip: 'Limpiar ruta',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa de Google
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _companyLocation,
              zoom: 16.0,
            ),
            markers: _markers,
            polylines: _polylines,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
          ),

          // Indicador de carga
          if (_isMapLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Cargando mapa...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // Información de la ubicación
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          'Jr. Tacna 340, Huancayo 12004',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Visítanos en nuestra oficina principal',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildModeChip('driving', Icons.directions_car, 'Auto'),
                    _buildModeChip('walking', Icons.directions_walk, 'A pie'),
                  ],
                ),
                  if (_showingRoute) ...[
                    SizedBox(height: screenHeight * 0.01),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.route,
                                color: Colors.green.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ruta calculada',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_currentRoute != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten,
                                  color: Colors.green.shade600,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentRoute!.distance,
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  color: Colors.green.shade600,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentRoute!.duration,
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    SizedBox(height: screenHeight * 0.01),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error,
                            color: Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Botones de acción
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón "Cómo llegar"
                FloatingActionButton.extended(
                  heroTag: "show_route",
                  onPressed: _isLoadingUserLocation
                      ? null
                      : _getCurrentLocationAndShowRoute,
                  backgroundColor: Colors.orange,
                  icon: _isLoadingUserLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.directions, color: Colors.white),
                  label: Text(
                    _isLoadingUserLocation ? 'Obteniendo...' : 'Cómo llegar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // Botón para centrar en la ubicación
                FloatingActionButton(
                  heroTag: "center_location",
                  onPressed: _goToLocation,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),

                SizedBox(height: screenHeight * 0.01),

                // Botón para abrir en Google Maps
                FloatingActionButton(
                  heroTag: "open_google_maps",
                  onPressed: _openNavigationInGoogleMaps,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.navigation, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, IconData icon, String label) {
    final bool selected = _selectedMode == mode;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : Colors.black87),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => _onModeSelected(mode),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
}
