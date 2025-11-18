import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Conditionally import Google Maps - only on mobile
import 'package:google_maps_flutter/google_maps_flutter.dart' 
    if (dart.library.html) 'google_maps_stub.dart';

void main() {
  runApp(const TravelSafeApp());
}

class TravelSafeApp extends StatelessWidget {
  const TravelSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelSafe',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
      ),
      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.data == true) {
            // User is logged in, show home screen first
            return const HomeScreen();
          } else {
            // User is not logged in, show login screen
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

// Web version with all features
class WebSafetyScreen extends StatefulWidget {
  const WebSafetyScreen({super.key});

  @override
  State<WebSafetyScreen> createState() => _WebSafetyScreenState();
}

class _WebSafetyScreenState extends State<WebSafetyScreen> {
  // Default to Tunis, Tunisia
  double _latitude = 36.8065; // Default to Tunis
  double _longitude = 10.1815;
  String? _placeName; // Store place name from reverse geocoding
  bool _isLoading = false;
  Map<String, dynamic>? _safetyData;
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web compatibility

  @override
  void initState() {
    super.initState();
    // Automatically get current location when app starts
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Please enable location access.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get place name from coordinates (reverse geocoding)
      String? placeName;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Build address string
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            addressParts.add(place.subAdministrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          placeName = addressParts.isNotEmpty ? addressParts.join(', ') : 'Unknown Location';
        }
      } catch (e) {
        print('Error getting place name: $e');
        placeName = null;
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _placeName = placeName;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location updated! ${placeName != null ? placeName : '(${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Automatically analyze safety after getting location
        _analyzeSafety();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e\nUsing default location (Tunis).'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        // For web, read bytes directly
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImage = null; // Not used on web
        });
      } else {
        // For mobile, use File
        setState(() {
          _selectedImage = File(image.path);
          _selectedImageBytes = null;
        });
      }
      
      // Automatically analyze safety with the new image
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Image selected! Analyzing safety...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        _analyzeSafety();
      }
    }
  }

  Future<void> _analyzeSafety() async {
    setState(() {
      _isLoading = true;
      _safetyData = null;
    });

    try {
      final result = await ApiService.getSafetyAnalysis(
        latitude: _latitude,
        longitude: _longitude,
        imageFile: _selectedImage,
        imageBytes: _selectedImageBytes,
      );

      setState(() {
        _safetyData = result;
        _isLoading = false;
      });

      // Debug: Print image analysis data
      if (_selectedImage != null || _selectedImageBytes != null) {
        print('📸 Image Analysis Data:');
        print('Image Analysis in factors: ${result['factors']?['image_analysis']}');
        print('Image Analysis in breakdown: ${result['breakdown']?['image_analysis']}');
        print('Safety Score: ${result['safety_score']}');
      }

      if (_safetyData?['alert'] == true) {
        _showAlertDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reportIncident() async {
    final incidentType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Incident'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Theft'),
              onTap: () => Navigator.pop(context, 'theft'),
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Assault'),
              onTap: () => Navigator.pop(context, 'assault'),
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Vandalism'),
              onTap: () => Navigator.pop(context, 'vandalism'),
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Suspicious Activity'),
              onTap: () => Navigator.pop(context, 'suspicious_activity'),
            ),
            ListTile(
              leading: const Icon(Icons.other_houses),
              title: const Text('Other'),
              onTap: () => Navigator.pop(context, 'other'),
            ),
          ],
        ),
      ),
    );

    if (incidentType != null) {
      try {
        final result = await ApiService.reportIncident(
          latitude: _latitude,
          longitude: _longitude,
          incidentType: incidentType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message'] ?? 'Incident reported successfully!'}\nCrime counter will update on next safety check.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Immediately refresh safety analysis to show updated crime counter
        await _analyzeSafety();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error reporting incident: $e')),
          );
        }
      }
    }
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Safety Alert'),
        content: const Text(
          'This area has been flagged as potentially unsafe. Please exercise caution.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getSafetyColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  String _getSafetyLevel(String level) {
    switch (level) {
      case 'very_safe':
        return 'Very Safe';
      case 'safe':
        return 'Safe';
      case 'moderate':
        return 'Moderate';
      case 'caution':
        return 'Caution';
      case 'unsafe':
        return 'Unsafe';
      default:
        return 'Unknown';
    }
  }

  Widget _buildCoordinateCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
              letterSpacing: -0.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageAnalysisStatus() {
    // Get image analysis data from safety response
    final imageAnalysis = _safetyData?['factors']?['image_analysis'];
    if (imageAnalysis == null) {
      return const Text(
        '📸 Image analyzed',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }

    final indicators = imageAnalysis['indicators'];
    if (indicators == null || indicators is! Map) {
      return const Text(
        '📸 Image analyzed',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }

    // Safely extract road_hazards - handle both Map and String types
    dynamic roadHazardsRaw = indicators['road_hazards'];
    Map<String, dynamic> roadHazards = {};
    
    if (roadHazardsRaw != null) {
      if (roadHazardsRaw is Map) {
        roadHazards = Map<String, dynamic>.from(roadHazardsRaw);
      } else if (roadHazardsRaw is String) {
        // If it's a string, try to parse it as JSON
        try {
          final parsed = json.decode(roadHazardsRaw);
          if (parsed is Map) {
            roadHazards = Map<String, dynamic>.from(parsed);
          }
        } catch (e) {
          // If parsing fails, use empty map
          roadHazards = {};
        }
      }
    }
    
    final hazardSeverity = (indicators['hazard_severity'] ?? 'none').toString();
    final hazardDescription = (indicators['hazard_description'] ?? '').toString();
    
    // Check if any hazards detected
    final hasConstruction = roadHazards['construction_roadwork'] == true;
    final hasWater = roadHazards['water_flooding'] == true;
    final hasObstacles = roadHazards['obstacles_debris'] == true;
    final hasPoorRoad = roadHazards['poor_road_condition'] == true;
    final hasTrafficHazards = roadHazards['traffic_hazards'] == true;
    
    final hasAnyHazards = hasConstruction || hasWater || hasObstacles || hasPoorRoad || hasTrafficHazards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.image, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            const Text(
              'Image analyzed',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        if (hasAnyHazards) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hazardSeverity == 'critical' || hazardSeverity == 'high'
                  ? Colors.red.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hazardSeverity == 'critical' || hazardSeverity == 'high'
                    ? Colors.red
                    : Colors.orange,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: hazardSeverity == 'critical' || hazardSeverity == 'high'
                          ? Colors.red
                          : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Road Hazards Detected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hazardSeverity == 'critical' || hazardSeverity == 'high'
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (hazardSeverity != 'none')
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 22),
                    child: Text(
                      'Severity: ${hazardSeverity.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hazardSeverity == 'critical'
                            ? Colors.red
                            : hazardSeverity == 'high'
                                ? Colors.deepOrange
                                : Colors.orange,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (hasConstruction)
                      Chip(
                        avatar: const Icon(Icons.build, size: 14),
                        label: const Text('Construction', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        padding: const EdgeInsets.all(4),
                      ),
                    if (hasWater)
                      Chip(
                        avatar: const Icon(Icons.water_drop, size: 14),
                        label: const Text('Water/Flooding', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        padding: const EdgeInsets.all(4),
                      ),
                    if (hasObstacles)
                      Chip(
                        avatar: const Icon(Icons.block, size: 14),
                        label: const Text('Obstacles', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.red.withOpacity(0.2),
                        padding: const EdgeInsets.all(4),
                      ),
                    if (hasPoorRoad)
                      Chip(
                        avatar: const Icon(Icons.construction, size: 14),
                        label: const Text('Poor Road', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        padding: const EdgeInsets.all(4),
                      ),
                    if (hasTrafficHazards)
                      Chip(
                        avatar: const Icon(Icons.traffic, size: 14),
                        label: const Text('Traffic Hazards', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        padding: const EdgeInsets.all(4),
                      ),
                  ],
                ),
                if (hazardDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Text(
                      hazardDescription,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          const Text(
            '✅ No road hazards detected',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'TravelSafe',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.image, color: Colors.white),
            ),
            onPressed: _pickImage,
            tooltip: 'Upload Image',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
            onPressed: _analyzeSafety,
            tooltip: 'Analyze Location',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.white),
            ),
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Location Section - Professional Design
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and title
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[900],
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (_placeName != null && _placeName!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _placeName!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Coordinates in a clean grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildCoordinateCard(
                            context,
                            'Latitude',
                            _latitude.toStringAsFixed(6),
                            Icons.north,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCoordinateCard(
                            context,
                            'Longitude',
                            _longitude.toStringAsFixed(6),
                            Icons.east,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Update button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        icon: Icon(
                          Icons.refresh,
                          size: 18,
                          color: _isLoading ? Colors.grey : Colors.white,
                        ),
                        label: Text(
                          _isLoading ? 'Updating...' : 'Update Location',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _analyzeSafety,
                      icon: const Icon(Icons.safety_check, size: 24),
                      label: const Text(
                        'Check Safety',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _reportIncident,
                    icon: const Icon(Icons.report, size: 24),
                    label: const Text(
                      'Report',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),

            // Selected Image
            if (_selectedImage != null || _selectedImageBytes != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Selected Image',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb && _selectedImageBytes != null
                          ? Image.memory(
                              _selectedImageBytes!,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],

            // Loading Indicator
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],

            // Safety Score Card
            if (_safetyData != null) ...[
              const SizedBox(height: 30),
              _buildSafetyCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard() {
    final crimeData = _safetyData!['factors']?['crime'];
    final weatherData = _safetyData!['factors']?['weather'];
    final incidentCount = crimeData?['total_incidents'] ?? 0;
    final recentIncidents = crimeData?['recent_incidents'] ?? 0;
    final isRealWeather = weatherData?['data_source'] == 'openweathermap_api';

    final score = _safetyData!['safety_score'] ?? 50;
    final safetyColor = _getSafetyColor(score);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            safetyColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: safetyColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: safetyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shield,
                        color: safetyColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Safety Score',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                if (_safetyData!['alert'] == true)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        safetyColor,
                        safetyColor.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: safetyColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSafetyLevel(_safetyData!['safety_level'] ?? 'moderate'),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: safetyColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Show image analysis status and hazards
                      if (_selectedImage != null || _selectedImageBytes != null)
                        _buildImageAnalysisStatus(),
                      const SizedBox(height: 8),
                      if (incidentCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Text(
                                '$incidentCount incident(s) reported',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              const Text(
                                'No incidents reported',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Only show breakdown if image was analyzed (not null)
            if (_safetyData!['breakdown'] != null && 
                _safetyData!['breakdown']['image_analysis'] != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Breakdown:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBreakdownItem(
                    'Image',
                    _safetyData!['breakdown']['image_analysis'],
                    showNA: true,
                  ),
                  _buildBreakdownItem(
                    'Weather',
                    _safetyData!['breakdown']['weather'] ?? 50,
                  ),
                  _buildBreakdownItem(
                    'User Reports',
                    _safetyData!['breakdown']['crime_data'] ?? 50,
                  ),
                ],
              ),
            ],
            if (weatherData != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.wb_sunny, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${weatherData['temperature'] ?? 'N/A'}°C',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  weatherData['description'] ?? weatherData['condition'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (weatherData['city'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.blue[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${weatherData['city']}, ${weatherData['country'] ?? 'TN'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRealWeather ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRealWeather ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isRealWeather ? 'Real Data' : 'Fallback',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isRealWeather ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // User Reports Section
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.report, size: 20, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'User Reports: $incidentCount',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (recentIncidents > 0)
                      Text(
                        '$recentIncidents recent (last 30 days)',
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                      )
                    else if (incidentCount == 0)
                      const Text(
                        'No incidents reported in this area',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    const SizedBox(height: 4),
            Text(
                      'Safety Score: ${_safetyData!['breakdown']['crime_data'] ?? 50}/100 (Higher = Safer)',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                if (incidentCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+$incidentCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            if (crimeData?['incident_types'] != null && (crimeData['incident_types'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (crimeData['incident_types'] as List).map<Widget>((type) {
                  return Chip(
                    label: Text(type.toString().replaceAll('_', ' ')),
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    labelStyle: const TextStyle(fontSize: 11),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, dynamic score, {bool showNA = false}) {
    final hasScore = score != null;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        hasScore
            ? Text(
                '$score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getSafetyColor(score),
                ),
              )
            : showNA
                ? const Text(
                    'N/A',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  )
                : const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
      ],
    );
  }

}

// Mobile version with maps - only used on mobile platforms
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(36.8065, 10.1815); // Default to Tunis
  String? _placeName; // Store place name from reverse geocoding
  bool _isLoading = false;
  Map<String, dynamic>? _safetyData;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) return;
    
    var status = await Permission.location.request();
    if (!status.isGranted) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get place name from coordinates (reverse geocoding)
      String? placeName;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Build address string
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            addressParts.add(place.subAdministrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          placeName = addressParts.isNotEmpty ? addressParts.join(', ') : 'Unknown Location';
        }
      } catch (e) {
        print('Error getting place name: $e');
        placeName = null;
      }
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _placeName = placeName;
      });
      if (_mapController != null) {
        (_mapController as GoogleMapController).animateCamera(
          CameraUpdate.newLatLng(_currentLocation as LatLng),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      
      // Automatically analyze safety with the new image
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Image captured! Analyzing safety...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        _analyzeSafety();
      }
    }
  }

  Future<void> _analyzeSafety() async {
    setState(() {
      _isLoading = true;
      _safetyData = null;
    });

    try {
      double lat, lng;
      if (kIsWeb) {
        lat = 48.8566;
        lng = 2.3522;
      } else {
        lat = (_currentLocation as LatLng).latitude;
        lng = (_currentLocation as LatLng).longitude;
      }
      
      final result = await ApiService.getSafetyAnalysis(
        latitude: lat,
        longitude: lng,
        imageFile: _selectedImage,
      );

      setState(() {
        _safetyData = result;
        _isLoading = false;
      });

      if (_safetyData?['alert'] == true) {
        _showAlertDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Safety Alert'),
        content: const Text(
          'This area has been flagged as potentially unsafe. Please exercise caution.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getSafetyColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  String _getSafetyLevel(String level) {
    switch (level) {
      case 'very_safe':
        return 'Very Safe';
      case 'safe':
        return 'Safe';
      case 'moderate':
        return 'Moderate';
      case 'caution':
        return 'Caution';
      case 'unsafe':
        return 'Unsafe';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'TravelSafe',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
            onPressed: _pickImage,
            tooltip: 'Take Photo',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
            onPressed: _analyzeSafety,
            tooltip: 'Analyze Location',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.white),
            ),
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          kIsWeb
              ? const Center(
                  child: Text(
                    'Maps not available on web.\nUse Android/iOS for full features.',
                    textAlign: TextAlign.center,
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onTap: (LatLng location) {
                    setState(() {
                      _currentLocation = location;
                    });
                  },
                ),
          if (_safetyData != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Safety Score',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (_safetyData!['alert'] == true)
                            const Icon(Icons.warning, color: Colors.red),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _getSafetyColor(
                                _safetyData!['safety_score'] ?? 50,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${_safetyData!['safety_score'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getSafetyLevel(
                                    _safetyData!['safety_level'] ?? 'moderate',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_selectedImage != null)
                                  const Text(
                                    'Image analyzed',
                                    style: TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Only show breakdown if image was analyzed (not null)
                      if (_safetyData!['breakdown'] != null && 
                          _safetyData!['breakdown']['image_analysis'] != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Breakdown:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBreakdownItem(
                              'Image',
                              _safetyData!['breakdown']['image_analysis'],
                              showNA: true,
                            ),
                            _buildBreakdownItem(
                              'Weather',
                              _safetyData!['breakdown']['weather'] ?? 50,
                            ),
                            _buildBreakdownItem(
                              'User Reports',
                              _safetyData!['breakdown']['crime_data'] ?? 50,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _analyzeSafety,
        icon: const Icon(Icons.safety_check),
        label: const Text('Check Safety'),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, dynamic score, {bool showNA = false}) {
    final hasScore = score != null;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        hasScore
            ? Text(
                '$score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getSafetyColor(score),
                ),
              )
            : showNA
                ? const Text(
                    'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  )
                : const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
      ],
    );
  }
}
