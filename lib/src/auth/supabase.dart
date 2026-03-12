import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://uubykxezfezmlsbqwbfx.supabase.co';
const _supabaseKey = 'sb_publishable_D9buhiSqNLtbG06M1-LlvA_iWnPi9ef';

bool _initialized = false;

bool get isSupabaseInitialized => _initialized;

Future<void> ensureSupabaseInitialized() async {
  if (_initialized) return;
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);
  _initialized = true;
}

SupabaseClient getSupabaseClient() => Supabase.instance.client;

Session? getSession() {
  if (!_initialized) return null;
  return Supabase.instance.client.auth.currentSession;
}

Future<String?> signIn(String email, String password) async {
  try {
    await getSupabaseClient().auth.signInWithPassword(
      email: email,
      password: password,
    );
    return null;
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

Future<void> signOut() async {
  await getSupabaseClient().auth.signOut();
}
