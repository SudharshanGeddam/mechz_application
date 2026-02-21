import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:customer_app/features/auth/cubit/auth_cubit.dart';
import 'package:customer_app/features/auth/cubit/auth_state.dart';
import 'package:customer_app/features/auth/repository/auth_repository.dart';
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

  try {
    await FirebaseAuth.instance.signInAnonymously();
    print("Auth emulator connected");
  } catch (e) {
    print("Auth error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(AuthRepository())..checkAuthStatus(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const RootRouter(),
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
