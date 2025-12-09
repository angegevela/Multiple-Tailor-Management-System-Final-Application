import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Pages/login_page.dart';
import 'package:threadhub_system/Tailor/pages/tailorhomepage.dart';
import 'package:threadhub_system/Tailor/signup/terms&conditions.dart';
import 'package:threadhub_system/Tailor/signup/upload_media.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class TailorSignUpPage extends StatefulWidget {
  final String role;
  final bool acceptedTerms;

  const TailorSignUpPage({
    super.key,
    required this.role,
    this.acceptedTerms = false,
  });

  @override
  State<TailorSignUpPage> createState() => _TailorSignUpPageState();
}

class _TailorSignUpPageState extends State<TailorSignUpPage> {
  // Boolean for Permit Uploading
  bool _businessPermitError = false;
  List<UploadFile>? _businessPermitFiles;

  // Error States of textfields
  bool _shopNamer = false;
  bool _username = false;
  bool _ownerName = false;
  bool _businessNumber = false;
  bool _address = false;
  bool _password = false;
  bool _confirmPass = false;

  // Input TextFields
  final bool _validate = false;
  final TextEditingController _shopnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _businessNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _numberEmployeesController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController =
      TextEditingController();

  // Remember Me
  bool _rememberMe = false;
  @override
  void initState() {
    super.initState();
    _rememberMe = widget.acceptedTerms;
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signUp() async {
    setState(() {
      _shopNamer = _shopnameController.text.trim().isEmpty;
      _username = _usernameController.text.trim().isEmpty;
      _ownerName = _ownerNameController.text.trim().isEmpty;
      _businessNumber = _businessNumberController.text.trim().isEmpty;
      _address = _addressController.text.trim().isEmpty;
      _password = _passwordController.text.trim().isEmpty;
      _confirmPass = _confirmpasswordController.text.trim().isEmpty;
    });

    if (_shopNamer ||
        _username ||
        _ownerName ||
        _businessNumber ||
        _address ||
        _password ||
        _confirmPass) {
      return;
    }

    if (!_rememberMe) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Terms & Conditions'),
          content: Text(
            'You must agree to the terms and conditions to continue.',
          ),
        ),
      );
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Weak Password'),
          content: Text('Password must be at least 6 characters long.'),
        ),
      );
      return;
    }

    if (_passwordController.text.trim() !=
        _confirmpasswordController.text.trim()) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Error'),
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Email Required'),
          content: Text('Please provide an email to sign up securely.'),
        ),
      );
      return;
    }

    try {
      final email = _emailController.text.trim();

      final emailQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Email Error'),
            content: Text('This email is already registered.'),
          ),
        );
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text.trim(),
          );

      if (!mounted) return;

      final user = userCredential.user;
      if (user == null) return;

      final supabase = Supabase.instance.client;
      final permitUrls = <String>[];

      if (_businessPermitFiles != null && _businessPermitFiles!.isNotEmpty) {
        final storage = supabase.storage.from('Tailor');
        final existingFiles = await storage.list(path: 'Permits');

        if (!mounted) return;

        for (final file in _businessPermitFiles!) {
          final filePath = file.file.path;
          if (filePath == null) continue;
          final fileName = filePath.split('/').last;

          if (existingFiles.any((f) => f.name == fileName)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File "$fileName" already exists. It will be renamed.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }

          final uniqueFileName =
              '${DateTime.now().millisecondsSinceEpoch}_$fileName';
          final path = 'Permits/$uniqueFileName';

          try {
            await storage.upload(path, File(filePath));
            final publicUrl = storage.getPublicUrl(path);
            permitUrls.add(publicUrl);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload "$fileName": $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      final fullAddress =
          '${_addressController.text.trim()}, Puerto Princesa City, 5300, Philippines';
      GeoPoint? geoPoint;
      try {
        final locations = await locationFromAddress(fullAddress);
        if (locations.isNotEmpty) {
          geoPoint = GeoPoint(
            locations.first.latitude,
            locations.first.longitude,
          );
        }
      } catch (_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Invalid Address'),
            content: Text(
              'We couldn’t find this location. Please include street and barangay.',
            ),
          ),
        );
      }

      final userData = {
        'role': 'Tailor',
        'shopName': _shopnameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'ownerName': _ownerNameController.text.trim(),
        'businessNumber': int.parse(_businessNumberController.text.trim()),
        'email': email,
        'address': _addressController.text.trim(),
        'fullAddress': fullAddress,
        'businessPermits': permitUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'passwordHash': hashPassword(_passwordController.text.trim()),
      };

      if (geoPoint != null) userData['location'] = geoPoint;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .set(userData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile was created successfully.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TailorHomePage(showAccepted: true),
        ),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                const SizedBox(height: 15),
                Text(
                  'Sign Up Successful',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome to ThreadHub',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Okay',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        default:
          message = e.message ?? 'An unknown error occurred.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Up Error'),
          content: Text(message),
        ),
      );
    }
  }

  @override
  void dispose() {
    _shopnameController.dispose();
    _usernameController.dispose();
    _ownerNameController.dispose();
    _businessNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _numberEmployeesController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: Text(
          'Create Account Now!',
          style: GoogleFonts.jockeyOne(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFF6082B6),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Shop Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Shop Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _shopnameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFE1EBEE),
                        labelText: 'Enter your shop name',
                        errorText: _shopNamer ? 'Shop name is required' : null,
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
                  ],
                ),
              ),

              // Username
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Color(0xFFE1EBEE),
                        labelText: 'Enter your desired username',
                        errorText: _username ? 'Username is required' : null,
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
                  ],
                ),
              ),

              // Owner Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Owner Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _ownerNameController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Color(0xFFE1EBEE),
                        labelText: 'Enter the Owners Name',
                        errorText: _ownerName
                            ? 'Owner\'s name is required'
                            : null,
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
                  ],
                ),
              ),

              // Business Number
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Business Phone Number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _businessNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Color(0xFFE1EBEE),
                        labelText: 'eg. +63 9123456789',
                        prefixText: '+63 ',
                        errorText: _businessNumber
                            ? 'Business number is required'
                            : null,
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
                  ],
                ),
              ),

              // Email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Color(0xFFE1EBEE),
                        labelText: 'email@example.com',
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
                  ],
                ),
              ),

              // Address
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      maxLines: 4,
                      textAlign: TextAlign.left,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFE1EBEE),
                        labelText: 'Enter your business address',
                        errorText: _address ? 'Address is required' : null,
                        alignLabelWithHint: true,
                        contentPadding: EdgeInsets.all(18),
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

              // Business Permit - photo media upload
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Business Permit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final uploadedFiles = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UploadMediaPage(
                              initialFiles: _businessPermitFiles,
                            ),
                          ),
                        );

                        if (uploadedFiles != null) {
                          setState(() {
                            _businessPermitFiles = uploadedFiles;
                            _businessPermitError = false;
                          });
                        }
                      },

                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1EBEE),
                          border: Border.all(
                            color: _businessPermitError
                                ? Colors.red
                                : Colors.black,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _businessPermitFiles != null &&
                                  _businessPermitFiles!.isNotEmpty
                              ? "${_businessPermitFiles?.length} file(s) uploaded"
                              : "Click To Upload Media",
                          style: TextStyle(
                            fontSize: 16,
                            color: _businessPermitError
                                ? Colors.red
                                : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              // Password
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Password',
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
                          labelText: 'Create password',
                          errorText: _password
                              ? 'Creating a password is required'
                              : null,
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

              SizedBox(height: 15),
              //Confirm Password
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
                          errorText: _confirmPass
                              ? 'Confirm Password is required'
                              : null,
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

              // Terms & Conditions Checkbox
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
                          final accepted = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TermsAndConditionsPage(),
                            ),
                          );
                          if (accepted == true) {
                            if (mounted) {
                              setState(() {
                                _rememberMe = true;
                              });
                            }
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

              SizedBox(height: 20),

              // Sign Up Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: GestureDetector(
                  onTap: () async {
                    await signUp();
                    setState(() {});
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

              SizedBox(height: 10),

              // Redirect to Login Screen
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

              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
