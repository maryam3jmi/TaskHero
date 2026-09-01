import 'package:flutter/material.dart';
import 'passCode.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgutPass extends StatefulWidget {
  const ForgutPass({super.key});

  @override
  State<ForgutPass> createState() => _ForgutPassState();
}

class _ForgutPassState extends State<ForgutPass> {
  final _emailController = TextEditingController();
  String? emailError;

  Future<void> sendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        emailError = "Email cannot be empty";
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('parent')
          .select()
          .eq('parent_email', email)
          .maybeSingle();

      if (response == null) {
        setState(() {
          emailError = "This email is not registered";
        });
        return;
      }

      setState(() {
        emailError = null;
      });

      // Send OTP
      await Supabase.instance.client.auth.signInWithOtp(email: email);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PassCode(email: email)),
      );
    } catch (e) {
      setState(() {
        emailError = "Something went wrong";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA9CDE3),
      appBar: AppBar(backgroundColor: const Color(0xFFA9CDE3), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "We will send you a code through your email",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 60),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Email",
                errorText: emailError,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Color(0xFFF9CF45), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFD9E4F5),
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: sendCode,

              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF9CF45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(25),
                ),
              ),

              child: const Text("Send Code"),
            ),
          ],
        ),
      ),
    );
  }
}
