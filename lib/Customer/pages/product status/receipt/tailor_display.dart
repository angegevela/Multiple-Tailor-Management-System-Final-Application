import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Customer/pages/Notification/customer_notification.dart';
import 'package:threadhub_system/Customer/pages/algorithm%20code/customer_engine.dart';
import 'package:threadhub_system/Customer/pages/product%20status/receipt/appointmentdata.dart';

class TailorResultsPage extends StatefulWidget {
  final AppointmentData data;
  final String customerId;
  final GeoPoint customerLocation;
  final String? declinedTailorId;
  final List<Map<String, dynamic>> tailors;
  const TailorResultsPage({
    super.key,
    required this.data,
    required this.customerId,
    required this.customerLocation,
    this.declinedTailorId,
    required this.tailors,
  });

  @override
  _TailorResultsPageState createState() => _TailorResultsPageState();
}

class _TailorResultsPageState extends State<TailorResultsPage> {
  List<Map<String, dynamic>> availableTailors = [];
  int? selectedTailorIndex;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTailors();
  }

  Future<void> _fetchTailors() async {
    try {
      final matcher = TailorMatcher();
      final allTailors = await matcher.findTailorsForAppointment(
        service: widget.data.services,
        customerLocation: widget.customerLocation,
        radiusKm: 100.0,
        appointmentDate: widget.data.appointmentDateTime,
      );

      final filtered = allTailors
          .where((t) => t['id'] != widget.declinedTailorId)
          .toList();

      setState(() {
        availableTailors = filtered;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching tailors: $e");
      setState(() {
        availableTailors = [];
        isLoading = false;
      });
    }
  }

  Future<String?> _getSignedUrlForTailorImage(String fullUrl) async {
    try {
      const prefix =
          'https://lyoarnvbiegjplqbakyg.supabase.co/storage/v1/object/public/Tailor/Portfolio/';
      if (!fullUrl.startsWith(prefix)) return null;

      final relativePath = fullUrl.substring(prefix.length);
      return await Supabase.instance.client.storage
          .from('Tailor')
          .createSignedUrl('Portfolio/$relativePath', 3600);
    } catch (e) {
      debugPrint('Error generating signed URL: $e');
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchTailorReviews(
    String? tailorUid,
  ) async {
    if (tailorUid == null || tailorUid.isEmpty) return [];

    final trimmedUid = tailorUid.trim();
    try {
      // 1) Try subcollection path: /Users/{tailorUid}/Reviews
      final subcolSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(trimmedUid)
          .collection('Reviews')
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint(
        "📄 Reviews (subcollection) fetched: ${subcolSnapshot.docs.length} for $trimmedUid",
      );

      if (subcolSnapshot.docs.isNotEmpty) {
        return subcolSnapshot.docs;
      }

      // 2) Fallback: top-level /Reviews collection where tailorId == uid
      final topLevelSnapshot = await FirebaseFirestore.instance
          .collection('Reviews')
          .where('tailorId', isEqualTo: trimmedUid)
          // If timestamp doesn't exist or ordering causes index error, catch below
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint(
        "📄 Reviews (top-level) fetched: ${topLevelSnapshot.docs.length} for $trimmedUid",
      );

      return topLevelSnapshot.docs;
    } on FirebaseException catch (fe) {
      // If ordering by timestamp causes a composite index error OR timestamp missing,
      // try to fetch without .orderBy as a last resort.

      try {
        final altSnapshot = await FirebaseFirestore.instance
            .collection('Reviews')
            .where('tailorId', isEqualTo: trimmedUid)
            .get();
        debugPrint(
          "📄 Reviews (top-level, no order) fetched: ${altSnapshot.docs.length} for $trimmedUid",
        );
        if (altSnapshot.docs.isNotEmpty) return altSnapshot.docs;
      } catch (e) {
        debugPrint("❌ Fallback reviews fetch failed: $e");
      }

      return [];
    } catch (e) {
      debugPrint("❌ Error fetching reviews for $tailorUid: $e");
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchTailorPortfolio(
    String? tailorUid,
  ) async {
    if (tailorUid == null || tailorUid.isEmpty) return [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Portfolio')
          .where('tailorUid', isEqualTo: tailorUid.trim())
          .get();

      debugPrint(
        "📂 Portfolio fetched: ${snapshot.docs.length} items for $tailorUid",
      );
      return snapshot.docs;
    } catch (e) {
      debugPrint("❌ Error loading portfolio for $tailorUid: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6082B6),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFA5B7D3),
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            child: Center(
              child: Text(
                'Tailor Available in the Area',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : availableTailors.isEmpty
                ? const Center(child: Text("No tailors found"))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                    itemCount: availableTailors.length,
                    itemBuilder: (context, index) {
                      final tailor = availableTailors[index];
                      final isSelected = selectedTailorIndex == index;
                      final isFullyBooked =
                          (tailor['status'] ?? '') == 'Fully Booked';
                      final shopName = tailor['shopName'] ?? 'Unknown Shop';
                      final ownerName = tailor['ownerName'] ?? 'N/A';
                      final profileImageUrl =
                          tailor['profileImageUrl'] ??
                          tailor['profile_url'] ??
                          tailor['image'] ??
                          '';

                      final availability =
                          tailor['availability'] as Map<String, dynamic>?;

                      final List<dynamic>? daysList =
                          availability?['days'] as List<dynamic>?;
                      final List<dynamic>? servicesList =
                          availability?['servicesOffered'] as List<dynamic>?;
                      final String? timeSlot = availability?['timeSlot'];
                      final int? maxPerDay =
                          availability?['maxCustomersPerDay'];

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTailorIndex = index;
                              });
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(8),
                                                ),
                                            child: SizedBox(
                                              height: 130,
                                              width: double.infinity,
                                              child: profileImageUrl.isNotEmpty
                                                  ? Image.network(
                                                      profileImageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => Container(
                                                            color: Colors
                                                                .grey[300],
                                                            child: const Icon(
                                                              Icons.store,
                                                              size: 50,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.store,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                _showTailorDetails(tailor);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.black,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.person_2,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        shopName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ownerName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isFullyBooked
                                            ? 'Fully Booked'
                                            : 'Available',
                                        style: TextStyle(
                                          color: isFullyBooked
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: -20,
                                    right: -15,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedTailorIndex = value == true
                                              ? index
                                              : null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          Container(
            width: 330,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white),
            child: Text(
              'A thoughtful choice can lead to a lasting relationship with your tailor. '
              'This rapport can improve communication and lead to better service in future appointments.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 9,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6082B6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.cormorantSc(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fetchTailors,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6082B6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Request More Tailors',
                      style: GoogleFonts.cormorantSc(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTailorDetails(Map<String, dynamic> tailor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, controller) {
            final availability =
                tailor['availability'] as Map<String, dynamic>?;
            final List<dynamic>? daysList =
                availability?['days'] as List<dynamic>?;
            final List<dynamic>? servicesList =
                availability?['servicesOffered'] as List<dynamic>?;
            final String? timeSlot = availability?['timeSlot'];
            final int? maxPerDay = availability?['maxCustomersPerDay'];

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: controller,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundImage:
                                  tailor['profileImageUrl'] != null &&
                                      tailor['profileImageUrl'].isNotEmpty
                                  ? NetworkImage(tailor['profileImageUrl'])
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child:
                                  tailor['profileImageUrl'] == null ||
                                      tailor['profileImageUrl'].isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 45,
                                      color: Colors.black54,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tailor['shopName'] ?? 'Unknown Shop',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Owner: ${tailor['ownerName'] ?? 'N/A'}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: const Color(0xFFFAEAB1),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tailor['fullAddress'] ??
                                          tailor['address'] ??
                                          'Not specified',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tailor['businessNumber'] ?? 'Not available',
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tailor['email'] ?? 'Not available',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: const Color(0xFFF0E4D3),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Availability & Schedule",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text(
                                "🕒 Time Slot: ${timeSlot ?? 'No schedule'}",
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "📅 Days: ${daysList != null && daysList.isNotEmpty ? daysList.join(', ') : 'Not listed'}",
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "👥 Max Customers/Day: ${maxPerDay?.toString() ?? 'N/A'}",
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: const Color(0xFFD1D8BE),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.design_services,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Services Offered",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              if (servicesList != null &&
                                  servicesList.isNotEmpty)
                                ...servicesList.map(
                                  (service) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      "• $service",
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  "No services listed",
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Reviews",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),

                      FutureBuilder<List<QueryDocumentSnapshot>>(
                        future: _fetchTailorReviews(
                          tailor['uid'] ??
                              tailor['id'] ??
                              tailor['tailorUid'] ??
                              '',
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              "Error loading reviews.",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.red,
                              ),
                            );
                          }

                          final reviews = snapshot.data ?? [];
                          if (reviews.isEmpty) {
                            return Text(
                              "No reviews yet.",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            );
                          }

                          return Column(
                            children: reviews.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;

                              final rating = data['rating'] ?? 0;
                              final comment =
                                  (data['comment'] ?? data['reviewText'] ?? '')
                                      .toString();
                              final userName =
                                  (data['userName'] ??
                                          data['reviewerName'] ??
                                          'Anonymous')
                                      .toString();
                              DateTime? timestamp;
                              if (data['timestamp'] is Timestamp) {
                                timestamp = (data['timestamp'] as Timestamp)
                                    .toDate();
                              } else if (data['createdAt'] is Timestamp) {
                                timestamp = (data['createdAt'] as Timestamp)
                                    .toDate();
                              }

                              final dateStr = timestamp != null
                                  ? "${timestamp.day}/${timestamp.month}/${timestamp.year}"
                                  : '';

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Reviewer name and date
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            userName,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (dateStr.isNotEmpty)
                                            Text(
                                              dateStr,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            index < rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        comment.isNotEmpty
                                            ? comment
                                            : "No given reviews yet.",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      Text(
                        "Portfolio",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<QueryDocumentSnapshot>>(
                        future: _fetchTailorPortfolio(
                          tailor['uid'] ??
                              tailor['id'] ??
                              tailor['tailorUid'] ??
                              '',
                        ),

                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              "Error loading portfolio images with details.",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.red,
                              ),
                            );
                          }
                          final portfolio = snapshot.data ?? [];
                          if (portfolio.isEmpty) {
                            return Text(
                              "No portfolio are uploaded.",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return _buildPortfolioGrid(portfolio);
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPortfolioImages(
    BuildContext context,
    List<dynamic> fileUrls,
    int startIndex,
  ) async {
    List<String?> signedUrls = await Future.wait(
      fileUrls.map((url) async {
        if (url == null || url.toString().isEmpty) return null;
        return await _getSignedUrlForTailorImage(url.toString());
      }),
    );
    final validUrls = signedUrls.whereType<String>().toList();

    if (validUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No uploaded portfolio images found.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        final controller = PageController(initialPage: startIndex);
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: controller,
                itemCount: validUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = validUrls[index];
                  return InteractiveViewer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioGrid(List<QueryDocumentSnapshot> portfolio) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: portfolio.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final item = portfolio[index].data() as Map<String, dynamic>;
        final List<dynamic>? fileUrls = item['files'] as List<dynamic>?;
        final String? firstImageUrl = (fileUrls != null && fileUrls.isNotEmpty)
            ? (fileUrls.first as String).trim()
            : null;

        if (firstImageUrl == null || firstImageUrl.isEmpty) {
          return _emptyPortfolioCard(item);
        }
        return FutureBuilder<String?>(
          future: _getSignedUrlForTailorImage(firstImageUrl),
          builder: (context, snapshot) {
            final String? signedUrl = snapshot.data;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: signedUrl == null
                        ? Container(
                            height: 120,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              if (fileUrls != null && fileUrls.isNotEmpty) {
                                await _showPortfolioImages(
                                  context,
                                  fileUrls,
                                  0,
                                );
                              }
                            },

                            child: Image.network(
                              signedUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      item['title'] ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      item['description'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyPortfolioCard(Map<String, dynamic> item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item['title'] ?? 'Untitled',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['description'] ?? '',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    if (selectedTailorIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a tailor first.")),
      );
      return;
    }

    final selectedTailor = availableTailors[selectedTailorIndex!];
    final currentUser = FirebaseAuth.instance.currentUser;
    final realCustomerId = widget.customerId.isNotEmpty
        ? widget.customerId
        : currentUser?.uid ?? "";

    await FirebaseFirestore.instance
        .collection("Appointment Forms")
        .doc(widget.data.appointmentId)
        .update({
          "tailorId": selectedTailor['id'],
          "toCustomerId": realCustomerId,
          "status": "Pending Tailor Response",
          "timestamp": FieldValue.serverTimestamp(),
        });

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      'customer_channel',
      'Customer Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      "Appointment Sent!",
      "Your request has been sent to ${selectedTailor['shopName']}.",
      notificationDetails,
    );

    final now = DateTime.now();
    await FirebaseFirestore.instance.collection("notifications").add({
      "title": "Request Sent",
      "body":
          "Your appointment request has been sent to ${selectedTailor['shopName']}.",
      "toCustomerId": realCustomerId,
      "userType": "customer",
      "readBy": [],
      "timestamp": FieldValue.serverTimestamp(),
      "createdAt": now,
      "appointmentId": widget.data.appointmentId,
    });

    await FirebaseFirestore.instance.collection("notifications").add({
      "title": "New Appointment Request",
      "body": "You’ve received a new appointment request from a customer.",
      "toTailorId": selectedTailor['id'],
      "userType": "tailor",
      "readBy": [],
      "timestamp": FieldValue.serverTimestamp(),
      "createdAt": now,
      "appointmentId": widget.data.appointmentId,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerNotification(customerId: realCustomerId),
      ),
    );
  }
}
