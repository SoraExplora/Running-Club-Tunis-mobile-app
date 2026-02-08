import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const SplashScreen({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/splashscreen.jpg',
            fit: BoxFit.cover,
          ),

          // Dark overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + club name
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/RCTCONNECT2.png',
                        width: 44,
                        height: 44,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "RUNNING CLUB TUNIS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),

                  // Only move TEXT up (into the sky area)
                  SizedBox(height: h * 0.16), // tweak 0.14–0.20 if needed

                  Text(
                    "COME JOIN\nUS & RUN",
                    style: GoogleFonts.oswald(
                      fontSize: 38,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Run with purpose. Join a community that inspires healthy living, discipline, and the joy of becoming your best self.",
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),

                  // Push buttons down (like before)
                  const Spacer(flex: 2),

                  // Continue as guest button
                  Semantics(
                    identifier: 'bouton_login',
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: onLogin,
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Login outline button
                  Semantics(
                    identifier: 'bouton_guest',
                    child: SizedBox(
                      height: 35,
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.45)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                        ),
                        onPressed: onGetStarted,
                        child: const Text(
                          "Continue as guest",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
