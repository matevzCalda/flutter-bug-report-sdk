import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/supabase.dart';

const _borderColor = Color(0xFFE4E4E7);
const _foregroundColor = Color(0xFF18181B);
const _sidebarForeground = Color(0xFF3F3F46);
const _primaryForeground = Color(0xFFFAFAFA);
const _hintColor = Color(0xFFA1A1AA);
const _secondaryText = Color(0xFF71717A);
const _errorColor = Color(0xFFDC2626);

Future<bool?> showCaldaLoginSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _LoginSheetContent(),
  );
}

class _LoginSheetContent extends StatefulWidget {
  const _LoginSheetContent();

  @override
  State<_LoginSheetContent> createState() => _LoginSheetContentState();
}

class _LoginSheetContentState extends State<_LoginSheetContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      !_loading;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_rebuild);
    _passwordController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _emailController.removeListener(_rebuild);
    _passwordController.removeListener(_rebuild);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final error = await signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.fromBorderSide(BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 17.9,
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 71,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(Icons.close,
                          size: 20, color: _sidebarForeground),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Header image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.black,
                    child: Image.asset(
                      'assets/login-page.png',
                      package: 'calda_bug_sdk',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _foregroundColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to submit bug reports',
                  style: TextStyle(
                    fontSize: 14,
                    color: _secondaryText,
                  ),
                ),
                const SizedBox(height: 24),
                // Email
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _sidebarForeground,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, color: _foregroundColor),
                ),
                const SizedBox(height: 12),
                // Password
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _sidebarForeground,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, color: _foregroundColor),
                ),
                // Error
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 13, color: _errorColor),
                  ),
                ],
                const SizedBox(height: 16),
                // Login button
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _handleLogin : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _foregroundColor,
                      foregroundColor: _primaryForeground,
                      disabledBackgroundColor:
                          _foregroundColor.withValues(alpha: 0.5),
                      disabledForegroundColor:
                          _primaryForeground.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Text(_loading ? 'Signing in...' : 'Log in'),
                  ),
                ),
                const SizedBox(height: 24),
                // Manage account link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      launchUrl(
                        Uri.parse(
                            'https://calda-bugsense-frontend.vercel.app/login'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: const Text(
                      'Manage account',
                      style: TextStyle(
                        fontSize: 13,
                        color: _secondaryText,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
