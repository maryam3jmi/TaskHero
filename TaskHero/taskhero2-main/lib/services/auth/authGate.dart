import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskhero/parent/parentLoginPage.dart';
import 'package:taskhero/parent/ParentProgressScreen.dart';

class authGate extends StatelessWidget {
  const authGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return ParentProgressScreen();
        } else {
          return const ParentLoginPage();
        }
      },
    );
  }
}
