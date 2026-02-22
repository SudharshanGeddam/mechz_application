import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTrackingView extends StatefulWidget {
  final double customerLat;
  final double customerLng;
  final double mechanicLat;
  final double mechanicLng;

  const MapTrackingView({
    super.key,
    required this.customerLat,
    required this.customerLng,
    required this.mechanicLat,
    required this.mechanicLng,
  });

  @override
  State<MapTrackingView> createState() => _MapTrackingViewState();
}

class _MapTrackingViewState extends State<MapTrackingView> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final customer = LatLng(widget.customerLat, widget.customerLng);
    final mechanic = LatLng(widget.mechanicLat, widget.mechanicLng);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: customer, zoom: 14),
          onMapCreated: (controller) {
            _mapController = controller;

            // Delay camera animation slightly to ensure map is ready
            Future.delayed(const Duration(milliseconds: 400), () {
              if (!mounted) return;
              _animateCamera(customer, mechanic);
            });
          },
          markers: {
            Marker(
              markerId: const MarkerId("customer"),
              position: customer,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
            Marker(
              markerId: const MarkerId("mechanic"),
              position: mechanic,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId("route"),
              points: [customer, mechanic],
              width: 4,
            ),
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),

        // Bottom panel
        _buildBottomPanel(),
      ],
    );
  }

  void _animateCamera(LatLng customer, LatLng mechanic) {
    if (_mapController == null) return;

    // If mechanic and customer are far, show both inside bounds
    if (widget.mechanicLat != widget.customerLat ||
        widget.mechanicLng != widget.customerLng) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(widget.customerLat, widget.mechanicLat),
          min(widget.customerLng, widget.mechanicLng),
        ),
        northeast: LatLng(
          max(widget.customerLat, widget.mechanicLat),
          max(widget.customerLng, widget.mechanicLng),
        ),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: customer, zoom: 16),
        ),
      );
    }
  }

  Widget _buildBottomPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "Mechanic is on the way",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("ETA: Calculating..."),
          ],
        ),
      ),
    );
  }
}
