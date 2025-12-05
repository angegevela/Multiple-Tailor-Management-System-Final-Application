import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/Tailor%20Porfolio/tailor_uploadportfolio.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_portfoliodetailpage.dart';

class TailorPortfoliopage extends StatefulWidget {
  const TailorPortfoliopage({super.key});

  @override
  State<TailorPortfoliopage> createState() => _TailorPortfoliopageState();
}

class _TailorPortfoliopageState extends State<TailorPortfoliopage> {
  final firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _portfolioData = [];
  bool _loading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _listenPortfolioData();
  }

  void _listenPortfolioData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    _subscription = firestore
        .collection('Portfolio')
        .where('tailorUid', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) async {
          List<Map<String, dynamic>> tempList = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final List<String> files = List<String>.from(data['files'] ?? []);
            String imageUrl = '';

            if (files.isNotEmpty) {
              final path = files.first;
              imageUrl = await _getImageUrl(path);
            }

            tempList.add({
              'title': data['title'] ?? 'No title',
              'description': data['description'] ?? '',
              'files': files,
              'imageUrl': imageUrl,
            });
          }

          if (!mounted) return;
          setState(() {
            _portfolioData = tempList;
            _loading = false;
          });
        });
  }

  Future<String> _getImageUrl(String pathOrUrl) async {
    if (pathOrUrl.isEmpty) return '';
    final relativePath = extractRelativePath(pathOrUrl);

    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('Tailor')
          .createSignedUrl(relativePath, 3600);
      return signedUrl ?? '';
    } catch (e) {
      print('Error generating signed URL for $pathOrUrl: $e');
      return '';
    }
  }

  String extractRelativePath(String fullUrl) {
    const prefix =
        'https://lyoarnvbiegjplqbakyg.supabase.co/storage/v1/object/public/Tailor/';
    if (fullUrl.startsWith(prefix)) {
      return fullUrl.substring(prefix.length);
    }
    return fullUrl;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailorfontSize = context.watch<TailorFontprovider>().fontSize;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF262633),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            _buildHeader(),
            const SizedBox(height: 10),
            _portfolioData.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Center(
                      child: Text(
                        "This tailor has not yet uploaded any portfolio.",
                        style: GoogleFonts.chauPhilomeneOne(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 18,
                            mainAxisExtent: 260,
                          ),
                      itemCount: _portfolioData.length,
                      itemBuilder: (context, index) {
                        final item = _portfolioData[index];
                        final imageUrl = item['imageUrl'] ?? '';
                        final files = item['files'] ?? [];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TailorPortfolioDetailPage(
                                  title: item['title'],
                                  description: item['description'],
                                  imageList: files,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.zero,
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        height: 185,
                                        placeholder: (context, url) =>
                                            Container(
                                              height: 185,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              height: 185,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 60,
                                              ),
                                            ),
                                      )
                                    : Container(
                                        height: 185,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          size: 60,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 6),
                              _buildTitleBox(item['title'], tailorfontSize),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),
            _buildUploadButton(tailorfontSize),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF6082B6),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                'Portfolio',
                style: GoogleFonts.chauPhilomeneOne(
                  fontWeight: FontWeight.w400,
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/clear.png',
                      width: 35,
                      height: 35,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBox(String? title, double fontSize) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF6082B6),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        title ?? '',
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.chauPhilomeneOne(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildUploadButton(double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TailorUploadportfolio(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.9),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icons/upload.png', width: 22, height: 22),
                const SizedBox(width: 15),
                Text(
                  "Media Upload",
                  style: GoogleFonts.chauPhilomeneOne(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
