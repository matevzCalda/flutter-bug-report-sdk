import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://uubykxezfezmlsbqwbfx.supabase.co';
const _supabaseKey = 'sb_publishable_D9buhiSqNLtbG06M1-LlvA_iWnPi9ef';

/// The SDK's own isolated Supabase client — completely separate from the
/// host app's Supabase.instance singleton.
SupabaseClient? _client;

bool get isSupabaseInitialized => _client != null;

Future<void> ensureSupabaseInitialized() async {
  if (_client != null) return;
  _client = SupabaseClient(_supabaseUrl, _supabaseKey);
}

SupabaseClient getSupabaseClient() {
  if (_client == null) {
    throw StateError('CaldaBug Supabase not initialized. '
        'Call ensureSupabaseInitialized() first.');
  }
  return _client!;
}

/// Synchronous session check — may return a stale/expired session.
/// Use [getAccessToken] for a fresh token before making API calls.
Session? getSession() {
  return _client?.auth.currentSession;
}

/// Returns a fresh access token.
/// Refreshes the session if expired, ensuring the backend always receives
/// a valid Bearer token.
Future<String?> getAccessToken() async {
  if (_client == null) return null;
  final auth = _client!.auth;

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
