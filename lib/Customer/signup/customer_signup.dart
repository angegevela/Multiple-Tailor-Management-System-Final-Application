import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Customer/signup/customer_homepage.dart';
import 'package:threadhub_system/Customer/signup/terms&condition_customer.dart';
import 'package:threadhub_system/Pages/login_page.dart';
import 'package:geocoding/geocoding.dart';

class SignupRegister extends StatefulWidget {
  final String role;
  final bool acceptedTerms;

  const SignupRegister({
    super.key,
    required this.role,
    this.acceptedTerms = false,
  });

  @override
  State<SignupRegister> createState() => _SignupRegisterState();
}

class _SignupRegisterState extends State<SignupRegister> {
  // Accept Terms and Conditions
  late bool _isChecked;
  @override
  void initState() {
    super.initState();
    _isChecked = widget.acceptedTerms;
  }

  // Text Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phonenumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    _firstnameController.dispose();
    _surnameController.dispose();
    _phonenumberController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Text Controllers - Signing Up with Empty Textfield Error
  bool _validateTextFields() {
    if (_firstnameController.text.trim().isEmpty ||
        _surnameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phonenumberController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmpasswordController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Missing Information. Required Field"),
          content: Text(" Please fill in all required fields."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Okay"),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Future signUp() async {
    // Check Empty Fields On This Signup
    if (selectedBarangay == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Missing Information"),
          content: Text("Please select your Barangay."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Okay"),
            ),
          ],
        ),
      );
      return false;
    }

    // Terms and Conditions
    if (!_rememberMe) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Terms & Conditions'),
          content: const Text(
            'You must agree to the terms and conditions to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Authenticate User
    if (passwordConfirmed()) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        // Add User Details
        await addUserDetails(
          _firstnameController.text.trim(),
          _surnameController.text.trim(),
          _emailController.text.trim(),
          int.parse(_phonenumberController.text.trim()),
          widget.role,
          _addressController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomePage()),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Registration Error"),
            content: Text(e.message ?? "Something went wrong."),
            actions: [
              TextButton(
                child: const Text("Okay"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Passwords do not match.'),
          actions: [
            TextButton(
              child: const Text("Okay"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future addUserDetails(
    String firstName,
    String surname,
    String email,
    int phoneNumber,
    String role,
    String address,
    String username,
    String password,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String baseCity = "Puerto Princesa City, 5300, Philippines";
      String fullAddress =
          "$address, $selectedBarangay, Puerto Princesa City, 5300, Philippines";

      GeoPoint? geoPoint;

      try {
        List<Location> locations = await locationFromAddress(fullAddress);
        if (locations.isNotEmpty) {
          geoPoint = GeoPoint(
            locations.first.latitude,
            locations.first.longitude,
          );
        }
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Invalid Address"),
            content: const Text(
              "We couldn't find this location. Please include street and barangay in your address.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Okay'),
              ),
            ],
          ),
        );
      }

      // Hash password before storing
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      final Map<String, dynamic> userData = {
        'firstName': firstName,
        'surname': surname,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role,
        'address': address,
        'userBarangay': selectedBarangay,

        'fullAddress': fullAddress,
        'username': username,
        'passwordHash': hashedPassword,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (geoPoint != null) {
        userData['location'] = geoPoint;
      }

      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .set(userData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Firestore Error"),
            content: const Text(
              "There was an error saving your account. Please try again.",
            ),
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

  // Confirmed Password
  bool passwordConfirmed() {
    return _passwordController.text.trim() ==
        _confirmpasswordController.text.trim();
  }

  // Remember Me Checkbox - I Agree With Terms and Conditions
  bool _rememberMe = false;

  // List Of Barangays here in Puerto Pricesa City
  final List<String> ppcBarangays = [
    "Babuyan",
    "Bagong Bayan",
    "Bagong Pag-Asa",
    "Bagong Silang",
    "Bahile",
    "Bahile",
    "Bancao-Bancao",
    "Barangay ng mga Mangingisda",
    "Binduyan",
    "Buenavista",
    "Cabayugan",
    "Concepcion",
    "Inagawan",
    "Inagawan Sub-Colony",
    "Irawan",
    "Iwahig",
    "Kalipay",
    "Kamuning",
    "Langogan",
    "Liwanag",
    "Lucbuan",
    "Luzviminda",
    "Mabuhay",
    "Macarascas",
    "Magkakaibigan",
    "Maligaya",
    "Manalo",
    "Mandaragat",
    "Manggahan",
    "Maningning",
    "Maoyon",
    "Marufinas",
    "Maruyogon",
    "Masigla",
    "Masikap",
    "Masipag",
    "Matahimik",
    "Matiyaga",
    "Maunland",
    "Milagrosa",
    "Model",
    "Montible",
    "Napsan",
    "New Panggangan",
    "Pagkakaisa",
    "Princesa",
    "Salvacion",
    "San Jose",
    "San Manuel",
    "San Miguel",
    "San Pedro",
    "San Rafael",
    "Santa Cruz",
    "Santa Lourdes",
    "Santa Lucia",
    "Santa Monica",
    "Seaside",
    "Sicsican",
    "Simpocan",
    "Tagabinit",
    "Tagburos",
    "Tagumpay",
    "Tanabag",
    "Tanglaw",
    "Tiniguiban",
  ];

  // Selected Barangay
  String? selectedBarangay;
  @override
  Widget build(BuildContext context) {
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
                  fontWeight: FontWeight.w400,
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
                // First Name Textfield
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
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          controller: _firstnameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: const Color(0xFFE1EBEE),
                            labelText: 'Enter your first name',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Surname Textfield
                SizedBox(height: 5),
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
                          controller: _surnameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: const Color(0xFFE1EBEE),
                            labelText: 'Enter your surname',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //Username Textfield
                SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: const Color(0xFFE1EBEE),
                            labelText: 'Enter your desired username',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //Email Textfield
                SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: const Color(0xFFE1EBEE),
                            labelText: 'example@email.com',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //Phone Number Textfield
                SizedBox(height: 5),
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
                          controller: _phonenumberController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: const Color(0xFFE1EBEE),
                            labelText: 'e.g. 09012345678',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //Address Section
                SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barangay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // BARANGAY DROPDOWN
                      DropdownButtonFormField<String>(
                        value: selectedBarangay,
                        items: ppcBarangays.map((barangay) {
                          return DropdownMenuItem(
                            value: barangay,
                            child: Text(barangay),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBarangay = value;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFE1EBEE),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          labelText: "Select Barangay",
                        ),
                      ),

                      SizedBox(height: 12),

                      // STREET / HOUSE ADDRESS
                      Text(
                        'Street / Block / House No.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFE1EBEE),
                          labelText: 'Example: Purok 1, BLK 2, Lot 7',
                          alignLabelWithHint: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                //Create Password Textfield
                SizedBox(height: 5),
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
                          controller: _passwordController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: const Color(0xFFE1EBEE),
                            labelText: 'Create a password',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 44, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //Confirm Password Textfield
                SizedBox(height: 5),
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
                          controller: _confirmpasswordController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: const Color(0xFFE1EBEE),
                            labelText: 'Re-enter password',
                            contentPadding: EdgeInsets.fromLTRB(18, 22, 44, 2),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkbox with Terms and Conditions navigation
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final accepted = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CustTermsAndConditionsPage(),
                              ),
                            );

                            // If user accepted terms, check the box automatically
                            if (accepted == true) {
                              setState(() {
                                _rememberMe = true;
                              });
                            }
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
                      ),
                    ],
                  ),
                ),

                //Sign in Button Textfield
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: GestureDetector(
                    onTap: () async {
                      await signUp();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A789E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.chakraPetch(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                //Redirect to Login Screen
                Padding(
                  padding: const EdgeInsets.fromLTRB(15.0, 0, 15.0, 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LoginPage(showRegisterPage: () {}),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF335E7A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Have an Account? Sign In',
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
