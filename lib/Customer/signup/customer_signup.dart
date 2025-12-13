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
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.acceptedTerms;
  }

  // Controllers
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

  // Barangay Overlay
  final LayerLink _barangayLayerLink = LayerLink();
  final GlobalKey _barangayKey = GlobalKey();
  OverlayEntry? _barangayOverlayEntry;
  bool _isBarangayDropdownOpen = false;

  String? selectedBarangay;

  // List of Puerto Princesa City Barangays
  final List<String> ppcBarangays = [
    "Babuyan",
    "Bagong Bayan",
    "Bagong Pag-Asa",
    "Bagong Silang",
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

  void _toggleBarangayDropdown() {
    if (_isBarangayDropdownOpen) {
      _barangayOverlayEntry?.remove();
    } else {
      _barangayOverlayEntry = _createBarangayOverlay();
      Overlay.of(context)?.insert(_barangayOverlayEntry!);
    }
    setState(() {
      _isBarangayDropdownOpen = !_isBarangayDropdownOpen;
    });
  }

  OverlayEntry _createBarangayOverlay() {
    RenderBox renderBox =
        _barangayKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayHeight = (ppcBarangays.length * 56.0) > screenHeight * 0.5
        ? screenHeight * 0.5
        : ppcBarangays.length * 56.0;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: BoxConstraints(maxHeight: overlayHeight),
            decoration: BoxDecoration(
              color: const Color(0xFF3B5998),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ppcBarangays.map((barangay) {
                  return ListTile(
                    title: Text(
                      barangay,
                      style: GoogleFonts.daiBannaSil(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedBarangay = barangay;
                        _barangayOverlayEntry?.remove();
                        _isBarangayDropdownOpen = false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Terms and Conditions Checkbox
  bool _rememberMe = false;

  // Password confirmation
  bool passwordConfirmed() =>
      _passwordController.text.trim() == _confirmpasswordController.text.trim();

  // Sign Up method (simplified for brevity)
  Future signUp() async {
    if (selectedBarangay == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Missing Information"),
          content: const Text("Please select your Barangay."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Okay"),
            ),
          ],
        ),
      );
      return;
    }
    if (!_rememberMe) {
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
    if (passwordConfirmed()) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String fullAddress =
              "${_addressController.text.trim()}, $selectedBarangay, Puerto Princesa City, 5300, Philippines";

          GeoPoint? geoPoint;
          try {
            List<Location> locations = await locationFromAddress(fullAddress);
            if (locations.isNotEmpty) {
              geoPoint = GeoPoint(
                locations.first.latitude,
                locations.first.longitude,
              );
            }
          } catch (_) {}

          final hashedPassword = sha256
              .convert(utf8.encode(_passwordController.text))
              .toString();

          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .set({
                'firstName': _firstnameController.text.trim(),
                'surname': _surnameController.text.trim(),
                'email': _emailController.text.trim(),
                'phoneNumber':
                    int.tryParse(_phonenumberController.text.trim()) ?? 0,
                'role': widget.role,
                'address': _addressController.text.trim(),
                'userBarangay': selectedBarangay,
                'fullAddress': fullAddress,
                'username': _usernameController.text.trim(),
                'passwordHash': hashedPassword,
                if (geoPoint != null) 'location': geoPoint,
                'approved': false,
                'accountStatus':'pending',
                'createdAt': FieldValue.serverTimestamp(),
              });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

        }
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Account',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
        backgroundColor: const Color(0xFFEEEEEE),
        body: SafeArea(
          child: SingleChildScrollView(
            reverse: true,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First Name
                  Text(
                    'First Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _firstnameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: const Color(0xFFE1EBEE),
                      labelText: 'Enter your first name',
                      contentPadding: const EdgeInsets.fromLTRB(18, 22, 48, 2),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Surname
                  Text(
                    'Surname',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: const Color(0xFFE1EBEE),
                      labelText: 'Enter your surname',
                      contentPadding: const EdgeInsets.fromLTRB(18, 22, 48, 2),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Username
                  Text(
                    'Username',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: const Color(0xFFE1EBEE),
                      labelText: 'Enter your desired username',
                      contentPadding: const EdgeInsets.fromLTRB(18, 22, 48, 2),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Barangay Dropdown
                  Text(
                    'Barangay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    key: _barangayKey,
                    onTap: _toggleBarangayDropdown,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1EBEE),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedBarangay ?? "Select Barangay",
                            style: GoogleFonts.palanquin(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 28,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Street/House No.
                  Text(
                    'Street / Block / House No.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFE1EBEE),
                      labelText: 'Purok 1, BLK 2, Lot 7',
                      alignLabelWithHint: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  Text(
                    'Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: const Color(0xFFE1EBEE),
                      labelText: 'Create a password',
                      contentPadding: const EdgeInsets.fromLTRB(18, 22, 44, 2),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm Password
                  Text(
                    'Confirm Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmpasswordController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: const Color(0xFFE1EBEE),
                      labelText: 'Re-enter password',
                      contentPadding: const EdgeInsets.fromLTRB(18, 22, 44, 2),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),

                  // Terms & Conditions
                  const SizedBox(height: 12),
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
                            if (accepted == true) {
                              setState(() => _rememberMe = true);
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

                  // Sign Up Button
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: signUp,
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

                  // Redirect to Login
                  const SizedBox(height: 10),
                  GestureDetector(
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
