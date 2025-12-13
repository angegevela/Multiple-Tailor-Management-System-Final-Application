import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_animated_button/bouncing_button.dart';
import 'package:simple_animated_button/elevated_layer_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Admin/pages/sidebar/menu.dart';

class AdminUserApprovalFrame extends StatefulWidget {
  const AdminUserApprovalFrame({super.key});

  @override
  State<AdminUserApprovalFrame> createState() => _AdminUserApprovalFrameState();
}

class _AdminUserApprovalFrameState extends State<AdminUserApprovalFrame> {
  int _selectedTab = 0;

  final List<String> roles = ['Tailor', 'Customer', 'All'];

  Future<void> approveUser(String userId) async {
    await FirebaseFirestore.instance.collection('Users').doc(userId).update({
      'approved': true,
      'accountStatus': 'approved',
    });
    if (mounted) setState(() {});
  }

  Future<void> rejectUser(String userId) async {
    await FirebaseFirestore.instance.collection('Users').doc(userId).update({
      'approved': false,
      'accountStatus': 'rejected',
    });
    if (mounted) setState(() {});
  }

  Stream<QuerySnapshot> getUsersStream(String role) {
    final query = FirebaseFirestore.instance
        .collection('Users')
        .where('accountStatus', isEqualTo: 'pending');
    if (role != 'All') {
      return query.where('role', isEqualTo: role).snapshots();
    }
    return query.snapshots();
  }

  String _extractRelativePath(String fullUrl) {
    const prefix =
        'https://lyoarnvbiegjplqbakyg.supabase.co/storage/v1/object/public/Tailor/Permits/';
    if (fullUrl.startsWith(prefix)) {
      return fullUrl.substring(prefix.length);
    }
    return '';
  }

  Future<String?> getSignedUrl(String path) async {
    try {
      return await Supabase.instance.client.storage
          .from('Tailor')
          .createSignedUrl('Permits/$path', 3600);
    } catch (e) {
      print('Error generating signed URL for $path: $e');
      return null;
    }
  }

  Widget userCard(QueryDocumentSnapshot user) {
    final role = user['role'] ?? '-';
    final email = user['email'] ?? '-';
    final displayName = role == 'Tailor'
        ? '${user['ownerName'] ?? '-'} — ${user['shopName'] ?? '-'}'
        : '${user['firstName'] ?? '-'} ${user['surname'] ?? '-'}';
    final extraDetails = role == 'Tailor'
        ? '${user['businessNumber'] ?? '-'}'
        : '${user['phoneNumber'] ?? '-'}';
    final user_address = user['fullAddress'] ?? user['address'] ?? '-';

    // Raw permit URLs from Firestore
    final List<String> permitUrls = role == 'Tailor'
        ? (user['businessPermits'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList()
        : [];

    // Fetch signed URLs
    Future<List<String>> _getSignedPermitUrls() async {
      List<String> signedUrls = [];
      for (var url in permitUrls) {
        final path = _extractRelativePath(url);
        if (path.isNotEmpty) {
          final signedUrl = await getSignedUrl(path);
          if (signedUrl != null) signedUrls.add(signedUrl);
        }
      }
      return signedUrls;
    }

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Of the User Displayed in Card
            Text(
              displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            // Personal Information from the Create Account - Sign Up
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: 'Address:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: user_address),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: 'Role: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: role),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: 'Email: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: email),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: 'Phone: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: extraDetails),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Business Permits (Tailors - Tailor Shops only)
            if (role == 'Tailor' && permitUrls.isNotEmpty) ...[
              const Text(
                'Business Permit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<String>>(
                future: _getSignedPermitUrls(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No permits available');
                  }
                  final signedUrls = snapshot.data!;
                  return SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: signedUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            signedUrls[index],
                            width: 220,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                const Text('Permit not available'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Approve Button - for Administrator Application
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedLayerButton(
                  buttonWidth: 110,
                  buttonHeight: 48,
                  onClick: () async {
                    await approveUser(user.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$displayName approved'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  baseDecoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  topDecoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  topLayerChild: const Text(
                    'Approve',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  animationDuration: null,
                  animationCurve: null,
                ),
                const SizedBox(width: 16),

                // Reject Button - Administrator
                ElevatedLayerButton(
                  buttonWidth: 110,
                  buttonHeight: 48,
                  onClick: () async {
                    await rejectUser(user.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$displayName rejected'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  baseDecoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  topDecoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  topLayerChild: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  animationDuration: null,
                  animationCurve: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Approval'),
        backgroundColor: const Color(0xFF6082B6),
      ),
      drawer: const Menu(),
      backgroundColor: const Color(0xFFD9D9D9),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUsersStream(roles[_selectedTab]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending users.'));
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return userCard(users[index]);
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBAr(
        selectedItem: _selectedTab,
        callbackFromNav: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
      ),
    );
  }
}

// Source - https://stackoverflow.com/a
// Posted by Md. Yeasin Sheikh
// Retrieved 2025-12-14, License - CC BY-SA 4.0

class BottomNavBAr extends StatelessWidget {
  final int selectedItem;

  final Function callbackFromNav;

  const BottomNavBAr({
    Key? key,
    required this.callbackFromNav,
    required this.selectedItem,
  }) : super(key: key);

  get _radius => Radius.circular(8);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: kToolbarHeight,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: constraints.maxWidth * .85,
                height: kToolbarHeight * .7,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF547792),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: constraints.maxWidth * .88,
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ChipItem(
                        text: "Tailors",
                        width: constraints.maxWidth * .5,
                        isSelected: 0 == selectedItem,
                        oncallBack: () => callbackFromNav(0),
                        decoration: 0 == selectedItem
                            ? BoxDecoration(
                                color: Color(0xFFA1BC98),
                                borderRadius: BorderRadius.only(
                                  topLeft: _radius,
                                  topRight: _radius,
                                  bottomLeft: _radius,
                                ),
                              )
                            : BoxDecoration(),
                      ),
                      ChipItem(
                        text: "Customers",
                        width: constraints.maxWidth * .5,
                        isSelected: 1 == selectedItem,
                        decoration: 1 == selectedItem
                            ? BoxDecoration(
                                color: Color(0xFFA1BC98),
                                borderRadius: BorderRadius.only(
                                  topLeft: _radius,
                                  topRight: _radius,
                                  bottomRight: _radius,
                                ),
                              )
                            : BoxDecoration(),
                        oncallBack: () => callbackFromNav(1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChipItem extends StatelessWidget {
  final double width;

  final String text;
  final bool isSelected;
  final Function oncallBack;

  final BoxDecoration decoration;

  const ChipItem({
    Key? key,
    required this.oncallBack,
    required this.text,
    required this.width,
    required this.isSelected,
    this.decoration = const BoxDecoration(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => oncallBack(),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(8),
        width: width,
        decoration: decoration,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSelected ? 24 : 16,
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
