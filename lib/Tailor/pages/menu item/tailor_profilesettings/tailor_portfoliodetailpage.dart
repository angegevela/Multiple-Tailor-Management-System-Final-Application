import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';

class TailorPortfolioDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final List<String> imageList;

  const TailorPortfolioDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.imageList,
  });

  @override
  State<TailorPortfolioDetailPage> createState() =>
      _TailorPortfolioDetailPageState();
}

class _TailorPortfolioDetailPageState extends State<TailorPortfolioDetailPage> {
  int currentIndex = 0;
  List<String> _displayImages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prepareSignedUrls();
  }

  Future<void> _prepareSignedUrls() async {
    const prefix =
        'https://lyoarnvbiegjplqbakyg.supabase.co/storage/v1/object/public/Tailor/';

    List<String> signedList = [];

    for (final img in widget.imageList) {
      if (img.startsWith('http') && !img.contains('/object/public/Tailor/')) {
        signedList.add(img);
        continue;
      }
      String relativePath = img;
      if (img.startsWith(prefix)) {
        relativePath = img.substring(prefix.length);
      }

      try {
        final signedUrl = await Supabase.instance.client.storage
            .from('Tailor')
            .createSignedUrl(relativePath, 3600);

        signedList.add(signedUrl);
      } catch (e) {
        print('Error signing URL for $relativePath: $e');
        signedList.add(img);
      }
    }

    if (!mounted) return;
    setState(() {
      _displayImages = signedList;
      _loading = false;
    });
  }

  void _nextImage() {
    if (currentIndex < _displayImages.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void _prevImage() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  Future<String> getImageUrl(String path) async {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Clean up potential duplicate folder paths
    final cleanPath = path.replaceFirst(RegExp(r'^Tailor/'), '');

    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('Tailor')
          .createSignedUrl('Portfolio/$cleanPath', 3600);
      return signedUrl;
    } catch (e) {
      print('❌ Error creating signed URL for $cleanPath: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailorFontSize = context.watch<TailorFontprovider>().fontSize;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_displayImages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF262633),
        ),
        body: const Center(child: Text('No images found.')),
      );
    }

    final hasMultiple = _displayImages.length > 1;
    final currentImage = _displayImages[currentIndex];

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF262633),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                height: 45,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/img/flowerbackground.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Stack(
                    children: [
                      Text(
                        'Portfolio',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.chauPhilomeneOne(
                          fontSize: 24,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..color = Colors.black,
                          letterSpacing: 15,
                        ),
                      ),
                      Text(
                        'Portfolio',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.chauPhilomeneOne(
                          fontSize: 24,
                          color: const Color(0xFF68D2E8).withOpacity(0.8),
                          letterSpacing: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       if (hasMultiple && currentIndex > 0)
            //         Positioned(
            //           left: 12,
            //           child: Container(
            //             width: 45,
            //             height: 45,
            //             decoration: BoxDecoration(
            //               shape: BoxShape.circle,
            //               border: Border.all(
            //                 color: Colors.black.withOpacity(0.8),
            //                 width: 2,
            //               ),
            //               color: Colors.white.withOpacity(0.3),
            //             ),
            //             child: IconButton(
            //               icon: const Icon(
            //                 Icons.arrow_back,
            //                 color: Colors.black,
            //                 size: 22,
            //               ),
            //               onPressed: _prevImage,
            //             ),
            //           ),
            //         ),

            //       Expanded(
            //         child: Stack(
            //           alignment: Alignment.center,
            //           children: [
            //             Padding(
            //               padding: const EdgeInsets.symmetric(
            //                 horizontal: 6,
            //                 vertical: 4,
            //               ),
            //               child: ClipRRect(
            //                 borderRadius: BorderRadius.circular(10),
            //                 child: currentImage.startsWith('http')
            //                     ? CachedNetworkImage(
            //                         imageUrl: currentImage,
            //                         height: 400,
            //                         width: 450,
            //                         fit: BoxFit.fill,
            //                         placeholder: (context, url) => const Center(
            //                           child: CircularProgressIndicator(),
            //                         ),
            //                         errorWidget: (context, url, error) =>
            //                             const Icon(Icons.image, size: 80),
            //                       )
            //                     : Image.asset(
            //                         currentImage,
            //                         height: 285,
            //                         fit: BoxFit.cover,
            //                       ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),

            //       if (hasMultiple && currentIndex < widget.imageList.length - 1)
            //         Positioned(
            //           right: 12,
            //           child: Container(
            //             width: 45,
            //             height: 45,
            //             decoration: BoxDecoration(
            //               shape: BoxShape.circle,
            //               border: Border.all(
            //                 color: Colors.black.withOpacity(0.8),
            //                 width: 2,
            //               ),
            //               color: Colors.white.withOpacity(0.3),
            //             ),
            //             child: IconButton(
            //               icon: const Icon(
            //                 Icons.arrow_forward,
            //                 color: Colors.black,
            //                 size: 22,
            //               ),
            //               onPressed: _nextImage,
            //             ),
            //           ),
            //         ),
            //     ],
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasMultiple && currentIndex > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.8),
                            width: 2,
                          ),
                          color: Colors.transparent,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 22,
                            color: Colors.black,
                          ),
                          onPressed: _prevImage,
                        ),
                      ),
                    ),

                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: currentImage.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: currentImage,
                              height: 420,
                              width: 480,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image, size: 80),
                            )
                          : Image.asset(
                              currentImage,
                              height: 420,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),

                  if (hasMultiple && currentIndex < widget.imageList.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.8),
                            width: 2,
                          ),
                          color: Colors.transparent,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            size: 22,
                            color: Colors.black,
                          ),
                          onPressed: _nextImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chauPhilomeneOne(
                      fontSize: tailorFontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Divider(
                    color: Colors.black,
                    thickness: 2,
                    indent: 20,
                    endIndent: 20,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  widget.description.isNotEmpty
                      ? widget.description
                      : 'No description provided.',
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.cormorantInfant(
                    fontSize: tailorFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
