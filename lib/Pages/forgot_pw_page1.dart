import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Pages/forgot_pw_page2.dart';
import 'package:threadhub_system/Pages/forgot_pw_page3.dart';

class ForgotPasswordbutton extends StatefulWidget {
  const ForgotPasswordbutton({super.key});

  @override
  State<ForgotPasswordbutton> createState() => _ForgotPasswordStatebutton();
}

class _ForgotPasswordStatebutton extends State<ForgotPasswordbutton> {
  final TextEditingController emailController = TextEditingController();
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6082B6),
        title: Text(
          'Forgot Password',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text(
              'How do you want to receive the code to reset your password?',
              style: GoogleFonts.inter(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20),

            //Option 1 - Email
            RadioListTile<String>(
              title: Text(
                'Send a reset link to my email',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              value: 'email-option',
              groupValue: _selectedOption,
              activeColor: Colors.black,
              onChanged: (value) {
                setState(() => _selectedOption = value);
              },
            ),

            // // Option 2 - Phone
            // RadioListTile<String>(
            //   title: Text(
            //     'Send a reset code to my phone number',
            //     style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            //   ),
            //   value: 'phone-option',
            //   groupValue: _selectedOption,
            //   activeColor: Colors.black,
            //   onChanged: (value) {
            //     setState(() => _selectedOption = value);
            //   },
            // ),
            SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedOption == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select an option')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordPage(),
                    ),
                  );

                  // if (_selectedOption == 'email-option') {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) {
                  //         return ForgotPasswordPage();
                  //       }, // to email flow
                  //     ),
                  //   );
                  // } else if (_selectedOption == 'phone-option') {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => ForgotPasswordverify(),
                  //     ),
                  //   );
                  // }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  textStyle: GoogleFonts.podkova(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text('Pick'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
