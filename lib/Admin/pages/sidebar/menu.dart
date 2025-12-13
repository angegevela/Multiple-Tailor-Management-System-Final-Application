import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Admin/pages/sidebar/appointment.dart';
import 'package:threadhub_system/Admin/pages/sidebar/people.dart';
import 'package:threadhub_system/Admin/pages/sidebar/report_management.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:threadhub_system/Admin/login/admin_login.dart';
import 'package:threadhub_system/Admin/pages/sidebar/user_approval.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  // For hover tracking
  int hoveredIndex = -1;

  Widget menuItem({
    required IconData icon,
    required String label,
    required int index,
    required void Function() onTap,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: hoveredIndex == index
              ? const Color(0xFF19232F)
              : const Color(0xFF334257),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFD6E5FA),
      width: 254,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: Center(
              child: Text(
                'ADMIN',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          menuItem(
            icon: Icons.calendar_month,
            label: 'Appointments',
            index: 0,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminAppointmentPage()),
              );
            },
          ),

          menuItem(
            icon: Icons.person,
            label: 'People',
            index: 1,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersPage()),
              );
            },
          ),

          menuItem(
            icon: Icons.approval,
            label: 'User Approvals',
            index: 2,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminUserApprovalFrame(),
                ),
              );
            },
          ),

          menuItem(
            icon: Icons.report,
            label: 'Report Management',
            index: 2,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportManagementPage()),
              );
            },
          ),
          const Spacer(),
          menuItem(
            icon: Icons.logout_sharp,
            label: 'Logout',
            index: 3,
            onTap: () async {
              Navigator.pop(context);

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('isAdminLoggedIn');

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AdminLoginPage()),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
