import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ParentProgressScreen.dart';
import 'package:taskhero/services/session.dart';

class PassCode extends StatefulWidget {
  final String email;
  const PassCode({super.key, required this.email});

  @override
  State<PassCode> createState() => _PassCodeState();
}

// class _PassCodeState extends State<PassCode> {
//   final _codeController = TextEditingController();

//   Future<void> verifyCode() async {
//     final code = _codeController.text.trim();

//     if (code.isEmpty) return;

//     final response = await Supabase.instance.client.auth.verifyOTP(
//       email: widget.email,
//       token: code,
//       type: OtpType.email,
//     );

//     if (response.session != null) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => ParentProgressScreen()),
//         (route) => false,
//       );
//     }
//   }
class _PassCodeState extends State<PassCode> {
  final _codeController = TextEditingController();

  String errorMessage = "";

  Future<void> verifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) return;

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.email,
      );

      if (response.session != null) {
        final user = response.session!.user;

        AppSession.userId = user.id;
        AppSession.parentId = user.id;
        //AppSession.email = user.email;

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ParentProgressScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = "Wrong verification code";
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
              "Enter the code sent to your email",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 60),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Code",
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
            const SizedBox(height: 8),

            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF9CF45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(25),
                ),
              ),

              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
