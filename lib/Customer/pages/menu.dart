import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:threadhub_system/Customer/pages/Notification/customer_notification.dart';
import 'package:threadhub_system/Customer/pages/appointment_form.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'package:threadhub_system/Customer/pages/product%20status/product_status.dart';
import 'package:threadhub_system/Customer/pages/settings.dart';
import 'package:threadhub_system/Customer/signup/customer_homepage.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;
    return Drawer(
      backgroundColor: Color(0xFFD6E5FA),
      width: 254,
      child: ListView(
        children: [
          SizedBox(
            height: 50,
            child: Center(
              child: Text(
                'ThreadHub',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          //Dashboard Menu Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFF334257),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white),
              title: Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        CustomerHomePage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
            ),
          ),

          //Customer Profile Menu Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFF334257),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(Icons.person_2, color: Colors.white),
              title: Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerSettings()),
                );
              },
            ),
          ),

          //Product Status
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFF334257),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.production_quantity_limits,
                color: Colors.white,
              ),
              title: Text(
                'Product Status',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductStatusPage(customerId: ''),
                  ),
                );
              },
            ),
          ),

          //Appointment Booking Form
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFF334257),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.white),
              title: Text(
                'Appointment Form',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentFormPage(
                      customerId: FirebaseAuth.instance.currentUser!.uid,
                      usedMeasurementId: null,
                      measurements: const {},
                      measurementType: '',
                    ),
                  ),
                );
              },
            ),
          ),

          // Container(
          //   margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          //   decoration: BoxDecoration(
          //     color: Color(0xFF334257),
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          //   child: ListTile(
          //     leading: const Icon(Icons.edit_outlined, color: Colors.white),
          //     title: Text(
          //       'Review',
          //       style: GoogleFonts.poppins(
          //         fontSize: fontSize,
          //         fontWeight: FontWeight.w400,
          //         color: Colors.white,
          //       ),
          //     ),
          //     onTap: () {
          //       Navigator.pop(context);
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => RatingandReviewPage(),
          //         ),
          //       );
          //     },
          //   ),
          // ),

          //Notification Menu Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFF334257),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              title: Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              // onTap: () {
              //   Navigator.pop(context);
              //   // Navigator.push(
              //   //   context,
              //   //   MaterialPageRoute(
              //   //     builder: (context) => CustomerNotification(appointmentData: {}, tailor: {}, customerId: '',),
              //   //   ),
              //   // );
              //   // Navigate only after the notification is saved

              // },
              onTap: () {
                Navigator.pop(context);

                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerNotification(customerId: currentUser.uid),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
