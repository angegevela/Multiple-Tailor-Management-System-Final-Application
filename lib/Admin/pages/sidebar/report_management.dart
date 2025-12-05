import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Admin/pages/sidebar/admin_reportdetails/admincard_report.dart';
import 'package:threadhub_system/Admin/pages/sidebar/menu.dart';

class ReportManagementPage extends StatefulWidget {
  const ReportManagementPage({super.key});

  @override
  State<ReportManagementPage> createState() => _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage> {
  Color getStatusColor(String status) {
    switch (status) {
      case "No Action Yet":
        return Colors.red;
      case "Pending Approval":
        return Colors.orange;
      case "Completed":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  final List<Color> cardColors = [
    const Color(0xFF6D9886),
    const Color(0xFFE4EFE7),
    const Color(0xFF79B4B7),
    const Color(0xFFA4B787),
    const Color(0xFF30475E),
    const Color(0xFF4F8A8B),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF6082B6)),
      drawer: const Menu(),
      backgroundColor: Color(0xFFD9D9D9),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Reports')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No reports available.'));
            }

            final reports = snapshot.data!.docs;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.45,
              ),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final data = reports[index].data() as Map<String, dynamic>;
                final String reportee = data['reporteeName'] ?? 'Unknown';
                final String respondent = data['respondentName'] ?? 'N/A';
                final String status = data['status'] ?? "No Action Yet";

                return InkWell(

                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 160,
                          color: cardColors[index % cardColors.length],
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "Reportee: $reportee",
                                      style: GoogleFonts.robotoMono(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Respondent: $respondent",
                                      style: GoogleFonts.robotoMono(
                                        fontWeight: FontWeight.w700,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Status: $status",
                                      style: GoogleFonts.robotoMono(
                                        color: getStatusColor(status),
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.info),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReportDetailPage(report: data),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('Reports')
                                            .doc(reports[index].id)
                                            .delete();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
