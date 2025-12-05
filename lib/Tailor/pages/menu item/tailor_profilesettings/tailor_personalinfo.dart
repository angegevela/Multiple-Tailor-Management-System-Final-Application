import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_portfoliopage.dart';

class TailorPersonalInformation extends StatefulWidget {
  const TailorPersonalInformation({super.key});

  @override
  State<TailorPersonalInformation> createState() =>
      _TailorPersonalInformationState();
}

class _TailorPersonalInformationState extends State<TailorPersonalInformation> {
  String? _profileImageUrl;
  File? _imageFile;

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _ownerNameController.text = data['ownerName'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _phoneController.text = data['businessNumber']?.toString() ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _addressController.text = data['address'] ?? '';
          _shopNameController.text = data['shopName'] ?? '';
          _profileImageUrl = data['profileImageUrl'] ?? '';
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Load error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() => _imageFile = file);

    final user = FirebaseAuth.instance.currentUser!;
    final ext = file.path.split('.').last;
    final path = 'pictures/${user.uid}.$ext';

    try {
      final bytes = await file.readAsBytes();

      await Supabase.instance.client.storage
          .from('profile_pictures')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = Supabase.instance.client.storage
          .from('profile_pictures')
          .getPublicUrl(path);
      final cacheBustedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update(
        {'profileImageUrl': cacheBustedUrl},
      );

      setState(() => _profileImageUrl = cacheBustedUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated successfully!")),
      );
    } catch (e) {
      debugPrint('Upload error: $e');
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .update({
            'username': _usernameController.text.trim(),
            'businessNumber': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'profileImageUrl': _profileImageUrl ?? '',
          });

      setState(() => _isLoading = false);

      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Saved"),
          content: const Text("Your changes have been saved successfully."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Save error: $e");
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error saving changes. Please try again."),
        ),
      );
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    String? hint,
    int maxLines = 1,
    required double tailorfontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: tailorfontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint ?? label,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Colors.black, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tailorfontSize = context.watch<TailorFontprovider>().fontSize;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 90,
                    backgroundColor: Colors.black,
                    child: _imageFile != null
                        ? CircleAvatar(
                            radius: 88,
                            backgroundImage: FileImage(_imageFile!),
                          )
                        : (_profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty)
                        ? CircleAvatar(
                            radius: 88,
                            backgroundImage: NetworkImage(_profileImageUrl!),
                          )
                        : const CircleAvatar(
                            radius: 88,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.blueGrey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 25,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'Owner Name',
              controller: _ownerNameController,
              tailorfontSize: tailorfontSize,
            ),
            _buildInputField(
              label: 'Username',
              controller: _usernameController,
              tailorfontSize: tailorfontSize,
            ),
            _buildInputField(
              label: 'Business Number',
              controller: _phoneController,
              tailorfontSize: tailorfontSize,
            ),
            _buildInputField(
              label: 'Email',
              controller: _emailController,
              readOnly: true,
              tailorfontSize: tailorfontSize,
            ),

            _buildInputField(
              label: 'Shop Name',
              controller: _shopNameController,
              tailorfontSize: tailorfontSize,
            ),
            _buildInputField(
              label: 'Address',
              controller: _addressController,
              maxLines: 3,
              tailorfontSize: tailorfontSize,
            ),

            const SizedBox(height: 25),

            // Portfolio Button
            Center(
              child: Container(
                width: 350,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6082B6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Portfolio',
                      style: GoogleFonts.chauPhilomeneOne(
                        fontWeight: FontWeight.w400,
                        fontSize: tailorfontSize,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TailorPortfoliopage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              'SEE MORE',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: tailorfontSize,
                                letterSpacing: 1.5,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
              ),
              child: Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: tailorfontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
