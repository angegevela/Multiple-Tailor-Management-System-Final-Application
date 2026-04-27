import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Customer/signup/customer_homepage.dart';
import 'package:threadhub_system/Pages/login_page.dart';
import 'package:threadhub_system/Tailor/pages/menu item/tailor_availabilitysettings.dart';
import 'package:threadhub_system/Tailor/pages/tailorhomepage.dart';

class ApprovalPendingScreen extends StatelessWidget {
  final String userId;

  const ApprovalPendingScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['accountStatus'] ?? 'pending';
        final role = data['role'];

        if (status == 'approved') {
          Future.microtask(() {
            if (role == 'Customer') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => CustomerHomePage()),
              );
            } else if (role == 'Tailor') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const TailorAvailabilitySettings(),
                ),
              );
            }
          });
        }

        if (status == 'rejected') {
          return Scaffold(
            body: Center(
              child: Text(
                "Your account was rejected.",
                style: GoogleFonts.poppins(fontSize: 18),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF6082B6),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(showRegisterPage: () {}),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://media.tenor.com/_EvegJwzPa0AAAAi/hourglass-kids-choice-awards.gif',
                  height: 300,
                ),
                const SizedBox(height: 20),
                Text(
                  'Your account is under review',
                  style: GoogleFonts.shareTech(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait for admin approval.\nYou will gain access once approved.',
                  style: GoogleFonts.bitter(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
