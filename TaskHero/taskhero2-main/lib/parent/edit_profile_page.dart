import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'change_password.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskhero/splash_screen.dart';
//this is the last parent folder
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String profilePic = "";
  String originalEmail = "";
  bool isLoading = true;

  String? _pendingNewEmail;
  String? _originalUserId;

  @override
  void initState() {
    super.initState();
    loadParentData();
  }

  Future<void> loadParentData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final res = await supabase
          .from('parent')
          .select()
          .eq('parent_id', user.id)
          .maybeSingle();

      if (res == null) {
        setState(() => isLoading = false);
        return;
      }
      if (!mounted) return;

      setState(() {
        nameController.text = res['parent_name'] ?? '';
        emailController.text = res['parent_email'] ?? '';
        originalEmail = res['parent_email'] ?? '';
        profilePic = res['parent_pic'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final extension = image.name.split('.').last;
      final fileName =
          "parent_avatar/${user.id}_${DateTime.now().millisecondsSinceEpoch}.$extension";

      await supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('parent')
          .update({'parent_pic': imageUrl}).eq('parent_id', user.id);

      setState(() => profilePic = imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated")),
        );
      }
    } catch (e) {
      debugPrint("Image upload error: $e");
    }
  }

  Future<void> saveChanges() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final newEmail = emailController.text.trim();

      if (newEmail != originalEmail) {
        // Capture user id and send OTP to OLD email only.
        // We do NOT touch the new email via auth — avoids session hijack.
        _originalUserId = user.id;
        _pendingNewEmail = newEmail;
        await supabase.auth.signInWithOtp(email: originalEmail);
        if (!mounted) return;
        _showOtpDialog();
        return;
      }

      // Name-only change
      await supabase
          .from('parent')
          .update({'parent_name': nameController.text.trim()}).eq(
              'parent_id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated")),
      );
      await loadParentData();
    } catch (e) {
      debugPrint("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showOtpDialog() {
    otpController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFA9CDE3),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Verify Identity",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Enter the OTP sent to your current email:\n$originalEmail",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
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
                      borderRadius: BorderRadius.circular(30)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        const BorderSide(color: Color(0xFFF9CF45), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 120,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        otpController.clear();
                        _pendingNewEmail = null;
                        _originalUserId = null;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _handleOtpVerify(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9CF45),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text(
                        "Verify",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleOtpVerify(BuildContext dialogContext) async {
    final code = otpController.text.trim();

    try {
      // Verify OTP for old email — session stays on original user after this.
      final response = await supabase.auth.verifyOTP(
        email: originalEmail,
        token: code,
        type: OtpType.email,
      );

      if (response.session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Wrong OTP. Try again.")),
          );
        }
        return;
      }

      // Session is valid and still belongs to the original user.
      // Call RPC with explicit user_id — does not rely on auth.uid().
      // Required SQL (run once in Supabase SQL editor):
      //
      // create or replace function update_user_email_by_id(user_id uuid, new_email text)
      // returns void as $$
      // begin
      //   update auth.users
      //   set email = new_email,
      //       email_confirmed_at = now(),
      //       updated_at = now()
      //   where id = user_id;
      // end;
      // $$ language plpgsql security definer;
      //
      // The trigger on_auth_user_email_updated fires here and updates parent_email.
      await supabase.rpc('update_user_email_by_id', params: {
        'user_id': _originalUserId!,
        'new_email': _pendingNewEmail!,
      });

      // Also update name and parent_email directly as safety net.
      await supabase.from('parent').update({
        'parent_name': nameController.text.trim(),
        'parent_email': _pendingNewEmail!,
      }).eq('parent_id', _originalUserId!);

      final updatedEmail = _pendingNewEmail!;
      _pendingNewEmail = null;
      _originalUserId = null;
      otpController.clear();

      if (!mounted) return;
      Navigator.pop(dialogContext);

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFA9CDE3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Email Updated",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Your email has been changed to\n$updatedEmail"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      originalEmail = updatedEmail;
      await loadParentData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Edit Account",
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: pickProfileImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profilePic.isNotEmpty
                            ? NetworkImage(profilePic)
                            : null,
                        child: profilePic.isEmpty
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Color(0xFFF9CF45),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            size: 18, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Current Email",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9E4F5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        originalEmail,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: "Enter full name",
                  filled: true,
                  fillColor: const Color(0xFFD9E4F5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        const BorderSide(color: Color(0xFFF9CF45), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'New Email Address',
                  hintText: "Enter new email",
                  filled: true,
                  fillColor: const Color(0xFFD9E4F5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        const BorderSide(color: Color(0xFFF9CF45), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              Center(
                child: SizedBox(
                  width: 300,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9CF45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage()),
                  ),
                  child: const Text(
                    "Change Password?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              Center(
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFFA9CDE3),
                        title: const Text("Log Out"),
                        content:
                            const Text("Are you sure you want to log out?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await supabase.auth.signOut();
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SplashScreen()),
                                (route) => false,
                              );
                            },
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      decoration: TextDecoration.underline,
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