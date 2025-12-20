import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future signUp() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool rememberMe = false;
    return MaterialApp(
      title: 'Create Account',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 50,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Create Account Now!',
                style: GoogleFonts.jockeyOne(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          backgroundColor: const Color(0xFF6082B6),
        ),
        backgroundColor: Color(0xFFEEEEEE),
        body: SafeArea(
          child: SingleChildScrollView(
            reverse: true,
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'First Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Enter your first name',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),

                // Surname TextField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surname',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Enter your surname',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //Email TextField
                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email(Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'example@email.com',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),

                //Phone Number
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'e.g. 09012345678',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),

                // Create Password Textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Create a password',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 44, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),
                //Confirm Password Textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Re-enter password',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 44, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),
                //Check Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rememberMe = !rememberMe;
                          });
                        },
                        child: Text(
                          'I agree to the Terms and Conditions',
                          style: GoogleFonts.chivo(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
                //Sign in Button
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 15.0,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(05),
                    decoration: BoxDecoration(
                      color: Color(0xFF4A789E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Sign in',
                        style: GoogleFonts.chakraPetch(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 15.0,
                    end: 15.0,
                    bottom: 20.0,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(05),
                    decoration: BoxDecoration(
                      color: Color(0xFF335E7A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: widget.showLoginPage,
                        child: Text(
                          'Have Account? Sign In',
                          style: GoogleFonts.chakraPetch(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
