import 'package:flutter/material.dart';
import '../services/auth/auth_services.dart';
import '../mainScreen.dart';

class parentSignupPage extends StatefulWidget {
  const parentSignupPage({super.key});

  @override
  State<parentSignupPage> createState() => _parentSignupPage();
}

class _parentSignupPage extends State<parentSignupPage> {
  final Auth_services = auth_services();
  final _formKey = GlobalKey<FormState>(); // Form key
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  void signup() async {
    if (!_formKey.currentState!.validate()) {
      // If form is invalid, stop
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    try {
      final response = await Auth_services.signUpWithEmailPassword(
        email,
        password,
      );
      final user = response.user;

      if (user != null) {
        await Auth_services.addParentToTable(
          userId: user.id,
          email: email,
          name: username,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => mainScreen()),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Sign-up failed")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA9CDE3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA9CDE3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "Sign-up",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: "Enter username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFD9E4F5),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: "Enter email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFD9E4F5),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email cannot be empty';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                      ).hasMatch(value.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  TextFormField(
                    controller: _passwordController,

                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: "Enter password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFD9E4F5),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password cannot be empty';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Password must contain at least 1 uppercase letter';
                      }
                      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        return 'Password must contain at least 1 symbol';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Signup button
                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9CF45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Sign-up",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
