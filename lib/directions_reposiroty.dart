import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'directions_model.dart';

class DirectionsRepository{
  static const String _baseUrl =
  'https://maps.googleapis.com/maps/api/directions/json?';

  late final Dio _dio;

  DirectionsRepository({ Dio? dio}) : _dio = dio ?? Dio();

  Future<Directions?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'key': 'AIzaSyCWIWs4tSQy4kHRg6h8WmTvF9RihIUHREo'
      },
    );
    if (response.statusCode==200){
      return Directions.fromMap(response.data);
    }
    return null;

  }
}