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

/// Returns a fresh access token, refreshing the session if needed.
Future<String?> getAccessToken() async {
  if (!_initialized) return null;
  final auth = Supabase.instance.client.auth;
  var session = auth.currentSession;
  if (session == null) return null;

  // If the token is expired or about to expire (within 30s), refresh it.
  if (session.isExpired ||
      (session.expiresAt != null &&
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
              .difference(DateTime.now())
              .inSeconds <
              30)) {
    try {
      final response = await auth.refreshSession();
      session = response.session;
    } catch (_) {
      // Fall back to current token even if refresh fails
    }
  }
  return session?.accessToken;
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
