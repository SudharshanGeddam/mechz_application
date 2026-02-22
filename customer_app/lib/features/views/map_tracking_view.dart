import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTrackingView extends StatefulWidget {
  final double customerLat;
  final double customerLng;
  final double mechanicLat;
  final double mechanicLng;
  final String status;

  const MapTrackingView({
    super.key,
    required this.customerLat,
    required this.customerLng,
    required this.mechanicLat,
    required this.mechanicLng,
    required this.status,
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
  return DraggableScrollableSheet(
    initialChildSize: 0.18,
    minChildSize: 0.12,
    maxChildSize: 0.45,
    builder: (context, scrollController) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
            ),
          ],
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // Drag Handle
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [

                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Mechanic Name",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text("4.8 ★ | 120 Jobs"),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.call),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Divider(),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Status"),
                    Text(
                      widget.status,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Estimated Arrival"),
                    Text(
                      "5 mins",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}
