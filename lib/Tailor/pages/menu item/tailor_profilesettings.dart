import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:threadhub_system/Pages/login_page.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_availabilitysettings.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_help.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_personalinfo.dart';

class TailorProfileSettingsPage extends StatefulWidget {
  const TailorProfileSettingsPage({super.key});

  @override
  State<TailorProfileSettingsPage> createState() =>
      _TailorProfileSettingsPageState();
}

class _TailorProfileSettingsPageState extends State<TailorProfileSettingsPage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final firebaseUser = FirebaseAuth.instance.currentUser;
  String? shopName;
  String? role;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserData();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (firebaseUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(firebaseUser!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final settings = data?['notificationSettings'] ?? {};
      setState(() {
        shopName = "${data?['shopName']}";
        role = data?['role'] ?? "No role";
        // Notification Push Buttons
        pushNotifications = settings['pushNotifications'] ?? true;
        reviewFeedbackAlerts = settings['reviewFeedbackAlerts'] ?? false;
        appointmentReminders = settings['appointmentReminders'] ?? false;
        customerMessages = settings['customerMessages'] ?? true;
      });
    }
  }

  void signUserOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginPage(showRegisterPage: () {}),
        ),
      );
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  bool darkModeEnabled = false;
  bool pushNotifications = true;
  bool reviewFeedbackAlerts = false;
  bool appointmentReminders = false;
  bool customerMessages = true;

  //Font sizes
  Map<String, double> fontMap = {
    'Small': 14.0,
    'Medium': 16.0,
    'Large': 18.0,
    'Extra Large': 20.0,
  };

  @override
  Widget build(BuildContext context) {
    final tailorfontSize = context.watch<TailorFontprovider>().fontSize;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // PROFILE IMAGE (no picker)
            CircleAvatar(
              radius: 90,
              backgroundColor: Colors.grey.shade300,
              child: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                  ? CircleAvatar(
                      radius: 88,
                      backgroundImage: NetworkImage(_profileImageUrl!),
                    )
                  : const CircleAvatar(
                      radius: 88,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
            ),

            const SizedBox(height: 20),
            Text(
              shopName ?? "Loading name...",
              style: GoogleFonts.moul(
                textStyle: TextStyle(
                  fontSize: tailorfontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              role ?? "Loading role...",
              style: GoogleFonts.montserratAlternates(
                textStyle: TextStyle(
                  fontSize: tailorfontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // PERSONAL INFORMATION BUTTON
            Container(
              width: 350,
              decoration: const BoxDecoration(color: Color(0xFF002244)),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TailorPersonalInformation(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 70,
                    vertical: 5,
                  ),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Personal Information',
                  style: GoogleFonts.prompt(
                    fontSize: tailorfontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 10),
                child: Text(
                  'Preferences',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w500,
                    fontSize: tailorfontSize,
                  ),
                ),
              ),
            ),

            // NOTIFICATIONS
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    'Notifications Settings',
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w500,
                      fontSize: tailorfontSize,
                    ),
                  ),
                  children: [
                    _buildSwitchTile('Push Notifications', pushNotifications, (
                      val,
                    ) {
                      _updateNotificationSetting('pushNotifications', val);
                    }),
                    _buildSwitchTile(
                      'Review and Feedback Alerts',
                      reviewFeedbackAlerts,
                      (val) {
                        _updateNotificationSetting('reviewFeedbackAlerts', val);
                      },
                    ),
                    _buildSwitchTile(
                      'Appointment Reminders',
                      appointmentReminders,
                      (val) {
                        _updateNotificationSetting('appointmentReminders', val);
                      },
                    ),
                    _buildSwitchTile('Customer Messages', customerMessages, (
                      val,
                    ) {
                      _updateNotificationSetting('customerMessages', val);
                    }),
                  ],
                ),
              ),
            ),

            // DARK MODE
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: _boxDecoration(),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  'Dark Mode',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w500,
                    fontSize: tailorfontSize,
                  ),
                ),
                value: darkModeEnabled,
                onChanged: (bool value) {
                  setState(() {
                    darkModeEnabled = value;
                  });
                },
              ),
            ),

            // HELP
            _buildListTile(
              title: 'Help',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TailorHelpPage()),
              ),
              trailing: _circleIcon(Icons.question_mark),
            ),

            // AVAILABILITY
            _buildListTile(
              title: 'Availability Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TailorAvailabilitySettings(),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward, size: 24),
            ),

            // FONT SIZE
            _buildFontSizeDropdown(context, tailorfontSize),

            // LOGOUT
            _buildListTile(
              title: 'Logout',
              onTap: () => signUserOut(context),
              trailing: const Icon(Icons.logout),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _updateNotificationSetting(String key, bool value) {
    setState(() {
      switch (key) {
        case 'pushNotifications':
          pushNotifications = value;
          break;
        case 'reviewFeedbackAlerts':
          reviewFeedbackAlerts = value;
          break;
        case 'appointmentReminders':
          appointmentReminders = value;
          break;
        case 'customerMessages':
          customerMessages = value;
          break;
      }
    });

    if (firebaseUser != null) {
      FirebaseFirestore.instance.collection("Users").doc(firebaseUser!.uid).set(
        {
          'notificationSettings': {
            'pushNotifications': pushNotifications,
            'reviewFeedbackAlerts': reviewFeedbackAlerts,
            'appointmentReminders': appointmentReminders,
            'customerMessages': customerMessages,
          },
        },
        SetOptions(merge: true),
      );
    }
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.prompt(fontWeight: FontWeight.w400),
      ),
      trailing: CupertinoSwitch(
        activeTrackColor: const Color(0xFF5B7DB1),
        inactiveTrackColor: Colors.grey.shade400,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: _boxDecoration(),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.prompt(fontWeight: FontWeight.w500),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildFontSizeDropdown(BuildContext context, double fontSize) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: _boxDecoration(),
      child: ListTile(
        title: Text(
          'Font Size',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w500),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: context.watch<TailorFontprovider>().chosenValue,
            style: GoogleFonts.montserratAlternates(
              textStyle: TextStyle(color: Colors.black87, fontSize: fontSize),
            ),
            dropdownColor: const Color(0xFFD9EAFD),
            icon: const Icon(Icons.arrow_downward, size: 24),
            items: fontMap.keys.map((String key) {
              return DropdownMenuItem<String>(value: key, child: Text(key));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              context.read<TailorFontprovider>().setFontSize(value);
            },
          ),
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade300,
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget _circleIcon(IconData icon) => Container(
    width: 25,
    height: 25,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black, width: 2),
    ),
    child: Icon(icon, size: 20, color: Colors.black),
  );
}
