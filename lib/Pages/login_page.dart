import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:threadhub_system/Customer/signup/customer_homepage.dart';
import 'package:threadhub_system/Customer/signup/welcoming_signup.dart';
import 'package:threadhub_system/Pages/approval_screen(signup).dart';
import 'package:threadhub_system/Pages/forgot_pw_page1.dart';
import 'package:threadhub_system/Pages/forgot_pw_page2.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_availabilitysettings.dart';
import 'package:threadhub_system/Tailor/pages/tailorhomepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;
  const LoginPage({super.key, required this.showRegisterPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  //Remember Me
  bool _rememberMe = false;

  void signUserIn() async {
    String identifier = emailController.text.trim();
    String password = passwordController.text.trim();

    // Prevent empty input BEFORE Firebase
    if (identifier.isEmpty || password.isEmpty) {
      NoInput();
      return;
    }

    // Show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String email = identifier;

      // Checking if user typed username instead of email
      if (!identifier.contains('@')) {
        final snapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          Navigator.pop(context);
          wrongEmailMessage();
          return;
        }

        email = snapshot.docs.first['email'];
      }

      // Attempt login with resolved email if the username is not possible
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Fetching from  user document in firebase
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        Navigator.pop(context);
        wrongEmailMessage();
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;

      // Reading the role
      String role = data['role'] ?? '';
      String status = data['accountStatus'] ?? 'pending';

      Navigator.pop(context);

      if (status == 'pending') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ApprovalPendingScreen(userId: uid)),
        );
        return;
      }

      if (status == 'rejected') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text(
                  "Your account was rejected through this application.",
                  style: GoogleFonts.oswald(),
                ),
              ),
            ),
          ),
        );
      }

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', emailController.text.trim());
        await prefs.setString('saved_password', passwordController.text.trim());
      }
      // New Customer Flow
      if (role == 'Customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomePage()),
        );
      }
      // New Tailor Flow
      else if (role == 'Tailor') {
        bool isApproved = data['approved'] ?? false;

        Map availability = data['availability'] ?? {};
        List days = availability['days'] ?? [];

        bool hasAvailabilityFlag = data['hasAvailability'] ?? false;
        bool hasAvailability = hasAvailabilityFlag && days.isNotEmpty;

        // This navigation will navigate to the approcal pending screen if the user is not yet approved by administrator
        if (!isApproved) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ApprovalPendingScreen(userId: uid),
            ),
          );
        }
        // Elif condition if the approved tailor are directed to the availability setting to avoid confusion
        else if (!hasAvailability) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const TailorAvailabilitySettings(),
            ),
          );
        }
        // This will ready the application and direct to the tailorhomepage if availibility are set up
        else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TailorHomePage(showAccepted: true),
            ),
          );
        }
      }
      // the system will notify the user if their is an error within their role or if they're arent sign up yet
      else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.blueGrey[100],
            title: Text(
              "Role Error",
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "User role is not recognized.",
              style: GoogleFonts.songMyung(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Okay",
                  style: GoogleFonts.songMyung(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      if (e.code == 'user-not-found') {
        wrongEmailMessage();
      } else if (e.code == 'wrong-password') {
        wrongPasswordMessage();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.blueGrey[100],
            title: Text(
              'Login Failed',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
            ),
            content: Text(
              e.message ?? 'An error occurred.',
              style: GoogleFonts.songMyung(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Okay", style: GoogleFonts.songMyung(fontSize: 16)),
              ),
            ],
          ),
        );
      }
    }
  }

  void NoInput() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[100],
          title: Text(
            'You havent input anything yet',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Confirm',
                style: GoogleFonts.songMyung(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void wrongEmailMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[100],
          title: Text(
            'Incorrect Email',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Confirm',
                style: GoogleFonts.songMyung(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void wrongPasswordMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[100],
          title: Text(
            'Incorrect Password',
            style: GoogleFonts.songMyung(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Confirm',
                style: GoogleFonts.songMyung(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';

    if (savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
    }

    if (savedPassword.isNotEmpty) {
      passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  //password hide, password visibility
  bool passwordVisible = false;

  @override
  void initState() {
    super.initState();
    passwordVisible = false;
    loadSavedLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome Back',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 40,
          backgroundColor: const Color(0xFF6082B6),
          title: Text(
            'Welcome Back!',
            style: GoogleFonts.inknutAntiqua(fontSize: 18, color: Colors.black),
          ),
        ),
        backgroundColor: Color(0xFFD9D9D9),
        body: SafeArea(
          child: SingleChildScrollView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'To continue, sign in or join us.',
                      style: GoogleFonts.labrada(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Email TextField
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'info@example.com',
                      labelText: 'Username/Email',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelStyle: GoogleFonts.abhayaLibre(
                        fontSize: 25,
                        backgroundColor: const Color(0xFF4A789E),
                        color: Colors.black,
                      ),
                      contentPadding: EdgeInsets.fromLTRB(18, 22, 44, 22),

                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password TextField
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 1.0),
                    child: TextField(
                      controller: passwordController,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Password',
                        contentPadding: const EdgeInsets.fromLTRB(
                          18,
                          22,
                          44,
                          22,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                //Remember Me and Forgot Password
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: const Text(
                        'Remember Me',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ForgotPasswordPage();
                            },
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Sign In Button
                GestureDetector(
                  onTap: signUserIn,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A789E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Register Now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t Have An Account?',
                      style: GoogleFonts.chivo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      // onTap: widget.showRegisterPage,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpPage(role: ''),
                          ),
                        );
                      },
                      child: const Text(
                        'Register Now',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFFF9A825),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
