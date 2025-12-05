import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Customer/pages/Measurement%20Method/measurement_model.dart';
import 'package:threadhub_system/Customer/pages/appointment_form.dart';

class ProductMeasurementHistory extends StatefulWidget {
  final String customerId;

  const ProductMeasurementHistory({super.key, required this.customerId});

  @override
  State<ProductMeasurementHistory> createState() =>
      _ProductMeasurementHistoryState();
}

class _ProductMeasurementHistoryState extends State<ProductMeasurementHistory> {
  late Future<List<MeasurementRecord>> _measurements;
  final supabase = Supabase.instance.client;
  String? expandedId;
  String? usedMeasurementId;
  Map<String, List<MapEntry<String, String>>> entryLists = {};
  Map<String, int> entryIndex = {};

  @override
  void initState() {
    super.initState();
    _measurements = getCustomerMeasurementHistory(widget.customerId);
  }

  Future<List<MeasurementRecord>> getCustomerMeasurementHistory(
    String customerId,
  ) async {
    final q1 = await FirebaseFirestore.instance
        .collection('Appointment Forms')
        .where('customerId', isEqualTo: customerId)
        .get();

    final q2 = await FirebaseFirestore.instance
        .collection('Appointment Forms')
        .where('toCustomerId', isEqualTo: customerId)
        .get();

    final Map<String, MeasurementRecord> uniqueRecords = {};

    for (var doc in [...q1.docs, ...q2.docs]) {
      final record = MeasurementRecord.fromFirestore(doc);
      uniqueRecords[record.appointmentId] = record;
    }

    return uniqueRecords.values.toList();
  }

  Future<void> markMeasurementAsUsed(String appointmentId) async {
    await FirebaseFirestore.instance
        .collection('Customers')
        .doc(widget.customerId)
        .update({'usedMeasurementId': appointmentId});

    setState(() {
      usedMeasurementId = appointmentId;
    });
  }

  Map<String, Future<String>> imageCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: FutureBuilder<List<MeasurementRecord>>(
            future: _measurements,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No measurements yet."));
              }

              final records = snapshot.data!;
              const SizedBox(height: 12);
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 350.0,
                    height: 60.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'Measurement History',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final m = records[index];

                        final isExpanded = expandedId == m.appointmentId;
                        final isUsed = usedMeasurementId == m.appointmentId;

                        entryLists[m.appointmentId] ??= m.measurements.values
                            .expand((group) => group.entries)
                            .toList();
                        final entries = entryLists[m.appointmentId]!;
                        entryIndex[m.appointmentId] ??= entries.isNotEmpty
                            ? 0
                            : -1;

                        if (entries.isEmpty) return const SizedBox.shrink();
                        final i = entryIndex[m.appointmentId]!.clamp(
                          0,
                          entries.length - 1,
                        );
                        final currentEntry = entries[i];
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                                boxShadow: isUsed
                                    ? [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  FutureBuilder<String>(
                                    future: imageCache[m.appointmentId] ??= m
                                        .getSignedImage(0),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          height: 100,
                                          width: 100,
                                          color: Colors.grey.shade300,
                                        );
                                      }

                                      final img = snapshot.data;
                                      if (img == null || img.isEmpty) {
                                        return const Icon(
                                          Icons.checkroom,
                                          size: 70,
                                          color: Colors.black,
                                        );
                                      }

                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          img,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Used For\n${m.usedFor.toUpperCase()}",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      _styledButton(
                                        text: isExpanded
                                            ? "Hide Details"
                                            : "Details",
                                        onTap: () => setState(
                                          () => expandedId = isExpanded
                                              ? null
                                              : m.appointmentId,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _styledButton(
                                        text: "Used This",
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) {
                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    color: Color(0xFF758694),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        "Do you want to use this measurement?",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            GoogleFonts.jetBrainsMono(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (_) => AppointmentFormPage(
                                                                    customerId:
                                                                        widget
                                                                            .customerId,
                                                                    usedMeasurementId:
                                                                        m.appointmentId,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            style: TextButton.styleFrom(
                                                              backgroundColor:
                                                                  Color(
                                                                    0xFF557A46,
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 8,
                                                                    horizontal:
                                                                        20,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              "Yes",
                                                              style: GoogleFonts.jetBrainsMono(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                          ),

                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(),
                                                            style: TextButton.styleFrom(
                                                              backgroundColor:
                                                                  Color(
                                                                    0xFFD83F31,
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 8,
                                                                    horizontal:
                                                                        20,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              "No",
                                                              style: GoogleFonts.jetBrainsMono(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isExpanded)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F2DE),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Details",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<String>(
                                          future: m.getSignedImage(0),
                                          builder: (context, snapshot) {
                                            final img = snapshot.data;
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child:
                                                  img != null && img.isNotEmpty
                                                  ? Image.network(
                                                      img,
                                                      height: 110,
                                                      width: 110,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      height: 110,
                                                      width: 110,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                        border: Border.all(
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.checkroom,
                                                        size: 50,
                                                      ),
                                                    ),
                                            );
                                          },
                                        ),

                                        const SizedBox(width: 14),

                                        // Measurement Box
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  currentEntry.key
                                                      .toUpperCase(),
                                                  style:
                                                      GoogleFonts.jetBrainsMono(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14,
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  currentEntry.value
                                                      .toUpperCase(),
                                                  style:
                                                      GoogleFonts.jetBrainsMono(
                                                        fontSize: 13,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _navChip(
                                          icon: Icons.arrow_left,
                                          onTap: () {
                                            final list =
                                                entryLists[m.appointmentId]!;
                                            setState(() {
                                              entryIndex[m.appointmentId] =
                                                  (entryIndex[m
                                                          .appointmentId]! -
                                                      1 +
                                                      list.length) %
                                                  list.length;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${entryIndex[m.appointmentId]! + 1}/${entryLists[m.appointmentId]!.length}",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _navChip(
                                          icon: Icons.arrow_right,
                                          onTap: () {
                                            final list =
                                                entryLists[m.appointmentId]!;
                                            setState(() {
                                              entryIndex[m.appointmentId] =
                                                  (entryIndex[m
                                                          .appointmentId]! +
                                                      1) %
                                                  list.length;
                                            });
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Notes
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Notes",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1.3,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        m.notes.isNotEmpty
                                            ? m.notes
                                            : "No notes available",
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _styledButton({required String text, required VoidCallback onTap}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFD9D9D9),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Colors.black, width: 1.4),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _navChip({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1.2),
          color: Colors.white,
        ),
        child: Icon(icon, size: 24, color: Colors.black),
      ),
    );
  }
}
