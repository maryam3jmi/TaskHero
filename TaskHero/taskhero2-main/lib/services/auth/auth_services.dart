import 'package:supabase_flutter/supabase_flutter.dart';

class auth_services {
  final SupabaseClient _supabase = Supabase.instance.client;

  //sign in (log in) with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  //sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  //add new users to the parent table
  Future<void> addParentToTable({
    required String userId,
    required String email,
    String? name,
  }) async {
     await _supabase.from('parent').insert({
    'parent_id': userId, // link to auth
     'parent_email': email,
     'parent_name': name,
     });
  }
}
