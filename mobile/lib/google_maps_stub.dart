// Stub file for web - provides Google Maps types
import 'package:flutter/material.dart';

// Stub types for web compilation
class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class GoogleMapController {
  void animateCamera(dynamic update) {}
}

class CameraPosition {
  final LatLng target;
  final double zoom;
  const CameraPosition({required this.target, required this.zoom});
}

class CameraUpdate {
  static CameraUpdate newLatLng(LatLng location) {
    return CameraUpdate();
  }
}

class GoogleMap extends StatelessWidget {
  final CameraPosition initialCameraPosition;
  final Function(GoogleMapController)? onMapCreated;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final Function(LatLng)? onTap;

  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Maps not available on web'),
    );
  }
}

