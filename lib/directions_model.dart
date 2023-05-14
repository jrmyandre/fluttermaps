import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Directions {
  final LatLngBounds bounds;
  final List<PointLatLng> polylinePoints;
  final int distance;
  final int duration;

  Directions({
    required this.bounds,
    required this.polylinePoints,
    required this.distance,
    required this.duration,
  });

  factory Directions.fromMap(Map<String, dynamic> map){
    if((map['routes'] as List).isEmpty) return Directions(bounds: LatLngBounds(southwest: LatLng(0, 0), northeast: LatLng(0, 0)), polylinePoints: [], distance: 0, duration: 0);

    final data = Map<String, dynamic>.from(map['routes'][0]);

    final northeast = data['bounds']['northeast'];
    final southwest = data['bounds']['southwest'];
    final bounds = LatLngBounds(
      southwest: LatLng(southwest['lat'], southwest['lng']),
      northeast: LatLng(northeast['lat'], northeast['lng']),
    );

    int distance = 0;
    int duration = 0;
    if ((data['legs'] as List).isNotEmpty){
      distance = data['legs'][0]['distance']['value'];
      duration = data['legs'][0]['duration']['value'];
    }

    return Directions(
      bounds: bounds,
      polylinePoints: PolylinePoints().decodePolyline(data['overview_polyline']['points']),
      distance: distance,
      duration: duration,
    );
    }
  }