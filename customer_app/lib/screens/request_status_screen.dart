import 'package:customer_app/features/cubit/request_status_cubit.dart';
import 'package:customer_app/features/cubit/request_status_state.dart';
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
        appBar: AppBar(title: const Text("Request Status")),
        body: BlocBuilder<RequestStatusCubit, RequestStatusState>(
          builder: (context, state) {
            if (state is RequestStatusLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RequestStatusUpdated) {
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
                    if (state.status == "SEARCHING")
                      const Text("Searching for nearby mechanics..."),
                    if (state.status == "ACCEPTED")
                      const Text("Mechanic accepted your request"),
                    if (state.status == "ARRIVING")
                      const Text("Mechanic is on the way"),
                    if (state.status == "IN_PROGRESS")
                      const Text("Service in progress"),
                    if (state.status == "COMPLETED")
                      const Text("Service completed"),
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
