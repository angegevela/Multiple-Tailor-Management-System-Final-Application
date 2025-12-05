import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';

class TailorRatingsandreviewsPage extends StatefulWidget {
  final String tailorId;

  const TailorRatingsandreviewsPage({super.key, required this.tailorId});

  @override
  State<TailorRatingsandreviewsPage> createState() =>
      _TailorRatingsandreviewsPageState();
}

class _TailorRatingsandreviewsPageState
    extends State<TailorRatingsandreviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  Map<String, dynamic>? tailorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
    fetchTailorInfo();
  }

  Future<void> fetchReviews() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.tailorId)
          .collection('Reviews')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        reviews = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['userName'] ?? 'Anonymous',
            'review': data['reviewText'] ?? '',
            'rating': data['rating'] ?? 0,
            'date': data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate().toString()
                : '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchTailorInfo() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.tailorId)
          .get();

      if (snapshot.exists) {
        setState(() {
          tailorData = snapshot.data();
        });
      }
    } catch (e) {
      print('Error fetching tailor info: $e');
    }
  }


  double get averageRating => reviews.isNotEmpty
      ? reviews
                .map((r) => ((r['rating'] ?? 0) as num).toDouble())
                .reduce((a, b) => a + b) /
            reviews.length
      : 0;

  Widget buildStarRating(int rating, {double iconSize = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: iconSize,
        ),
      ),
    );
  }

  Widget buildRatingBreakdown() {
    Map<int, int> breakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in reviews) {
      int rating = ((r['rating'] ?? 0) as num).toInt();
      if (breakdown.containsKey(rating)) {
        breakdown[rating] = breakdown[rating]! + 1;
      }
    }
    return Column(
      children: breakdown.entries.map((entry) {
        double percent = reviews.isEmpty ? 0 : entry.value / reviews.length;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Text(
                '${entry.key} ⭐',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.amber,
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tailorfontSize = context.watch<TailorFontprovider>().fontSize;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF262633),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF262633), Color(0xFF444454)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  tailorData?['profileImageUrl'] != null
                                  ? NetworkImage(tailorData!['profileImageUrl'])
                                  : null,
                              child: tailorData?['profileImageUrl'] == null
                                  ? const Icon(
                                      Icons.storefront,
                                      color: Color(0xFF262633),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tailorData?['shopName'] ?? 'Tailor Shop',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: (tailorfontSize ?? 14) + 3,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      buildStarRating(
                                        ((averageRating).round()).toInt(),
                                        iconSize: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '${averageRating.toStringAsFixed(1)} (${reviews.length} reviews)',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: tailorfontSize ?? 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tailorData?['fullAddress'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: tailorfontSize ?? 12,
                                    ),
                                    textAlign: TextAlign.start,
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        buildRatingBreakdown(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review['name'] ?? 'Anonymous',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  (tailorfontSize ?? 14) + 1,
                                            ),
                                          ),

                                          buildStarRating(
                                            ((review['rating'] ?? 0) as num)
                                                .toInt(),
                                            iconSize: 16,
                                          ),

                                          Text(
                                            review['date'] ?? '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    review['review'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: tailorfontSize ?? 14,
                                    ),
                                  ),
                                  if (review['reply'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.reply,
                                            size: 18,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              review['reply'],
                                              style: GoogleFonts.poppins(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
