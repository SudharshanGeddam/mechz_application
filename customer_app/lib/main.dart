import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:customer_app/features/cubit/auth_cubit.dart';
import 'package:customer_app/features/cubit/auth_state.dart';
import 'package:customer_app/features/cubit/service_cubit.dart';
import 'package:customer_app/features/repository/auth_repository.dart';
import 'package:customer_app/features/repository/service_repository.dart';
import 'package:customer_app/firebase_options.dart';
import 'package:customer_app/screens/home_screen.dart';
import 'package:customer_app/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
  FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  FirebaseFunctions.instance.useFunctionsEmulator('10.0.2.2', 5001);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
        RepositoryProvider<ServiceRepository>(
          create: (_) => ServiceRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) =>
                AuthCubit(context.read<AuthRepository>())..checkAuthStatus(),
          ),
          BlocProvider<ServiceCubit>(
            create: (context) =>
                ServiceCubit(context.read<ServiceRepository>())..loadServices(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const RootRouter(),
        ),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
