import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/rct_button.dart';
import '../widgets/rct_text_field.dart';

import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const LoginScreen({super.key, required this.onToggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (_name.text.isEmpty || _password.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Validate CIN is 3 digits
    if (_password.text.length != 3 ||
        !RegExp(r'^\d+$').hasMatch(_password.text)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('CIN must be 3 digits (last 3 digits of your CIN)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(_name.text, _password.text);

    if (!context.mounted) return; // Check mounted before calling setState

    setState(() => _isLoading = false);

    if (!context.mounted) return; // Check mounted again before using context

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Login failed. Check your name and CIN last 3 digits.')),
      );
    } else {
      // Load user preferences (theme, font scale)
      if (authService.currentUser != null) {
        if (context.mounted) {
          Provider.of<ThemeService>(context, listen: false)
              .loadFromUser(authService.currentUser!);
        }
      }
      // Navigate back to root (which will now be the AppShell/AdminShell thanks to main.dart AuthWrapper)
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Text(
                  "RCT",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onToggleTheme,
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const AuthHeader(
              title: "Ready to run?",
              subtitle: "Log in to see today's sessions and your group events.",
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Log in",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      identifier: 'auth_login_name',
                      child: RctTextField(
                        controller: _name,
                        label: "Name",
                        hint: "Your full name",
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      identifier: 'auth_login_cin',
                      child: RctTextField(
                        controller: _password,
                        label: "CIN (last 3 digits)",
                        hint: "e.g. 438",
                        obscure: true,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        "Enter the last 3 digits of your CIN",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.grey : Colors.black87,
                        ),
                        child: const Text("Forgot CIN?"),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        identifier: 'bouton_login',
                        child: RctButton(
                          text: _isLoading ? "Logging in..." : "Continue",
                          onPressed:
                              _isLoading ? () {} : () => _handleLogin(context),
                          isLoading: _isLoading,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New here? ",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.75)
                                : Colors.black.withValues(alpha: 0.65),
                          ),
                        ),
                        Semantics(
                          identifier: 'bouton_create_account',
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignUpScreen(
                                    onToggleTheme: widget.onToggleTheme,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: const Text(
                              "Create account",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
