import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:threadhub_system/Customer/pages/algorithm%20code/customer_engine.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'package:threadhub_system/Customer/pages/product%20status/receipt/appointmentdata.dart';
import 'package:path/path.dart' as p;
import 'package:threadhub_system/Customer/pages/product%20status/receipt/tailor_display.dart';
import 'dart:convert';

class ReceiptPage extends StatefulWidget {
  final AppointmentData data;
  const ReceiptPage({super.key, required this.data});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF262633),
        title: Text(
          'Appointment Receipt',
          style: TextStyle(color: Colors.white, fontSize: fontSize),
        ),
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: RepaintBoundary(
              key: _receiptKey,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.all(10.0),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xFF618CF1), width: 1.5),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "Please review the details of your appointment. Keep in  mind that this appointment is non-transferable and non-reversable.",
                      style: GoogleFonts.songMyung(fontSize: fontSize),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontFamily: 'HermeneusOne',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(2.5),
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: Colors.black12),
                        ),
                        children: [
                          buildTableRow(
                            context,
                            label: "Full Name",
                            value: widget.data.fullName,
                          ),
                          buildTableRow(
                            context,
                            label: "Garment Specification",
                            value: widget.data.garmentSpec,
                          ),
                          buildTableRow(
                            context,
                            label: "Service",
                            value: widget.data.services,
                          ),
                          buildTableRow(
                            context,
                            label: "Quantity",
                            value:
                                widget.data.quantity?.toString() ??
                                "Not specified",
                          ),

                          buildTableRow(
                            context,
                            label: "Customization Detail",
                            value:
                                widget.data.customizationDescription ?? "None",
                          ),
                          buildTableRow(
                            context,
                            label: "Media Upload",
                            value: widget.data.uploadedImages.isNotEmpty
                                ? widget.data.uploadedImages
                                      .map((filePath) => p.basename(filePath))
                                      .join(", ")
                                : "No media uploaded",
                          ),
                          buildTableRow(
                            context,
                            label: "Message",
                            value: widget.data.message,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Contact Details',
                      style: TextStyle(
                        fontFamily: 'HermeneusOne',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(2.5),
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: Colors.black12),
                        ),
                        children: [
                          buildTableRow(
                            context,
                            label: "Mobile Number",
                            value: widget.data.phoneNumber != null
                                ? "+63 ${widget.data.phoneNumber}"
                                : "Not provided",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Deadline Details',
                      style: TextStyle(
                        fontFamily: 'HermeneusOne',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(2.5),
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: Colors.black12),
                        ),
                        children: [
                          buildTableRow(
                            context,
                            label: "Needed By Date",
                            value: widget.data.dueDateTime != null
                                ? DateFormat(
                                    "MMMM dd, yyyy, h:mm a",
                                  ).format(widget.data.dueDateTime!)
                                : "Not set",
                          ),
                          buildTableRow(
                            context,
                            label: "Prioritization",
                            value: widget.data.duepriority ?? "Not specified",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontFamily: 'HermeneusOne',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(2.5),
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: Colors.black12),
                        ),
                        children: [
                          buildTableRow(
                            context,
                            label: "Appointment Date",
                            value: widget.data.appointmentDateTime != null
                                ? DateFormat(
                                    "MMMM dd, yyyy, h:mm a",
                                  ).format(widget.data.appointmentDateTime!)
                                : "Not set",
                          ),
                          buildTableRow(
                            context,
                            label: "Prioritization",
                            value: widget.data.priority ?? "Not specified",
                          ),
                          buildTableRow(
                            context,
                            label: "Measurement Method",
                            value:
                                widget.data.measurementMethod?.trim() ??
                                "Not specified",
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (widget.data.manualMeasurements != null &&
                      widget.data.manualMeasurements!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Manual Measurements',
                        style: TextStyle(
                          fontFamily: 'HermeneusOne',
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      width: 350,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2.5),
                            1: FlexColumnWidth(2.5),
                          },
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: Colors.black12),
                          ),
                          children: [
                            buildTableRow(
                              context,
                              label: "Measurement Type",
                              value:
                                  widget.data.manualMeasurementType ??
                                  "Not specified",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    SizedBox(
                      width: 350,
                      child: Column(
                        children: widget.data.manualMeasurements!.entries.map((
                          entry,
                        ) {
                          final partName = entry.key;
                          final measurements =
                              entry.value as Map<String, dynamic>? ?? {};

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                partName,
                                style: TextStyle(
                                  fontFamily: 'HermeneusOne',
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                ),
                              ),
                              children: measurements.entries.map((mEntry) {
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    mEntry.key,
                                    style: TextStyle(
                                      fontFamily: 'HermeneusOne',
                                      fontWeight: FontWeight.w500,
                                      fontSize: fontSize,
                                    ),
                                  ),
                                  trailing: Text(
                                    "${mEntry.value} ${widget.data.manualMeasurementType ?? ''}",
                                    style: TextStyle(
                                      fontFamily: 'HermeneusOne',
                                      fontSize: fontSize,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              final pos = await _determinePosition(context);
                              if (pos == null) return;

                              GeoPoint customerLocation = GeoPoint(
                                pos.latitude,
                                pos.longitude,
                              );

                              final matcher = TailorMatcher();
                              final tailors = await matcher
                                  .findTailorsForAppointment(
                                    service: widget.data.services,
                                    customerLocation: customerLocation,
                                    radiusKm: 5.0,
                                    appointmentDate:
                                        widget.data.appointmentDateTime,
                                  );

                              if (tailors.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TailorResultsPage(
                                      tailors: tailors,
                                      data: widget.data,
                                      customerId: '',
                                      customerLocation: customerLocation,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No tailors found nearby."),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to find tailors: $e"),
                                ),
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6082B6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(70, 50),
                      padding: const EdgeInsets.all(10),
                    ),
                    child: Text(
                      "Find Tailor",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

TableRow buildTableRow(
  BuildContext context, {
  required String label,
  required String value,
  Color leftColor = const Color(0xFFE8F9FF),
  Color rightColor = Colors.white,
}) {
  final fontSize = context.watch<FontProvider>().fontSize;
  Color textColor = Colors.black;

  if (label == "Prioritization") {
    if (value.toLowerCase().contains("low")) {
      textColor = Colors.green;
    } else if (value.toLowerCase().contains("medium")) {
      textColor = Colors.yellow[800]!;
    } else if (value.toLowerCase().contains("high")) {
      textColor = const Color(0xFF900707);
    }
  }

  return TableRow(
    children: [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.fill,
        child: Container(
          color: leftColor,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'HermeneusOne',
              fontSize: fontSize,
            ),
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Container(
          color: rightColor,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontFamily: 'HermeneusOne',
              fontSize: fontSize,
              color: textColor,
            ),
          ),
        ),
      ),
    ],
  );
}

Future<Position?> _determinePosition(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Location services are disabled.")),
    );
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are denied.")),
      );
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Location permissions are permanently denied. Please enable them in Settings.",
        ),
      ),
    );
    return null;
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}
