import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapboxService {
  static const String _accessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  static const String _baseUrl = 'https://api.mapbox.com';

  static String getTileLayerUrl() {
    return 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=$_accessToken';
  }

  static Future<LatLng> forwardGeocode(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = '$_baseUrl/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$_accessToken&limit=1';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['features'] != null && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        final coordinates = feature['geometry']['coordinates'];
        
        return LatLng(
          coordinates[1].toDouble(),
          coordinates[0].toDouble(),
        );
      } else {
        throw Exception('No results found for "$query"');
      }
    } else {
      throw Exception('Failed to fetch location: ${response.statusCode}');
    }
  }

  static Future<String> reverseGeocode(double latitude, double longitude) async {
    final url = '$_baseUrl/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$_accessToken&limit=1';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        return data['features'][0]['place_name'] ?? '';
      }
    }
    return '';
  }

  /// Get a routed polyline (list of LatLng) from origin to destination using Mapbox Directions API.
  /// Returns an empty list on failure.
  static Future<List<LatLng>> getRoute(double originLat, double originLng, double destLat, double destLng) async {
    final url = '$_baseUrl/directions/v5/mapbox/driving/$originLng,$originLat;$destLng,$destLat?geometries=geojson&overview=full&access_token=$_accessToken';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        final List<LatLng> path = coords.map<LatLng>((c) {
          final lon = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          return LatLng(lat, lon);
        }).toList();
        return path;
      }
    }

    return [];
  }
}
