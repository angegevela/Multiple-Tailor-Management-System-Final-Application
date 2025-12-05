import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:threadhub_system/Auth/sigInWithGoogle.dart';
import 'package:threadhub_system/Pages/home_page.dart';
import 'package:threadhub_system/button.dart';

class SignUpPage extends StatefulWidget {
  final String role;
  const SignUpPage({super.key, required this.role});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GoogleAuthService _authService = GoogleAuthService();
  @override
  void initState() {
    super.initState();
    print('Role selected: ${widget.role}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/img/welcome.png', width: 300, height: 300),
                const SizedBox(height: 20),
                Text(
                  'Hello, Welcome!',
                  style: GoogleFonts.jockeyOne(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome to ThreadHub\nwhere you can schedule and consult with ease',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.black),
                ),
                const SizedBox(height: 30),
                _buildSignUpButton(context),
                const SizedBox(height: 30),
                Text(
                  'Or continue with',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 20),
                _buildSocialIcons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => User_Button(role: widget.role)),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF72A0C1),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        minimumSize: const Size(300, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        'Sign Up',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF303030),
        ),
      ),
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialIcon(MdiIcons.facebook, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Facebook sign-in not implemented')),
          );
        }),

        _socialIcon(MdiIcons.gmail, () async {
          User? user = await _authService.signInWithGoogle();
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google sign-in failed')),
            );
          }
        }),
      ],
    );
  }

  Widget _socialIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: const Color(0xFF72A0C1), size: 50),
      ),
    );
  }
}
