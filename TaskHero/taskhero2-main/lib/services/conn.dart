import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://iwdlfqimfriayelhlblw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3ZGxmcWltZnJpYXllbGhsYmx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA3MjgyNjEsImV4cCI6MjA4NjMwNDI2MX0.DA1w6M7s1UvjIf6Yv95OoHsTbtdd0tl3TCvesuVTI_M',
  );
}

