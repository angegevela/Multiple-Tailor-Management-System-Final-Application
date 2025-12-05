import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:threadhub_system/Pages/reset_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordverify extends StatefulWidget {
  const ForgotPasswordverify({super.key});

  @override
  State<ForgotPasswordverify> createState() => _ForgotPasswordStateverify();
}

class _ForgotPasswordStateverify extends State<ForgotPasswordverify> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();

  String _verificationId = "";
  bool _otpSent = false;
  String _otp = "";

  User? user;
  String verifiedPhone = "";
  String uid = "";

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    verifiedPhone = user?.phoneNumber ?? "";
    uid = user?.uid ?? "";
  }

 
  Future<bool> _phoneExists(String phone) async {
    final users = FirebaseFirestore.instance.collection('Users');

    var q1 = await users.where('phoneNumber', isEqualTo: phone).limit(1).get();
    if (q1.docs.isNotEmpty) return true;

    var q2 = await users
        .where('businessNumber', isEqualTo: phone)
        .limit(1)
        .get();
    if (q2.docs.isNotEmpty) return true;

    return false;
  }

  void _sendOTP() async {
    String phone = _phoneController.text.trim();

    if (!phone.startsWith('+')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Use country code. Example: +639XXXXXXXXX"),
        ),
      );
      return;
    }

    bool exists = await _phoneExists(phone);

    if (!exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user found with this phone number")),
      );
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (_) {},

      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}")),
        );
      },

      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;

        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("OTP Sent Successfully")));
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

 
  void _verifyOTP() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otp,
      );

      await _auth.signInWithCredential(credential);

      await _auth.signOut();

      _goToReset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP. Try again.")));
    }
  }

  void _goToReset() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResetPassword()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6082B6),
        title: Text(
          'Verify OTP',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                height: 200,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage("assets/img/OTP.png"),
                    fit: BoxFit.fitHeight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _otpSent ? "Enter OTP" : "Enter Phone Number",
                  style: GoogleFonts.chivo(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (!_otpSent)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    hintText: "+639XXXXXXXXX",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

              if (_otpSent)
                OtpTextField(
                  numberOfFields: 6,
                  showFieldAsBox: true,
                  onSubmit: (code) {
                    setState(() => _otp = code);
                    _verifyOTP();
                  },
                ),

              const SizedBox(height: 30),

              MaterialButton(
                onPressed: _otpSent ? _verifyOTP : _sendOTP,
                color: Colors.blueGrey,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _otpSent ? "Verify OTP" : "Send OTP",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
