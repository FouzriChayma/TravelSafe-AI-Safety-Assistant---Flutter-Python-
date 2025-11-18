// Stub file for web - maps not supported
import 'package:flutter/material.dart';

class MapStub extends StatelessWidget {
  final Function(double, double)? onLocationSelected;
  
  const MapStub({super.key, this.onLocationSelected});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Maps not available on web platform'),
    );
  }
}

