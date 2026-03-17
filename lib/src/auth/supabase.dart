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

/// Synchronous session check — may return a stale/expired session.
/// Use [getAccessToken] for a fresh token before making API calls.
Session? getSession() {
  if (!_initialized) return null;
  return Supabase.instance.client.auth.currentSession;
}

/// Returns a fresh access token, matching the web SDK's async getSession().
/// Calls auth.refreshSession() if current session is expired, ensuring the
/// backend always receives a valid Bearer token.
Future<String?> getAccessToken() async {
  if (!_initialized) return null;
  final auth = Supabase.instance.client.auth;

  // First try the cached session
  var session = auth.currentSession;

  // If no session or token is expired, try refreshing
  if (session == null || session.isExpired) {
    try {
      final response = await auth.refreshSession();
      session = response.session;
    } catch (_) {
      // Refresh failed — no valid token available
      return null;
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
