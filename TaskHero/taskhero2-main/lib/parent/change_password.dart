import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'edit_profile_page.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({
    super.key,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String userEmail = "";
  bool isLoading = true;

  /// PASSWORD VISIBILITY STATES
  bool showOldPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    loadUserEmail();
  }

  /// LOAD USER EMAIL
  Future<void> loadUserEmail() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final res = await supabase
          .from('parent')
          .select('parent_email')
          .eq('parent_id', user.id)
          .single();

      setState(() {
        userEmail = res['parent_email'] ?? "";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading email: $e")),
      );
    }
  }

  /// CHANGE PASSWORD
  Future<void> changePassword() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      /// CHECK OLD PASSWORD
      try {
        await supabase.auth.signInWithPassword(
          email: userEmail,
          password: oldPassword,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Current password is wrong")),
        );
        return;
      }

      /// PASSWORD MATCH
      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")),
        );
        return;
      }

      /// PASSWORD LENGTH
      if (newPassword.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be at least 8 characters")),
        );
        return;
      }

      /// UPPERCASE
      if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must contain 1 uppercase letter")),
        );
        return;
      }

      /// SYMBOL
      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must contain 1 symbol")),
        );
        return;
      }

      /// CLEAR OTP FIELD BEFORE SENDING
      otpController.clear();

      /// SEND OTP
      await supabase.auth.signInWithOtp(
        email: userEmail,
      );

      /// OPEN OTP DIALOG
      showOtpDialog(newPassword);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// OTP DIALOG
  void showOtpDialog(String newPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFA9CDE3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Verify OTP",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Enter the OTP sent to\n$userEmail",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "OTP",
                    hintText: "Enter code",
                    filled: true,
                    fillColor: const Color(0xFFD9E4F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Color(0xFFF9CF45),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    /// CANCEL
                    SizedBox(
                      width: 120,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    /// VERIFY
                    SizedBox(
                      width: 120,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final code = otpController.text.trim();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Enter OTP code")),
                            );
                            return;
                          }

                          try {
                            final response = await supabase.auth.verifyOTP(
                              email: userEmail,
                              token: code,
                              type: OtpType.email,
                            );

                            if (response.session == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Wrong OTP code")),
                              );
                              return;
                            }

                            /// UPDATE PASSWORD
                            await supabase.auth.updateUser(
                              UserAttributes(password: newPassword),
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password changed successfully"),
                              ),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Wrong OTP code")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9CF45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Verify",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  /// REUSABLE PASSWORD TEXTFIELD WIDGET
  Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFD9E4F5),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Color(0xFFF9CF45),
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFA9CDE3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA9CDE3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              /// TITLE
              const Center(
                child: Text(
                  "Change Password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              /// OLD PASSWORD FIELD
              buildPasswordField(
                controller: oldPasswordController,
                label: "Current Password",
                hint: "Enter current password",
                isVisible: showOldPassword,
                toggle: () {
                  setState(() {
                    showOldPassword = !showOldPassword;
                  });
                },
              ),
              const SizedBox(height: 20),

              /// NEW PASSWORD FIELD
              buildPasswordField(
                controller: newPasswordController,
                label: "New Password",
                hint: "Enter new password",
                isVisible: showNewPassword,
                toggle: () {
                  setState(() {
                    showNewPassword = !showNewPassword;
                  });
                },
              ),
              const SizedBox(height: 20),

              /// CONFIRM PASSWORD FIELD
              buildPasswordField(
                controller: confirmPasswordController,
                label: "Confirm Password",
                hint: "Re-enter password",
                isVisible: showConfirmPassword,
                toggle: () {
                  setState(() {
                    showConfirmPassword = !showConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 40),

              /// ACTION BUTTON
              SizedBox(
                width: 300,
                height: 55,
                child: ElevatedButton(
                  onPressed: changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9CF45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Change Password",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

