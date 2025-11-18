// Mobile version with actual Google Maps
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final LatLng initialLocation;
  final Function(LatLng)? onLocationSelected;
  final Function(GoogleMapController)? onMapCreated;

  const MapWidget({
    super.key,
    required this.initialLocation,
    this.onLocationSelected,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: 15,
      ),
      onMapCreated: onMapCreated,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onTap: onLocationSelected,
    );
  }
}

