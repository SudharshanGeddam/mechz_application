import 'package:customer_app/features/cubit/auth_cubit.dart';
import 'package:customer_app/features/cubit/booking_cubit.dart';
import 'package:customer_app/features/cubit/booking_state.dart';
import 'package:customer_app/features/cubit/service_cubit.dart';
import 'package:customer_app/features/cubit/service_state.dart';
import 'package:customer_app/features/repository/service_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ServiceCubit(ServiceRepository())..loadServices(),
        ),
        BlocProvider(create: (_) => BookingCubit()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Services"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthCubit>().signOut();
              },
            ),
          ],
        ),
        body: BlocListener<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingLoading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
            }

            if (state is BookingSuccess) {
              Navigator.pop(context); // close loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Service request created successfully"),
                ),
              );
            }

            if (state is BookingError) {
              Navigator.pop(context); // close loading
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: BlocBuilder<ServiceCubit, ServiceState>(
            builder: (context, state) {
              if (state is ServiceLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ServiceLoaded) {
                return ListView.builder(
                  itemCount: state.services.length,
                  itemBuilder: (context, index) {
                    final service = state.services[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(service.name),
                        subtitle: Text(
                          "₹${service.basePrice.toStringAsFixed(0)}",
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            context.read<BookingCubit>().bookService(
                              service.name,
                            );
                          },
                          child: const Text("Book"),
                        ),
                      ),
                    );
                  },
                );
              }

              if (state is ServiceError) {
                return Center(child: Text(state.message));
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
