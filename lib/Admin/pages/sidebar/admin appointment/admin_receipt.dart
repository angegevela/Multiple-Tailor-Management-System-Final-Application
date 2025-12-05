import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReceiptPage extends StatelessWidget {
  final String appointmentId;
  const AdminReceiptPage({super.key, required this.appointmentId});

  String _extractRelativePath(String fullUrl) {
    const prefix =
        'https://lyoarnvbiegjplqbakyg.supabase.co/storage/v1/object/public/customers_appointmentfile/';
    if (fullUrl.startsWith(prefix)) return fullUrl.substring(prefix.length);
    
    return '';
  }

  Future<String?> getSignedUrl(String path) async {
    try {
      return await Supabase.instance.client.storage
          .from('customers_appointmentfile')
          .createSignedUrl(path, 3600);
    } catch (e) {
      print('Error generating signed URL: $e');
      return null;
    }
  }

  Future<List<String>> _generateSignedUrls(List<dynamic> uploadedImages) async {
    List<String> signedUrls = [];
    for (var url in uploadedImages) {
      final path = _extractRelativePath(url.toString());
      if (path.isNotEmpty) {
        final signedUrl = await getSignedUrl(path);
        if (signedUrl != null) signedUrls.add(signedUrl);
      }
    }
    return signedUrls;
  }

  @override
  Widget build(BuildContext context) {
    final appointmentRef = FirebaseFirestore.instance
        .collection('Appointment Forms')
        .doc(appointmentId);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1C1F26),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: appointmentRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Appointment not found."));
          }

          final appointmentData = snapshot.data!.data() as Map<String, dynamic>;
          final customerId = appointmentData['customerId'];
          final userRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(customerId);

          return FutureBuilder<DocumentSnapshot>(
            future: userRef.get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;

              final measurements =
                  appointmentData["manualMeasurements"]
                      as Map<String, dynamic>?;
              final uploadedImages =
                  appointmentData["uploadedImages"] as List<dynamic>?;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 1.0),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        "Receipt of Payment",
                        style: GoogleFonts.breeSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 1.0),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        "Within a receipt, you can download and reprint this for future or walk-in display. "
                        "Please keep this receipt as it serves as a reservation confirmation.",
                        style: GoogleFonts.nunito(fontSize: 13),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildSectionTitle("Appointment Details"),
                    buildDetailTable([
                      [
                        "Full Name",
                        appointmentData["fullName"]?.toString() ?? "",
                      ],
                      [
                        "Garment Specification",
                        appointmentData["garmentSpec"]?.toString() ?? "",
                      ],
                      [
                        "Service",
                        appointmentData["services"]?.toString() ?? "",
                      ],
                      [
                        "Customization Detail",
                        appointmentData["customizationDescription"]
                                    ?.toString()
                                    .isNotEmpty ==
                                true
                            ? appointmentData["customizationDescription"]
                                  .toString()
                            : "None indicated",
                      ],
                      [
                        "Quantity",
                        appointmentData["quantity"]?.toString() ?? "",
                      ],
                      ["Message", appointmentData["message"]?.toString() ?? ""],
                      [
                        "Measurement Method",
                        appointmentData["measurementMethod"]?.toString() ?? "",
                      ],
                      [
                        "Manual Measurement Type",
                        appointmentData["manualMeasurementType"]
                                    ?.toString()
                                    .isNotEmpty ==
                                true
                            ? appointmentData["manualMeasurementType"]
                                  .toString()
                            : "None indicated",
                      ],
                    ]),
                    if (uploadedImages != null && uploadedImages.isNotEmpty)
                      FutureBuilder<List<String>>(
                        future: _generateSignedUrls(uploadedImages),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const CircularProgressIndicator();
                          final urls = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                "Customization Images",
                                style: GoogleFonts.songMyung(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: urls.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (_, index) => ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      urls[index],
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 150,
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                    const SizedBox(height: 16),
                    if (measurements != null && measurements.isNotEmpty) ...[
                      buildSectionTitle("Manual Measurements"),
                      buildMeasurementTable(measurements),
                      const SizedBox(height: 16),
                    ],

                    buildSectionTitle("Customer Information"),
                    buildDetailTable([
                      ["Email", userData?["email"]?.toString() ?? "N/A"],
                      [
                        "Phone Number",
                        appointmentData["phoneNumber"]?.toString() ?? "N/A",
                      ],
                      ["Location", userData?["address"]?.toString() ?? "N/A"],
                    ]),

                    const SizedBox(height: 16),
                    buildSectionTitle("Appointment Schedule"),
                    buildDetailTable([
                      [
                        "Appointment Date",
                        appointmentData["appointmentDateTime"]
                                ?.toDate()
                                .toString() ??
                            "",
                      ],
                      [
                        "Due Date",
                        appointmentData["dueDateTime"]?.toDate().toString() ??
                            "",
                      ],
                      [
                        "Priority",
                        appointmentData["priority"]?.toString() ?? "",
                      ],
                      ["Status", appointmentData["status"]?.toString() ?? ""],
                    ]),

                    const SizedBox(height: 16),

                    FutureBuilder<DocumentSnapshot?>(
                      future:
                          (appointmentData["tailorId"] != null &&
                              appointmentData["tailorId"].toString().isNotEmpty)
                          ? FirebaseFirestore.instance
                                .collection('Users')
                                .doc(appointmentData["tailorId"])
                                .get()
                          : null,
                      builder: (context, tailorSnapshot) {
                        String tailorShopName = "Pending";
                        if (tailorSnapshot.hasData &&
                            tailorSnapshot.data != null &&
                            tailorSnapshot.data!.exists) {
                          final tailorData =
                              tailorSnapshot.data!.data()
                                  as Map<String, dynamic>;
                          tailorShopName =
                              tailorData["shopName"]?.toString() ??
                              "Unknown Shop";
                        }
                        return buildDetailTable([
                          ["Tailor Pick", tailorShopName],
                          [
                            "Tailor Assigned",
                            appointmentData["tailorAssigned"]?.toString() ??
                                "Pending",
                          ],
                          [
                            "Price",
                            (appointmentData["price"] == null ||
                                    appointmentData["price"].toString().isEmpty)
                                ? "Pending quotation"
                                : "PHP ${appointmentData["price"].toString()}",
                          ],
                        ]);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Section title widget
  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget buildDetailTable(List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: rows.map((row) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: rows.last == row
                      ? Colors.transparent
                      : Colors.grey.shade300,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        row[0],
                        style: GoogleFonts.b612(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        row[1],
                        style: GoogleFonts.nunito(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildMeasurementTable(Map<String, dynamic> measurements) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: measurements.entries.map((entry) {
          final sectionName = entry.key;
          final sectionData = entry.value as Map<String, dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: Colors.grey,
                padding: const EdgeInsets.all(8),
                child: Text(
                  sectionName,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ...sectionData.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "${e.value}",
                        style: GoogleFonts.nunito(color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 1, color: Colors.grey),
            ],
          );
        }).toList(),
      ),
    );
  }
}
