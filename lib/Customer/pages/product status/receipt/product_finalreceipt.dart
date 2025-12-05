import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';

class ReceiptPage extends StatelessWidget {
  final String appointmentId;
  const ReceiptPage({super.key, required this.appointmentId});

  String _extractRelativePath(String fullUrl) {
    const prefix =
        'https://lyoarnvbiegjplqbakyg.supabase.co/storage/v1/object/public/customers_appointmentfile/';
    if (fullUrl.startsWith(prefix)) {
      return fullUrl.substring(prefix.length);
    }
    return '';
  }

  Future<String?> getSignedUrl(String path) async {
    try {
      return await Supabase.instance.client.storage
          .from('customers_appointmentfile')
          .createSignedUrl(path, 3600);
    } catch (e) {
      print('Error generating signed URL for $path: $e');
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

  Future<String> _getDownloadPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/$filename";
  }

  Future<void> generatePdf(
    Map<String, dynamic> appointmentData,
    Map<String, dynamic>? userData,
  ) async {
    final pdf = pw.Document();

    String tailorShopName = "Pending";
    if (appointmentData["tailorId"] != null &&
        appointmentData["tailorId"].toString().isNotEmpty) {
      final tailorDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(appointmentData["tailorId"])
          .get();
      if (tailorDoc.exists) {
        final tailorData = tailorDoc.data() as Map<String, dynamic>;
        tailorShopName = tailorData["shopName"] ?? "Unknown Shop";
      }
    }

    List<String> signedUrls = [];
    if (appointmentData["uploadedImages"] != null &&
        (appointmentData["uploadedImages"] as List).isNotEmpty) {
      signedUrls = await _generateSignedUrls(
        appointmentData["uploadedImages"] as List,
      );
    }

    List<pw.MemoryImage> imageWidgets = [];
    for (String url in signedUrls) {
      try {
        final response = await Dio().get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        imageWidgets.add(pw.MemoryImage(response.data));
      } catch (e) {
        print("Image load failed for $url: $e");
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "Receipt of Payment",
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 22),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            "This receipt serves as confirmation of your appointment. Keep it for future reference.",
            style: pw.TextStyle(fontSize: 11),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 16),

          _buildSectionTitle("Appointment Details"),
          _buildDetailTable([
            ["Full Name", appointmentData["fullName"] ?? ""],
            ["Garment Specification", appointmentData["garmentSpec"] ?? ""],
            ["Service", appointmentData["services"] ?? ""],
            [
              "Customization Detail",
              appointmentData["customizationDescription"]
                          ?.toString()
                          .isNotEmpty ==
                      true
                  ? appointmentData["customizationDescription"]
                  : "None indicated",
            ],
            ["Quantity", appointmentData["quantity"]?.toString() ?? ""],
            ["Message", appointmentData["message"] ?? ""],
            ["Measurement Method", appointmentData["measurementMethod"] ?? ""],
            [
              "Manual Measurement Type",
              appointmentData["manualMeasurementType"]?.toString().isNotEmpty ==
                      true
                  ? appointmentData["manualMeasurementType"]
                  : "None indicated",
            ],
          ]),

          if (imageWidgets.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildSectionTitle("Customization Detail Image"),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: imageWidgets
                  .map(
                    (img) => pw.Container(
                      width: 150,
                      height: 150,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Image(img, fit: pw.BoxFit.cover),
                    ),
                  )
                  .toList(),
            ),
          ],

          if (appointmentData["manualMeasurements"] != null &&
              (appointmentData["manualMeasurements"] as Map).isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSectionTitle("Manual Measurements"),
            ...appointmentData["manualMeasurements"].entries.map((section) {
              final sectionName = section.key;
              final sectionData = section.value as Map<String, dynamic>;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      color: PdfColors.grey300,
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        sectionName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: sectionData.entries
                            .map((e) => pw.Text("${e.key}: ${e.value}"))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          pw.SizedBox(height: 16),
          _buildSectionTitle("Customer Information"),
          _buildDetailTable([
            ["Email", userData?["email"] ?? "N/A"],
            ["Phone Number", appointmentData["phoneNumber"] ?? "N/A"],
            ["Location", userData?["address"] ?? "N/A"],
          ]),

          pw.SizedBox(height: 16),
          _buildSectionTitle("Appointment Schedule"),
          _buildDetailTable([
            [
              "Appointment Date",
              appointmentData["appointmentDateTime"]?.toDate().toString() ?? "",
            ],
            [
              "Due Date",
              appointmentData["dueDateTime"]?.toDate().toString() ?? "",
            ],
            ["Priority", appointmentData["priority"] ?? ""],
            ["Status", appointmentData["status"] ?? ""],
          ]),

          pw.SizedBox(height: 16),
          _buildSectionTitle("Tailor & Pricing"),
          _buildDetailTable([
            ["Tailor Pick", tailorShopName],
            ["Tailor Assigned", appointmentData["tailorAssigned"] ?? "Pending"],
            [
              "Price",
              (appointmentData["price"] == null ||
                      appointmentData["price"].toString().isEmpty)
                  ? "Pending quotation"
                  : "PHP ${appointmentData["price"]}",
            ],
          ]),
        ],
      ),
    );

    final safeName =
        appointmentData["fullName"]
            ?.replaceAll(RegExp(r'[^\w\s_-]'), '_')
            .replaceAll(' ', '_') ??
        'Customer';
    final safeDate = DateTime.now()
        .toIso8601String()
        .split('T')
        .first
        .replaceAll('-', '_');

    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/Receipt_${safeName}_$safeDate.pdf";

    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(path);
  }

  Future<void> downloadFile(String url, String filename) async {
    final path = await _getDownloadPath(filename);
    await Dio().download(url, path);
    await OpenFilex.open(path);
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        "Receipt of Payment",
        style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 22),
      ),
    );
  }

  pw.Widget _buildDetailTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(5),
      },
      children: rows
          .map(
            (row) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(row[1]),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final appointmentRef = FirebaseFirestore.instance
          .collection('Appointment Forms')
          .doc(appointmentId);

      return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1F26),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
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

            final appointmentData =
                snapshot.data!.data() as Map<String, dynamic>;
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildDetailTable([
                            ["Full Name", appointmentData["fullName"] ?? ""],
                            [
                              "Garment Specification",
                              appointmentData["garmentSpec"] ?? "",
                            ],
                            ["Service", appointmentData["services"] ?? ""],
                            [
                              "Customization Detail",
                              appointmentData["customizationDescription"]
                                          ?.toString()
                                          .isNotEmpty ==
                                      true
                                  ? appointmentData["customizationDescription"]
                                  : "None is indicated",
                            ],
                          ]),

                          if (uploadedImages != null &&
                              uploadedImages.isNotEmpty)
                            FutureBuilder<List<String>>(
                              future: _generateSignedUrls(uploadedImages),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final urls = snapshot.data!;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Customization Detail Image",
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
                                          itemBuilder: (context, index) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                urls[index],
                                                width: 150,
                                                height: 150,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      width: 150,
                                                      height: 150,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.broken_image,
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
                            ),
                          const SizedBox(height: 10),
                          buildDetailTable([
                            [
                              "Quantity",
                              appointmentData["quantity"]?.toString() ?? "",
                            ],
                            ["Message", appointmentData["message"] ?? ""],
                            [
                              "Measurement Method",
                              appointmentData["measurementMethod"] ?? "",
                            ],
                            [
                              "Manual Measurement Type",
                              (appointmentData["manualMeasurementType"]
                                          ?.toString()
                                          .isNotEmpty ==
                                      true)
                                  ? appointmentData["manualMeasurementType"]
                                  : "None is indicated",
                            ],
                          ]),
                        ],
                      ),

                      if (measurements != null && measurements.isNotEmpty) ...[
                        buildSectionTitle("Manual Measurements"),
                        buildMeasurementTable(measurements),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 16),

                      buildSectionTitle("Customer Information"),
                      buildDetailTable([
                        ["Email", userData?["email"] ?? "N/A"],
                        [
                          "Phone Number",
                          appointmentData["phoneNumber"] ?? "N/A",
                        ],
                        ["Location", userData?["address"] ?? "N/A"],
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
                        ["Priority", appointmentData["priority"] ?? ""],
                        ["Status", appointmentData["status"] ?? ""],
                      ]),

                      const SizedBox(height: 16),

                      buildSectionTitle("Tailor & Pricing"),
                      FutureBuilder<DocumentSnapshot?>(
                        future:
                            (appointmentData["tailorId"] != null &&
                                appointmentData["tailorId"]
                                    .toString()
                                    .isNotEmpty)
                            ? FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(appointmentData["tailorId"])
                                  .get()
                            : null, // can just be null
                        builder: (context, tailorSnapshot) {
                          String tailorShopName = "Pending";

                          if (tailorSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (tailorSnapshot.hasData &&
                              tailorSnapshot.data != null &&
                              tailorSnapshot.data!.exists) {
                            final tailorData =
                                tailorSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            tailorShopName =
                                tailorData["shopName"] ?? "Unknown Shop";
                          }

                          return buildDetailTable([
                            ["Tailor Pick", tailorShopName],
                            [
                              "Tailor Assigned",
                              appointmentData["tailorAssigned"] ?? "Pending",
                            ],
                            [
                              "Price",
                              (appointmentData["price"] == null ||
                                      appointmentData["price"]
                                          .toString()
                                          .isEmpty)
                                  ? "Pending quotation"
                                  : "PHP ${appointmentData["price"]}",
                            ],
                          ]);
                        },
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await generatePdf(appointmentData, userData);
                          } catch (e) {
                            print("PDF generation failed: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Failed to download receipt."),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6082B6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "DOWNLOAD",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    } catch (e, st) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: Text('Failed to load receipt: $e')),
      );
    }
  }

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
