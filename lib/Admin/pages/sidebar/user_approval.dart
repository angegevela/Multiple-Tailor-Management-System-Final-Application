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

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [const Color(0xFF547792).withOpacity(0.1), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Name and Role Icon
                Row(
                  children: [
                    Icon(
                      role == 'Tailor' ? Icons.business : Icons.person,
                      color: const Color(0xFF6082B6),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey, thickness: 0.5),

                // Personal Information Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.location_on, 'Address', user_address),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.work, 'Role', role),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.email, 'Email', email),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.phone, 'Phone', extraDetails),
                  ],
                ),

                const SizedBox(height: 20),

                // Business Permits Section (Tailors only)
                if (role == 'Tailor' && permitUrls.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.description, color: const Color(0xFF6082B6)),
                      const SizedBox(width: 8),
                      Text(
                        'Business Permits',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: FutureBuilder<List<String>>(
                      future: _getSignedPermitUrls(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text(
                            'No permits available',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          );
                        }
                        final signedUrls = snapshot.data!;
                        return SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: signedUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 200,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Image.network(
                                    signedUrls[index],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      alignment: Alignment.center,
                                      color: Colors.grey[200],
                                      child: Text(
                                        'Permit not accessible',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedLayerButton(
                      buttonWidth: 120,
                      buttonHeight: 50,
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
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      topDecoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      topLayerChild: Text(
                        'Approve',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      animationDuration: null,
                      animationCurve: null,
                    ),
                    const SizedBox(width: 20),
                    ElevatedLayerButton(
                      buttonWidth: 120,
                      buttonHeight: 50,
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
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      topDecoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      topLayerChild: Text(
                        'Reject',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6082B6), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF6082B6),
        ),
        drawer: const Menu(),
        backgroundColor: const Color(0xFFD9D9D9),
        body: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    tabs: [
                      Tab(text: 'Tailors'),
                      Tab(text: 'Customers'),
                      Tab(text: 'All'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // TAB CONTENT
            Expanded(child: _ApprovalTabViews()),
          ],
        ),
      ),
    );
  }
}

class _ApprovalTabViews extends StatelessWidget {
  const _ApprovalTabViews();

  Stream<QuerySnapshot> _getUsers(String role) {
    final query = FirebaseFirestore.instance
        .collection('Users')
        .where('accountStatus', isEqualTo: 'pending');

    if (role == 'All') return query.snapshots();
    return query.where('role', isEqualTo: role).snapshots();
  }

  Widget _buildList(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
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
            return (context
                    .findAncestorStateOfType<_AdminUserApprovalFrameState>()!)
                .userCard(users[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        _buildList(_getUsers('Tailor')),
        _buildList(_getUsers('Customer')),
        _buildList(_getUsers('All')),
      ],
    );
  }
}
