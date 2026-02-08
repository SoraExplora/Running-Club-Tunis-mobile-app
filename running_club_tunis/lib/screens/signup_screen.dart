import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/rct_button.dart';
import '../widgets/rct_text_field.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const SignUpScreen({super.key, required this.onToggleTheme});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _cin = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _cin.dispose();
    super.dispose();
  }

Future<void> _handleRegister(BuildContext context) async {
  if (_name.text.isEmpty || _cin.text.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }

  // Validate CIN is 8 digits
  if (_cin.text.length != 8 || !RegExp(r'^\d+$').hasMatch(_cin.text)) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CIN must be exactly 8 digits')),
    );
    return;
  }

  setState(() => _isLoading = true);

  final authService = Provider.of<AuthService>(context, listen: false);
  final success = await authService.register(_name.text, _cin.text);

  if (!context.mounted) return; // Check mounted before calling setState
  
  setState(() => _isLoading = false);

  if (!context.mounted) return; // Check mounted again before using context

  if (!success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration failed. User may already exist or CIN is invalid.')),
    );
  } else {
    if (authService.currentUser != null) {
       if (context.mounted) {
        Provider.of<ThemeService>(context, listen: false).loadFromUser(authService.currentUser!);
       }
    }
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splashscreen.jpg',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withValues(alpha: 0.10)),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: textColor),
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
                const SizedBox(height: 8),
                const AuthHeader(
                  title: "Join the club.",
                  subtitle:
                      "Create your RCT account to access your group schedule.",
                ),
                const SizedBox(height: 16),
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
                          "Sign up",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        RctTextField(
                          controller: _name,
                          label: "Name",
                          hint: "Your full name",
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RctTextField(
                          controller: _cin,
                          label: "CIN (8 digits)",
                          hint: "e.g. 12345678",
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            "Enter your full 8-digit CIN number",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        Text(
                          "Note: You will use the last 3 digits of this CIN to login",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.orange[200] : Colors.orange[800],
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: RctButton(
                            text: _isLoading ? "Creating account..." : "Create account",
                            onPressed: _isLoading ? () {} : () => _handleRegister(context),
                            isLoading: _isLoading,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            "By creating an account, you agree to the club guidelines.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}