import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'package:threadhub_system/Customer/pages/menu.dart';

// import 'package:threadhub/customer/pages/settings.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black;
    final fontSize = context.watch<FontProvider>().fontSize;
    return Scaffold(
      backgroundColor: Color(0xffd9d9d9d9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6082B6),
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Threadhub',
            style: TextStyle(
              fontFamily: 'JainiPurva',
              fontSize: 28,
              color: textColor,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome to Threadhub',
                style: TextStyle(
                  fontFamily: 'JainiPurva',
                  fontSize: 28,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Your perfect fit starts here, book your tailor. Customize your style and track your orders with ease. Let\'s stitch your vision into reality.',
                  style: GoogleFonts.kottaOne(fontSize: 15, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'assets/img/sew.png',
                width: 347,
                height: 336,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 50),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Color(0xFFD9D9D9)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        Icon(Icons.phone, color: Colors.black),
                        const SizedBox(width: 10),
                        Icon(Icons.facebook, color: Colors.black),
                        const SizedBox(width: 10),
                        Icon(Icons.email_outlined, color: Colors.black),
                        const SizedBox(width: 10),
                        Icon(Icons.location_city, color: Colors.black),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Text(
                      "CONTACT US",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Main, Tiniguiban Heights",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    Text(
                      "Palawan State University",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    Text(
                      "Puerto Princesa City",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    Text(
                      "Palawan 5300",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "PHONE NUMBER",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: fontSize,
                      ),
                    ),
                    Text(
                      "(123) 4567890",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "EMAIL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: fontSize,
                      ),
                    ),
                    Text(
                      "developer1_threadhub@gmail.com",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    Text(
                      "developer2_threadhub@gmail.com",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    Text(
                      "developer3_threadhub@gmail.com",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                    Text(
                      "developer4_threadhub@gmail.com",
                      style: TextStyle(color: textColor, fontSize: fontSize),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: const Menu(),
    );
  }
}
