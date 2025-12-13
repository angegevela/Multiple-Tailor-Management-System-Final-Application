import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:threadhub_system/Customer/signup/customer_homepage.dart';
import 'package:threadhub_system/Pages/approval_screen(signup).dart';
import 'package:threadhub_system/Pages/login_page.dart';
import 'package:threadhub_system/Tailor/pages/tailorhomepage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoginPage(showRegisterPage: () {});
        }

        final uid = snapshot.data!.uid;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;

            final role = data['role'];
            final approved = data['approved'] ?? false;

            if (!approved) {
              return const ApprovalPendingScreen();
            }

            // Approved users
            if (role == 'customer') {
              return const CustomerHomePage();
              // } else if (role == 'tailor') {
              //   return const TailorHomePage(showAccepted: null,);
              // } else if (role == 'admin') {
              //   return const AdminDashboard();
            }

            return const Scaffold(body: Center(child: Text('Invalid role')));
          },
        );
      },
    );
  }
}
