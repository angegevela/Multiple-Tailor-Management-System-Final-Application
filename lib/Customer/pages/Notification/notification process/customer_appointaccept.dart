import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:threadhub_system/Customer/pages/Notification/customer_notification.dart';
import 'package:threadhub_system/Customer/pages/product%20status/product_status.dart';

class UpdatedAppointmentPage extends StatefulWidget {
  final String appointmentId;
  final String customerId;

  const UpdatedAppointmentPage({
    super.key,
    required this.appointmentId,
    required this.customerId,
  });

  @override
  State<UpdatedAppointmentPage> createState() => _UpdatedAppointmentPageState();
}

class _UpdatedAppointmentPageState extends State<UpdatedAppointmentPage> {
  Map<String, dynamic>? appointmentData;
  Map<String, dynamic>? tailorData;
  bool loading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  Future<void> _fetchData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snap = await firestore
          .collection('Appointment Forms')
          .doc(widget.appointmentId)
          .get();
      if (!snap.exists) return;

      final data = snap.data()!;
      String tailorId = data['tailorId'] ?? '';
      String currentStatus = data['status'] ?? 'Pending';


      if (currentStatus == 'Declined') {
        final availableTailors = await firestore
            .collection('Users')
            .where('role', isEqualTo: 'tailor')
            .where('available', isEqualTo: true)
            .limit(1)
            .get();

        if (availableTailors.docs.isNotEmpty) {
          tailorId = availableTailors.docs.first.id;

  
          await firestore
              .collection('Appointment Forms')
              .doc(widget.appointmentId)
              .update({
                'tailorId': tailorId,
                'status': 'Pending',
                'customerstatus': 'Pending',
              });

          data['tailorId'] = tailorId;
          data['status'] = 'Pending';
          data['customerstatus'] = 'Pending';
        }
      }


      Map<String, dynamic>? tailor;
      if (tailorId.isNotEmpty) {
        final tailorSnap = await firestore
            .collection('Users')
            .doc(tailorId)
            .get();
        tailor = tailorSnap.data();
      }

      setState(() {
        appointmentData = data;
        tailorData = tailor;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint('Error fetching appointment: $e');
    }
  }

  String formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'N/A';
    return DateFormat('MMMM dd, yyyy – hh:mm a').format(ts.toDate());
  }

  Future<void> _processAppointment(bool accepted) async {
    if (appointmentData == null) return;

    final firestore = FirebaseFirestore.instance;
    final now = Timestamp.now();
    final appointmentRef = firestore
        .collection('Appointment Forms')
        .doc(widget.appointmentId);

    final tailorId = appointmentData!['tailorId'] ?? '';

    setState(() => _isProcessing = true);
    try {

      await appointmentRef.update({
        'status': accepted ? 'Accepted' : 'Declined',
        'customerstatus': accepted ? 'Accepted' : 'Declined',
        'updatedAt': now,
      });


      setState(() {
        appointmentData!['status'] = accepted ? 'Accepted' : 'Declined';
        appointmentData!['customerstatus'] = accepted ? 'Accepted' : 'Declined';
      });

      final notificationsRef = firestore.collection('notifications');

      if (widget.customerId.isNotEmpty) {
        await notificationsRef.add({
          'recipientType': 'customer',
          'recipientId': widget.customerId,
          'title': accepted ? 'Appointment Accepted' : 'Appointment Declined',
          'body': accepted
              ? 'Your appointment request was accepted.'
              : 'Your appointment request was declined.',
          'readBy': [],
          'timestamp': FieldValue.serverTimestamp(),
          'appointmentId': widget.appointmentId,
        });
      }

      if (tailorId.isNotEmpty) {
        await notificationsRef.add({
          'recipientType': 'tailor',
          'recipientId': tailorId,
          'title': accepted
              ? 'Customer Accepted Appointment'
              : 'Customer Declined Appointment',
          'body': accepted
              ? 'Your customer accepted the appointment.'
              : 'Your customer declined the appointment.',
          'readBy': [],
          'timestamp': FieldValue.serverTimestamp(),
          'appointmentId': widget.appointmentId,
        });
      }
      if (accepted && tailorId.isNotEmpty) {
        final tailorDoc = await firestore
            .collection('Users')
            .doc(tailorId)
            .get();
        if (tailorDoc.exists) {
          final tailorInfo = tailorDoc.data()!;
          final int maxPerDay = (tailorInfo['maxCustomersPerDay'] ?? 3) as int;

          final acceptedQuery = await firestore
              .collection('Appointment Forms')
              .where('tailorId', isEqualTo: tailorId)
              .where('status', isEqualTo: 'Accepted')
              .get();

          if (acceptedQuery.docs.length > maxPerDay) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This tailor has no more available slots for today. Please try another tailor.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Appointment accepted successfully!'
                : 'Appointment declined successfully!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: accepted ? Colors.green : Colors.red,
        ),
      );

      if (accepted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductStatusPage(customerId: widget.customerId),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerNotification(customerId: widget.customerId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing appointment: $e');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Failed to process appointment:\n$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildTableSection(String title, List<List<dynamic>> rows) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black26, width: 0.8),
            ),
            child: Column(
              children: rows.map((row) {
                final label = row[0] as String;
                final value = row[1] ?? "Not Provided";
                final valueColor = row.length > 2
                    ? row[2] as Color
                    : Colors.black;

                return IntrinsicHeight(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black26, width: 0.6),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            color: const Color(0xFFE8F3FF),
                            alignment: Alignment.topLeft,
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            alignment: Alignment.topLeft,
                            child: Text(
                              value.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: valueColor,
                                height: 1.4,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (appointmentData == null) {
      return const Scaffold(
        body: Center(child: Text('Appointment not found.')),
      );
    }

    final data = appointmentData!;
    final tailor = tailorData;

    List<List<dynamic>> customerRows = [
      ["Full Name", data['fullName'] ?? 'N/A'],
      ["Phone Number", data['phoneNumber'] ?? 'N/A'],
    ];

    List<List<dynamic>> serviceRows = [
      ["Service", data['services'] ?? 'N/A'],
      ["Garment", data['garmentSpec'] ?? 'N/A'],
      ["Measurement Method", data['measurementMethod'] ?? 'N/A'],
      if (data['customizationDescription'] != null &&
          data['customizationDescription'].toString().isNotEmpty)
        ["Customization", data['customizationDescription']],
    ];

    List<List<dynamic>> appointmentRows = [
      ["Appointment Date", formatTimestamp(data['appointmentDateTime'])],
      ["Due Date", formatTimestamp(data['dueDateTime'])],
      [
        "Priority",
        data['priority'] ?? 'N/A',
        getPriorityColor(data['priority'] ?? ''),
      ],
      ["Status", data['status'] ?? 'N/A'],
    ];

    List<List<dynamic>> tailorRows = [];
    if (tailor != null) {
      tailorRows = [
        ["Shop Name", tailor['shopName'] ?? 'N/A'],
        if (data['tailorMessage'] != null)
          ["Tailor Message", (data['tailorMessage'] as List).join(', ')],
        if (data['tailorPrice'] != null)
          ["Tailor Price", data['tailorPrice'].toString()],
        if (data['tailorAssigned'] != null)
          ["Tailor Assigned", data['tailorAssigned'].toString()],
      ];
    }

    // Show buttons if status is Pending or Waiting Customer Response
    final showActionButtons =
        data['status'] == 'Pending' ||
        data['status'] == 'Waiting Customer Response';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            _buildTableSection("Customer Details", customerRows),
            _buildTableSection("Service Details", serviceRows),
            _buildTableSection("Appointment Information", appointmentRows),
            if (tailorRows.isNotEmpty)
              _buildTableSection("Tailor Information", tailorRows),
            const SizedBox(height: 16),
            if (showActionButtons)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _processAppointment(false),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Decline",
                                style: GoogleFonts.creteRound(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8A2D3B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _processAppointment(true),
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Accept This",
                                style: GoogleFonts.creteRound(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6082B6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
