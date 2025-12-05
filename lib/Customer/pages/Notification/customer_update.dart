import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UpdateFromTailor extends StatelessWidget {
  final String title;
  final String message;
  final String appointmentId;
  final DateTime timestamp;
  final String customerId;

  const UpdateFromTailor({
    super.key,
    required this.title,
    required this.message,
    required this.appointmentId,
    required this.timestamp,
    required this.customerId,
  });

  Widget _buildInfoCard(String label, String content) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              content,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        title: Text(
          'Tailor Update',
          style: GoogleFonts.chauPhilomeneOne(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFEFEFEF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.amber[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSerifMyanmar(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),


            _buildInfoCard('Appointment ID', appointmentId),
            _buildInfoCard(
              'Received at',
              DateFormat('h:mm a - MMMM d, yyyy').format(timestamp),
            ),
            _buildInfoCard('Customer ID', customerId),
          ],
        ),
      ),
    );
  }
}
