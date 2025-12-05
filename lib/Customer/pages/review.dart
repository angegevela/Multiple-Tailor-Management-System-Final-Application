import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';

class RatingandReviewPage extends StatefulWidget {
  final String tailorId;
  final String tailorName;
  final String tailorPhone;
  final String tailorEmail;
  final String tailorImage;
  final String tailorShop;
  final String availability;
  final String expertise;
  final String status;
  final String location;
  final String appointmentId;

  const RatingandReviewPage({
    super.key,
    required this.tailorId,
    required this.tailorName,
    required this.tailorPhone,
    required this.tailorEmail,
    required this.tailorImage,
    required this.tailorShop,
    required this.availability,
    required this.expertise,
    required this.status,
    required this.location,
    required this.appointmentId,
  });

  @override
  State<RatingandReviewPage> createState() => _RatingandReviewPageState();
}

class _RatingandReviewPageState extends State<RatingandReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _postAsAnonymous = false;

  final double _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();

  Future<String?> _getSignedUrlForTailorImage(String pathOrUrl) async {
    if (pathOrUrl.isEmpty) return null;

    const bucketName = 'customers_appointmentfile';
    String path;

    if (pathOrUrl.startsWith('http')) {
      final uri = Uri.parse(pathOrUrl);
      final segments = uri.pathSegments;
      final index = segments.indexOf('appointments');
      if (index != -1) {
        path = segments.sublist(index).join('/');
      } else {
        path = pathOrUrl;
      }
    } else {
      path = 'appointments/$pathOrUrl';
    }

    debugPrint('Fetching signed URL for: $path in bucket $bucketName');

    try {
      final signedUrl = await Supabase.instance.client.storage
          .from(bucketName)
          .createSignedUrl(path, 3600);
      debugPrint('Signed URL generated successfully: $signedUrl');
      return signedUrl;
    } catch (e) {
      debugPrint('Error generating signed URL: $e');
      return null;
    }
  }

  String extractPath(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final index = segments.indexOf('customers_appointmentfile');
    if (index != -1 && index + 1 < segments.length) {
      return segments.sublist(index + 1).join('/');
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _showReviewDialog() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .get();

    final firstName = userDoc.data()?['firstName'] ?? "";
    final surname = userDoc.data()?['surname'] ?? "";
    final realName = "$firstName $surname".trim();

    double rating = 0;
    TextEditingController reviewController = TextEditingController();
    bool postAsAnonymous = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Share Your Opinion",
                        style: GoogleFonts.vazirmatn(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 15),

                      Text(
                        "You can also rate in stars",
                        style: GoogleFonts.fahkwang(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                rating = (index + 1).toDouble();
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2BA24C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),
                      TextField(
                        controller: reviewController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          hintText: "Write your review here...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: postAsAnonymous,
                            activeColor: Colors.black,
                            onChanged: (value) {
                              setState(() {
                                postAsAnonymous = value!;
                              });
                            },
                          ),
                          const Text("Post as Anonymous"),
                        ],
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (rating == 0 ||
                                reviewController.text.trim().isEmpty) {
                              return;
                            }

                            final displayName = postAsAnonymous
                                ? "Anonymous"
                                : realName;

                            await FirebaseFirestore.instance
                                .collection('Users')
                                .doc(widget.tailorId)
                                .collection('Reviews')
                                .add({
                                  'rating': rating,
                                  'reviewText': reviewController.text.trim(),
                                  'userName': displayName,
                                  'userId': currentUserId,
                                  'appointmentId': widget.appointmentId,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF261E27),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Write A Review",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<DocumentSnapshot> _getAppointmentDetails() async {
    return await FirebaseFirestore.instance
        .collection('Appointment Forms')
        .doc(widget.appointmentId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.tailorImage.isNotEmpty
                          ? Image.network(
                              widget.tailorImage,
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.white70,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.store,
                                  color: Color(0xFF2BA24C),
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Shop Information",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize + 3,
                                    color: const Color(0xFF261E27),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _buildServiceDetail(
                              "Shop Name",
                              widget.tailorShop.trim(),
                            ),
                            _buildServiceDetail(
                              "Phone",
                              widget.tailorPhone.trim(),
                            ),
                            _buildServiceDetail(
                              "Email",
                              widget.tailorEmail.trim(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      FutureBuilder<DocumentSnapshot>(
                        future: _getAppointmentDetails(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              padding: const EdgeInsets.all(16),
                              decoration: _cardDecoration(),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              padding: const EdgeInsets.all(16),
                              decoration: _cardDecoration(),
                              child: const Text("No appointment details."),
                            );
                          }

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;

                          return Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_long,
                                      color: Color(0xFF2BA24C),
                                      size: 26,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Booked Service",
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w700,
                                        fontSize: fontSize + 3,
                                        color: Color(0xFF2B2B2B),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                _buildServiceDetail(
                                  "Service",
                                  data['services'],
                                ),
                                _buildServiceDetail(
                                  "Garment Specification",
                                  data['garmentSpec'],
                                ),
                                _buildServiceDetail(
                                  "Price",
                                  "₱ ${data['price']}",
                                ),

                                const SizedBox(height: 12),

                                FutureBuilder<DocumentSnapshot>(
                                  future: _getAppointmentDetails(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    if (!snapshot.hasData ||
                                        !snapshot.data!.exists) {
                                      return const SizedBox();
                                    }

                                    final data =
                                        snapshot.data!.data()
                                            as Map<String, dynamic>;
                                    final List<dynamic> customerImages =
                                        data['uploadedImages'] ?? [];

                                    if (customerImages.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          "No images uploaded images.",
                                        ),
                                      );
                                    }
                                    return SizedBox(
                                      height: 180,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: customerImages.length,
                                        itemBuilder: (context, index) {
                                          final imagePath =
                                              customerImages[index];

                                          return FutureBuilder<String?>(
                                            future: _getSignedUrlForTailorImage(
                                              imagePath,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Container(
                                                  width: 150,
                                                  margin: const EdgeInsets.only(
                                                    right: 12,
                                                  ),
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                              }
                                              if (snapshot.data == null) {
                                                return Container(
                                                  width: 150,
                                                  margin: const EdgeInsets.only(
                                                    right: 12,
                                                  ),
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                  ),
                                                );
                                              }
                                              return Container(
                                                width: 150,
                                                margin: const EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 35,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF6082B6),
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Text(
                    "Reviews",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                  Text(
                    "Portfolio",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 550,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewSectionDynamic(fontSize),
                  _buildPortfolioSectionDynamic(fontSize),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: fontSize,
                color: const Color(0xFF4F607A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBoxHeader(String text, double fontSize) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFC4C4C4),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildServiceDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value ?? "Not specified",
              style: GoogleFonts.montserrat(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBoxContent(
    List<String> lines,
    double fontSize, {
    bool isCentered = false,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: isCentered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Text(
                line,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF4F607A),
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
                textAlign: isCentered ? TextAlign.center : TextAlign.start,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _locationBox(String address, double fontSize) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        border: Border.all(color: Colors.black),
      ),
      child: Text(
        address,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: const Color(0xFF4F607A),
        ),
      ),
    );
  }

  Widget _buildReviewSectionDynamic(double fontSize) {
    final tailorId = widget.tailorId;
    final appointmentId = widget.appointmentId;
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What customers say about me",
            style: GoogleFonts.robotoCondensed(
              fontWeight: FontWeight.bold,
              fontSize: fontSize + 1,
            ),
          ),
          Text(
            "We do our best to provide you the best experience ever.",
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w300,
              fontSize: fontSize + 1,
            ),
          ),
          const SizedBox(height: 30),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(tailorId)
                .collection('Reviews')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Text("No reviews yet."),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _showReviewDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF261E27),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Write A Review",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final reviews = snapshot.data!.docs;
              final hasReviewed = reviews.any((r) {
                final data = r.data() as Map<String, dynamic>;
                return data['userId'] == currentUserUid &&
                    data['appointmentId'] == widget.appointmentId;
              });
              double avgRating = 0;
              if (reviews.isNotEmpty) {
                avgRating =
                    reviews.fold<double>(0.0, (sum, r) {
                      final data = r.data() as Map<String, dynamic>;
                      return sum + (data['rating'] as num).toDouble();
                    }) /
                    reviews.length;
              }

              return Column(
                children: [
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: reviews.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildReviewSummaryCardDynamic(
                            fontSize,
                            avgRating,
                            reviews.length,
                          );
                        }

                        final item =
                            reviews[index - 1].data() as Map<String, dynamic>;

                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      item['rating'].toInt(),
                                      (_) => const Icon(
                                        Icons.star,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['reviewText'] ?? "",
                                    style: GoogleFonts.montserrat(
                                      fontSize: fontSize,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['userName'],
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!hasReviewed)
                    ElevatedButton(
                      onPressed: _showReviewDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF261E27),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Write A Review",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummaryCardDynamic(
    double fontSize,
    double avgRating,
    int totalReviews,
  ) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Review and Rating",
                style: GoogleFonts.montserrat(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    color: i < avgRating.round() ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$totalReviews Reviews",
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSectionDynamic(double fontSize) {
    final tailorId = widget.tailorId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Portfolio')
          .where('tailorUid', isEqualTo: tailorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No portfolio items yet."));
        }

        final portfolioItems = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: portfolioItems.length,
                  itemBuilder: (context, index) {
                    final item = portfolioItems[index];
                    final List images = item['files'];

                    return Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item['description'] ?? "No description",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 200,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: images.length,
                                          itemBuilder: (context, imgIndex) {
                                            return FutureBuilder<String?>(
                                              future:
                                                  _getSignedUrlForTailorImage(
                                                    images[imgIndex],
                                                  ),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                }
                                                if (snapshot.data == null) {
                                                  return const Icon(
                                                    Icons.broken_image,
                                                  );
                                                }
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  child: Image.network(
                                                    snapshot.data!,
                                                    width: 150,
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: [
                              Expanded(
                                child: FutureBuilder<String?>(
                                  future: _getSignedUrlForTailorImage(
                                    images.isNotEmpty ? images[0] : "",
                                  ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.data == null) {
                                      return const Center(
                                        child: Icon(Icons.broken_image),
                                      );
                                    }
                                    return Image.network(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  item['title'],
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
