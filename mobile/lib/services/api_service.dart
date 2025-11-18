import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Change this to your backend URL
  // For emulator: http://10.0.2.2:8000
  // For web/desktop: http://localhost:8000
  // For real device: http://YOUR_COMPUTER_IP:8000
  static const String baseUrl = 'http://localhost:8000';

  // Test connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/test'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to connect');
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Get weather data
  static Future<Map<String, dynamic>> getWeather(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/weather'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get weather data');
    } catch (e) {
      throw Exception('Weather API error: $e');
    }
  }

  // Get crime data
  static Future<Map<String, dynamic>> getCrimeData(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/crime-data'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get crime data');
    } catch (e) {
      throw Exception('Crime API error: $e');
    }
  }

  // Analyze image
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/analyze-image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      }
      throw Exception('Failed to analyze image');
    } catch (e) {
      throw Exception('Image analysis error: $e');
    }
  }

  // Complete safety analysis
  static Future<Map<String, dynamic>> getSafetyAnalysis({
    required double latitude,
    required double longitude,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/safety-analysis'),
      );

      // Add location
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      // Add image if provided
      if (kIsWeb && imageBytes != null) {
        // For web, use bytes directly
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'image.jpg',
          ),
        );
      } else if (!kIsWeb && imageFile != null) {
        // For mobile, use file path
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      }
      throw Exception('Failed to get safety analysis');
    } catch (e) {
      throw Exception('Safety analysis error: $e');
    }
  }

  // Report an incident
  static Future<Map<String, dynamic>> reportIncident({
    required double latitude,
    required double longitude,
    required String incidentType,
    String description = '',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/report-incident'),
      );

      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['incident_type'] = incidentType;
      request.fields['description'] = description;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      }
      throw Exception('Failed to report incident');
    } catch (e) {
      throw Exception('Report incident error: $e');
    }
  }
}

