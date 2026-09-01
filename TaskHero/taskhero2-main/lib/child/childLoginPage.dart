import 'package:flutter/material.dart';
import 'package:taskhero/child/child_home_test.dart';
import 'package:taskhero/child/child_main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:taskhero/services/session.dart';
import '/api/firebase_api.dart';
//import 'package:taskhero/parent/parentActivityPage.dart';

final supabase = Supabase.instance.client;

class Childloginpage extends StatefulWidget {
  const Childloginpage({super.key});

  @override
  State<Childloginpage> createState() => _Childloginpage();
}

class _Childloginpage extends State<Childloginpage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? childtError;

  void login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      childtError = null;
    });

    try {
      final child = await supabase
          .from('child')
          .select()
          .eq('child_username', username)
          .maybeSingle();

      if (child == null) {
        setState(() {
          childtError = "Incorrect Username or password.";
        });
        return;
      }

      final storedHash = child['child_password'].toString().trim();
      bool passwordMatch = BCrypt.checkpw(password, storedHash);

      if (!passwordMatch) {
        setState(() {
          childtError = "Username or password is incorrect";
        });
        return;
      }

      final familyCheck = await supabase
          .from('Family')
          .select()
          .eq('child_id', child['child_id'])
          .maybeSingle();

      if (familyCheck == null) {
        setState(() {
          childtError = "Child is not linked to a parent.";
        });
        return;
      }

      AppSession.userId = child['child_id'];
      AppSession.username = child['child_username'];
      AppSession.userRole = "child";
      AppSession.childId = child['child_id'];
      AppSession.parentId = familyCheck['parent_id'];
      await FirebaseApi().initNotification(
        child['child_id'].toString(),
        'child',
      );

      //  Navigate to  child main
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChildHomePage(childId: child['child_id'].toString()),
        ),
      );
      
      
    } catch (e) {
      setState(() {
        childtError = "Login failed. Please try again.";
      });
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
          onPressed: () {
            Navigator.pop(context);
          },
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
                      "Login",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 90),

                  const Text(
                    'Username',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your username";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color(0xFFF9CF45),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFD9E4F5),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

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
                        borderSide: const BorderSide(
                          color: Color(0xFFF9CF45),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFD9E4F5),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 3,
                        ),
                      ),
                    ),
                  ),

                  if (childtError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        childtError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const Spacer(),

                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9CF45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
