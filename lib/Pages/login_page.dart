import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:threadhub_system/Customer/signup/customer_homepage.dart';
import 'package:threadhub_system/Customer/signup/welcoming_signup.dart';
import 'package:threadhub_system/Pages/forgot_pw_page1.dart';
import 'package:threadhub_system/Tailor/pages/tailorhomepage.dart';

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

  //Sign-in User
  void signUserIn() async {
    //Show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String identifier = emailController.text.trim();
      String password = passwordController.text.trim();
      String email = identifier;

      //Check if user typed username instead of email
      if (!identifier.contains('@')) {
        final snapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text("Login Error"),
              content: Text("No account found with that username."),
            ),
          );
          return;
        }

        // Extract email from Firestore
        email = snapshot.docs.first['email'];

        // If email is blank (optional), reconstruct fallback email
        if (email.isEmpty) {
          email = '${identifier.toLowerCase()}@example.com';
        }
      }

      // attempt login with resolved email
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      //Fetch user document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text("Login Error"),
            content: Text("User record not found in the database."),
          ),
        );
        return;
      }

      //Read role
      String role = userDoc['role'];

      Navigator.pop(context);

      if (role == 'Customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomePage()),
        );
      } else if (role == 'Tailor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TailorHomePage(showAccepted: true),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Role Error"),
            content: const Text("User role is not recognized."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Okay"),
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
            title: const Text('Login Failed'),
            content: Text(e.message ?? 'An error occurred.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Okay"),
              ),
            ],
          ),
        );
      }
    }
  }

  void wrongEmailMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(title: Text('Incorrect Email'));
      },
    );
  }

  void wrongPasswordMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(title: Text('Incorrect Password'));
      },
    );
  }

  //password hide
  bool passwordVisible = false;
  //password visibility
  @override
  void initState() {
    super.initState();
    passwordVisible = false;
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
                              return ForgotPasswordbutton();
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
