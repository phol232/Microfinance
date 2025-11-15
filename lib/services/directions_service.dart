import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String _apiKey = 'AIzaSyBy7ofoN91hDelJXR8-GKPKqtihm2JImvg';

  static Future<List<LatLng>?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    try {
      final String url =
          '$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=$travelMode&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final String encodedPolyline =
              data['routes'][0]['overview_polyline']['points'];

          final List<List<num>> decodedPoints = decodePolyline(encodedPolyline);

          final List<LatLng> routePoints = decodedPoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          return routePoints;
        } else {
          print('DirectionsService: Error en la respuesta - ${data['status']}');
          if (data['error_message'] != null) {
            print('DirectionsService: ${data['error_message']}');
          }
          return null;
        }
      } else {
        print('DirectionsService: Error HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('DirectionsService: Error al obtener direcciones - $e');
      return null;
    }
  }

  static Future<DirectionsResult?> getDirectionsWithDetails({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    try {
      final String url =
          '$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=$travelMode&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final String encodedPolyline = route['overview_polyline']['points'];
          final leg = route['legs'][0];

          final List<List<num>> decodedPoints = decodePolyline(encodedPolyline);

          // Convertir a LatLng
          final List<LatLng> routePoints = decodedPoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          return DirectionsResult(
            points: routePoints,
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            distanceValue: leg['distance']['value'],
            durationValue: leg['duration']['value'],
          );
        } else {
          print('DirectionsService: Error en la respuesta - ${data['status']}');
          if (data['error_message'] != null) {
            print('DirectionsService: ${data['error_message']}');
          }
          return null;
        }
      } else {
        print('DirectionsService: Error HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('DirectionsService: Error al obtener direcciones - $e');
      return null;
    }
  }
}

class DirectionsResult {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final int distanceValue; // en metros
  final int durationValue; // en segundos

  DirectionsResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
  });
}
