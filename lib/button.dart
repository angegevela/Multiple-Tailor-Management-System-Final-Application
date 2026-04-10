import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Admin/login/admin_login.dart';
import 'package:threadhub_system/Customer/signup/customer_signup.dart';
import 'package:threadhub_system/Tailor/signup/tailor_shops%20-%20signup.dart';

// role button for three users(customer, tailor, administrator)
class User_Button extends StatelessWidget {
  final String role;
  const User_Button({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF6082B6), elevation: 2),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Hello, User!',
                  style: GoogleFonts.jockeyOne(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Please choose a button that suits \n you',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mPlusCodeLatin(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SignupRegister(role: 'Customer'),
                      ),
                    );
                  },
                  child: userTile(
                    imagePath: 'assets/icons/customer.png',
                    label: 'Customer',
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TailorSignUpPage(role: 'Tailor'),
                      ),
                    );
                  },
                  child: userTile(
                    imagePath: 'assets/icons/tailor.png',
                    label: 'Tailor/Tailor Shop',
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminLoginPage(),
                      ),
                    );
                  },
                  child: userTile(
                    imagePath: 'assets/icons/systemadministration.png',
                    label: 'Admin',
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget userTile({required String imagePath, required String label}) {
    return Container(
      width: 300,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white70,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(4.0, 4.0),
            blurRadius: 10.0,
            // spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 110, fit: BoxFit.contain),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.labrada(color: Colors.black, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
