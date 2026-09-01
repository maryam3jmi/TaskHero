
import 'package:supabase_flutter/supabase_flutter.dart';


class SupabaseManager {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://iwdlfqimfriayelhlblw.supabase.co',
      anonKey: 'sb_publishable_r7ILewNap_Jy6gI-tojCtA_lKj9SC3a',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
