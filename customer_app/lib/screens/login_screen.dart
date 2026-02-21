import 'package:customer_app/features/auth/cubit/auth_cubit.dart';
import 'package:customer_app/features/auth/cubit/auth_state.dart';
import 'package:customer_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
  if (_formKey.currentState!.validate()) {
    final formattedNumber = "+91${_phoneController.text.trim()}";

    context.read<AuthCubit>().sendOtp(formattedNumber);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is CodeSent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OtpScreen(verificationId: state.verificationId),
              ),
            );
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Image.asset(
                        'assets/images/login_bg.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Let's Get Started",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Sign in to continue with your mobile number",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "Mobile Number",
                        border: OutlineInputBorder(),
                        prefixText: "+91 ",
                        counterText: "",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter mobile number";
                        }
                        if (value.length != 10) {
                          return "Enter valid 10-digit number";
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return "Only digits allowed";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "An 6-digit OTP will be sent via SMS to verify your mobile number",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;

                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _sendOtp,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Send OTP"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().verifyOtp(
        widget.verificationId,
        _otpController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const HomeScreen(), 
              ),
              (route) => false,
            );
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter OTP";
                    }
                    if (value.length != 6) {
                      return "Enter valid 6-digit OTP";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _verifyOtp,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Verify"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
