import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';

class CustomerHelpPage extends StatefulWidget {
  const CustomerHelpPage({super.key});

  @override
  State<CustomerHelpPage> createState() => _CustomerHelpPageState();
}

class _CustomerHelpPageState extends State<CustomerHelpPage> {
  final TextEditingController _searchController = TextEditingController();
  String _getYouTubeThumbnail(String url) {
    final uri = Uri.parse(url);
    String? videoId;

    if (uri.host.contains("youtu.be")) {
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.queryParameters["v"] != null) {
      videoId = uri.queryParameters["v"];
    }

    return videoId != null
        ? "https://img.youtube.com/vi/$videoId/hqdefault.jpg"
        : "https://via.placeholder.com/160x90.png?text=No+Preview";
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  final List<Map<String, dynamic>> faqs = [
    {
      "question": "How do I take my body measurements properly?",
      "answer":
          "The app provides a step-by-step measurement guide and tutorial videos to help users take accurate measurements at home.",
      "links": [
        {
          "title":
              "HOW TO MEASURE YOURSELF for Online Shopping & Sewing | BlueprintDIY",
          "url": "https://www.youtube.com/watch?v=KfOjOKX4dyg",
        },
        {
          "title": "How To Take Your Own Measurements For Clothing",
          "url": "https://www.youtube.com/watch?v=58UmtCMb-A4",
        },
      ],
    },
    {
      "question":
          "What are the options for measurement methods needed for custom-made clothes?",
      "answer":
          "The system supports two methods:\n\n• Manual Measurement: Customers input their measurements directly into the app.\n• Assisted Measurement: Customers visit a partner tailor who inputs the measurements using their tools.",
    },
    {
      "question": "Should I measure tightly or loosely?",
      "answer":
          "You can select your preferred fit style in the app (tight, standard, or loose). If unsure, choose Assisted Measurement so the tailor can recommend the best fit.",
    },
    {
      "question": "Do I measure over my clothes or directly on my body?",
      "answer":
          "For the most accurate results, measure directly on your body. If using a favorite garment as reference, note that in your customization details.",
    },
    {
      "question": "What’s the difference between body and garment measurement?",
      "answer":
          "Body measurement is your actual size, while garment measurement includes a small allowance for comfort.",
    },
    {
      "question": "How can I make sure my measurements are accurate?",
      "answer":
          "The system allows double-checking entries before saving and supports optional assisted verification by a partner tailor.",
    },
    {
      "question": "What if my clothes don’t fit perfectly after sewing?",
      "answer":
          "You can request readjustments at the tailoring shop after you receive the product.",
    },
    {
      "question": "Can I bring a sample dress or shirt to copy measurements?",
      "answer":
          "Yes. You can input measurements from your sample clothing or ask the tailor to do it during assisted measurement.",
    },
    {
      "question": "Can I update my measurements later in the app?",
      "answer":
          "Yes. Since measurements are taken per product, you can change them before confirming the appointment.",
    },
    {
      "question": "Can I upload a photo of the design I want?",
      "answer":
          "Yes. You can upload a photo within the customization page along with your design details.",
    },
    {
      "question": "Can you combine two different designs into one?",
      "answer":
          "Yes. Upload reference photos in the customization section and describe your desired combination.",
    },
    {
      "question": "Does the system offer ready-made designs?",
      "answer":
          "Yes. Each tailor’s portfolio includes ready-made and sample designs that you can browse before booking.",
    },
    {
      "question": "Can I bring my own fabric?",
      "answer":
          "Yes. Indicate this when submitting your order, and your tailor will confirm during appointment scheduling.",
    },
    {
      "question": "Can I request a specific color or pattern?",
      "answer":
          "Yes. Specify your preferred color, texture, or pattern in the customization section.",
    },
    {
      "question": "Is the price based on design or fabric?",
      "answer":
          "Pricing varies based on design complexity, chosen fabric, and added customization details. The tailor will provide a quote before confirmation.",
    },
    {
      "question": "What payment methods do you accept?",
      "answer":
          "Currently, payments are made directly to your chosen tailor. The app does not yet handle transactions.",
    },
    {
      "question": "How will I know when my clothes are ready?",
      "answer":
          "You’ll receive an in-app notification once production is completed and your order is ready for pickup.",
    },
    {
      "question": "Can I track my order progress in the app?",
      "answer":
          "Yes. Each order includes a progress tracker showing the current stage of production.",
    },
    {
      "question": "How do I contact my tailor through the app?",
      "answer":
          "Use the in-app messaging feature available on the product status page.",
    },
    {
      "question": "Can I log in using Google?",
      "answer": "Yes. The app supports Google login for faster access.",
    },
  ];

  List<Map<String, dynamic>> filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    filteredFaqs = List.from(faqs);
    _searchController.addListener(_filterFaqs);
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredFaqs = query.isEmpty
          ? List.from(faqs)
          : faqs
                .where(
                  (faq) =>
                      faq["question"].toLowerCase().contains(query) ||
                      faq["answer"].toLowerCase().contains(query),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Help Center",
          style: GoogleFonts.prompt(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for help...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
                    child: Text(
                      "No results found.",
                      style: GoogleFonts.prompt(
                        fontSize: fontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              faq["question"],
                              style: GoogleFonts.prompt(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSize,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      faq["answer"],
                                      style: GoogleFonts.prompt(
                                        color: Colors.grey[700],
                                        fontSize: fontSize,
                                      ),
                                    ),
                                    if (faq["links"] != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        "Related Videos:",
                                        style: GoogleFonts.prompt(
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSize,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          for (var link in faq["links"])
                                            GestureDetector(
                                              onTap: () =>
                                                  _launchUrl(link["url"]),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    child: Image.network(
                                                      _getYouTubeThumbnail(
                                                        link["url"],
                                                      ),
                                                      width: 200,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 200,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black26,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.play_circle_fill,
                                                      size: 40,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
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
        ],
      ),
    );
  }
}
