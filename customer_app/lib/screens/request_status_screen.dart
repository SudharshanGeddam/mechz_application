import 'package:customer_app/features/cubit/request_status_cubit.dart';
import 'package:customer_app/features/cubit/request_status_state.dart';
import 'package:customer_app/features/views/map_tracking_view.dart';
import 'package:customer_app/features/views/searching_radar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestStatusScreen extends StatelessWidget {
  final String requestId;

  const RequestStatusScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RequestStatusCubit(requestId),
      child: Scaffold(
        body: BlocBuilder<RequestStatusCubit, RequestStatusState>(
          builder: (context, state) {
            if (state is RequestStatusLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RequestStatusUpdated) {
              if (state.status == "SEARCHING") {
                return const SearchingRadarView();
              } else if (state.status == "ACCEPTED") {
                return MapTrackingView(
                  customerLat: state.customerLat,
                  customerLng: state.customerLng,
                  mechanicLat: state.customerLat + 0.002,
                  mechanicLng: state.customerLng + 0.002,
                );
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.status,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }

            if (state is RequestStatusError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
