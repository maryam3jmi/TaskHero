import 'package:flutter/material.dart';
import 'package:taskhero/services/auth/auth_services.dart';
import 'parentSignupPage.dart';
import 'ForgutPass.dart';
import 'ParentProgressScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskhero/services/session.dart';
import '/api/firebase_api.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';

final supabase = Supabase.instance.client;

class ParentLoginPage extends StatefulWidget {
  const ParentLoginPage({super.key});

  @override
  State<ParentLoginPage> createState() => _parentLoginPageState();
}

class _parentLoginPageState extends State<ParentLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final authService = auth_services();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? parentError;
  bool _isLoading = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      parentError = null;
      _isLoading = true;
    });

    try {
      // Login with Supabase
      final response = await authService.signInWithEmailPassword(
        email,
        password,
      );

      final user = response.user;

      if (user == null) {
        setState(() {
          parentError = "Login failed. Please try again.";
        });
        return;
      }

      //  parent exists in your table?
      final parentCheck = await supabase
          .from('parent')
          .select()
          .eq('parent_id', user.id)
          .maybeSingle();

      if (parentCheck == null) {
        await supabase.auth.signOut();
        setState(() {
          parentError = "No parent account linked to this user.";
        });
        return;
      }

      AppSession.userId = user.id;
      AppSession.username = user.email;
      AppSession.userRole = "parent";
      AppSession.parentId = user.id;

       // Notifications init
      await FirebaseApi().initNotification(user.id, 'parent');

      Navigator.pushReplacement(
        context,
       MaterialPageRoute(builder: (context) => ParentProgressScreen()),
      );
    } on AuthException {
      setState(() {
        parentError = "Incorrect email or password.";
      });
    } catch (e) {
      print("LOGIN ERROR: $e");
      setState(() {
        parentError = "Something went wrong. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFA9CDE3),
      appBar: AppBar(
        backgroundColor: Color(0xFFA9CDE3),
        elevation: 0,
        leading: IconButton(
          // Back Arrow
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // color: Color(0xFFA9CDE3), // blue background
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                  SizedBox(height: 90),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your email to login";
                          }

                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

                          if (!emailRegex.hasMatch(value)) {
                            return "Enter a valid email (example: test@mail.com)";
                          }

                          return null;
                        },

                        decoration: InputDecoration(
                          hintText: "email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color: Color(0xFFF9CF45),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Color(0xFFD9E4F5),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      // password feild
                      TextFormField(
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your password";
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color: Color(0xFFF9CF45),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Color(0xFFD9E4F5),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                      if (parentError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            parentError!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Forget Password done
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgutPass(),
                        ),
                      );
                    },
                    child: const Text(
                      "forget password?",
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ),

                  Spacer(),

                  // Login Button
                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            login();
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF9CF45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(25),
                          ),
                        ),

                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom Text
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const parentSignupPage(),
                          ),
                        );
                      },
                      child: const Text(
                        " Don't have an account? create one",
                        style: TextStyle(color: Colors.black),
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
