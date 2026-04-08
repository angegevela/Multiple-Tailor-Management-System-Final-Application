import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:simple_animated_button/elevated_layer_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Admin/pages/sidebar/menu.dart';
import 'package:threadhub_system/main.dart';

class AdminUserApprovalFrame extends StatefulWidget {
  const AdminUserApprovalFrame({super.key});

  @override
  State<AdminUserApprovalFrame> createState() => _AdminUserApprovalFrameState();
}

class _AdminUserApprovalFrameState extends State<AdminUserApprovalFrame> {
  final int _selectedTab = 0;

  final List<String> roles = ['Tailor', 'Customer', 'All'];

  Future<void> approveUser(String userId, String email) async {
    await FirebaseFirestore.instance.collection('Users').doc(userId).update({
      'approved': true,
      'accountStatus': 'approved',
      'emailApproved': email,
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
      debugPrint('Error generating signed URL for $path: $e');
      return null;
    }
  }

  Widget userCard(QueryDocumentSnapshot user) {
    final role = user['role'] ?? '-';

    if (role == 'Tailor') {
      // Tailor Card
      final displayName =
          '${user['ownerName'] ?? '-'} — ${user['shopName'] ?? '-'}';
      final extraDetails = '${user['businessNumber'] ?? '-'}';
      final userAddress = user['fullAddress'] ?? user['address'] ?? '-';
      final email = user['email'] ?? '-';

      final List<String> permitUrls =
          (user['businessPermits'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList();

      Future<List<String>> getSignedPermitUrls() async {
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

      return _buildTailorCard(
        displayName,
        extraDetails,
        userAddress,
        email,
        permitUrls,
        getSignedPermitUrls,
        user.id,
      );
    } else if (role == 'Customer') {
      // Customer Card
      final displayName =
          '${user['firstName'] ?? '-'} ${user['surname'] ?? '-'}';
      final extraDetails = (user['phoneNumber'] ?? '-').toString();
      final userAddress = user['fullAddress'] ?? user['address'] ?? '-';
      final email = user['email'] ?? '-';

      return _buildCustomerCard(
        displayName,
        extraDetails,
        userAddress,
        email,
        user.id,
      );
    } else {
      // Fallback For Any Unknown Role(Any glitch happens)
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Unknown user role'),
        ),
      );
    }
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

  Widget _buildTailorCard(
    String displayName,
    String extraDetails,
    String userAddress,
    String email,
    List<String> permitUrls,
    Future<List<String>> Function() getSignedPermitUrls,
    String userId,
  ) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: const Color(0xFF6082B6), size: 28),
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
            _buildInfoRow(Icons.location_on, 'Address', userAddress),
            _buildInfoRow(Icons.email, 'Email', email),
            _buildInfoRow(Icons.phone, 'Phone', extraDetails),
            const SizedBox(height: 12),
            // Business Permits
            if (permitUrls.isNotEmpty)
              FutureBuilder<List<String>>(
                future: getSignedPermitUrls(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final signedUrls = snapshot.data ?? [];
                  return SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: signedUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _adjustingImage(signedUrls[index]);
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            _buildApprovalButtons(userId, displayName, email),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    String displayName,
    String extraDetails,
    String userAddress,
    String email,
    String userId,
  ) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: const Color(0xFF6082B6), size: 28),
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
            _buildInfoRow(Icons.location_on, 'Address', userAddress),
            _buildInfoRow(Icons.email, 'Email', email),
            _buildInfoRow(Icons.phone, 'Phone', extraDetails),
            const SizedBox(height: 20),
            _buildApprovalButtons(userId, displayName, email),
          ],
        ),
      ),
    );
  }

  Widget _adjustingImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: navigatorKey.currentContext!,
            builder: (_) => Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  initialScale: PhotoViewComputedScale.contained,
                ),
              ),
            ),
          );
        },
        child: Image.network(imageUrl, width: 200, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildApprovalButtons(
    String userId,
    String displayName,
    String email,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedLayerButton(
          buttonWidth: 120,
          buttonHeight: 50,
          onClick: () async {
            await approveUser(userId, email);
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text('$displayName approved'),
                backgroundColor: Colors.green,
              ),
            );
          },
          baseDecoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(10),
          ),
          topDecoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
          ),
          topLayerChild: const Text(
            'Approve',
            style: TextStyle(color: Colors.white),
          ),
          animationDuration: null,
          animationCurve: null,
        ),
        const SizedBox(width: 20),
        ElevatedLayerButton(
          buttonWidth: 120,
          buttonHeight: 50,
          onClick: () async {
            await rejectUser(userId);
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text('$displayName rejected'),
                backgroundColor: Colors.red,
              ),
            );
          },
          baseDecoration: BoxDecoration(
            color: Colors.red[700],
            borderRadius: BorderRadius.circular(10),
          ),
          topDecoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          topLayerChild: const Text(
            'Reject',
            style: TextStyle(color: Colors.white),
          ),
          animationDuration: null,
          animationCurve: null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF6082B6)),
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
