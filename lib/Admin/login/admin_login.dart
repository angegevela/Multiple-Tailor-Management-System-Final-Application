import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Admin/login/tc_admin.dart';
import 'package:threadhub_system/Admin/pages/sidebar/appointment.dart';
import 'package:threadhub_system/Pages/forgot_pw_page1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = false;
  bool _agreeToTerms = false;

  void _signInAdmin(BuildContext context) async {
    final enteredId = idController.text.trim();
    final enteredEmail = emailController.text.trim();

    if (enteredId.isEmpty || enteredEmail.isEmpty) {
      _showError("Please enter Admin ID and Email.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('adminid', isEqualTo: enteredId)
          .where('email', isEqualTo: enteredEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showError("Invalid Admin credentials.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      if (rememberMe) {
        await prefs.setString('adminid', enteredId);
        await prefs.setString('adminemail', enteredEmail);
      } else {
        await prefs.remove('adminid');
        await prefs.remove('adminemail');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminAppointmentPage()),
      );
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  //Remember Me - Checklist
  final bool _rememberMe = false;

  // //Password hide - Icon/Transition
  // bool passwordVisible = false;

  // //Terms and Conditions - Checklist Logic
  // bool _agreeToTerms = false;

  Future<void> _loadRememberedAdmin() async {
    final prefs = await SharedPreferences.getInstance();

    final savedId = prefs.getString('adminid');
    final savedEmail = prefs.getString('adminemail');

    if (savedId != null && savedEmail != null) {
      idController.text = savedId;
      emailController.text = savedEmail;
      rememberMe = true;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedAdmin();
    // passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 72, 112, 172),
        elevation: 2,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: Stack(
        children: [
          Container(color: const Color(0xFF31507F)),
          Positioned.fill(
            child: Opacity(
              opacity: 1.0,
              child: Image.asset('assets/img/Group 63.png', fit: BoxFit.cover),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Please Fill In Your Unique Admin Details Below",
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black45,
                            ),
                          ),

                          const SizedBox(height: 40),

                          //Administration Identification - UI
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Administrator Identification",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: idController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 22,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(width: 1.5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black54,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          //Password
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Email",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[200],
                              // labelText: 'Password',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 22,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(width: 1.5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black54,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Text(
                                "Remember Me",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          // //Forgot Password
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.end,
                          //   children: [
                          //     const SizedBox(width: 45),
                          //     GestureDetector(
                          //       onTap: () {
                          //         Navigator.push(
                          //           context,
                          //           MaterialPageRoute(
                          //             builder: (context) {
                          //               return ForgotPasswordbutton();
                          //             },
                          //           ),
                          //         );
                          //       },
                          //       child: const Text(
                          //         'Forgot Password?',
                          //         style: TextStyle(
                          //           fontSize: 12,
                          //           color: Colors.black,
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 30),

                          //Sign In Button
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => _signInAdmin(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Checkbox with Terms and Conditions navigation
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final accepted = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminTermsCondition(),
                                      ),
                                    );

                                    if (accepted == true) {
                                      setState(() {
                                        _agreeToTerms = true;
                                      });
                                    }
                                  },
                                  child: Text(
                                    'I agree to the Terms and Conditions',
                                    style: GoogleFonts.chivo(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
