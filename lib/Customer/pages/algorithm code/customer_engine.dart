import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class TailorMatcher {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> findTailorsForAppointment({
    required String service,
    required GeoPoint customerLocation,
    double radiusKm = 2.0,
    DateTime? appointmentDate,
    String? customerAddress,
  }) async {
    final DateTime targetDate = appointmentDate ?? DateTime.now();
    final String requestedDay = DateFormat('EEEE').format(targetDate);
    final String requestedDateStr = DateFormat('yyyy-MM-dd').format(targetDate);

    String customerStreet = customerAddress?.toLowerCase() ?? '';

    if (customerStreet.isEmpty) {
      try {} catch (e) {
        print('Error getting customer street: $e');
        return [];
      }
    }

    final snapshot = await _db
        .collection('Users')
        .where('availability.isAvailable', isEqualTo: true)
        .get();

    final String requestedService = service.trim().toLowerCase();
    List<Map<String, dynamic>> matches = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final availability = data['availability'];

      // Check if tailor offers the requested service
      final List<String> offeredServices =
          ((availability['servicesOffered'] as List<dynamic>?) ?? [])
              .map((s) => s.toString().toLowerCase().trim())
              .toList();
      if (!offeredServices.contains(requestedService)) continue;

      // Check if tailor has location
      final GeoPoint? loc = data['location'];
      if (loc == null) continue;

      // Calculate distance
      final double distance =
          Geolocator.distanceBetween(
            customerLocation.latitude,
            customerLocation.longitude,
            loc.latitude,
            loc.longitude,
          ) /
          1000.0;
      if (distance > radiusKm) continue;

      final String tailorAddress =
          (data['address'] ?? data['fullAddress'] ?? '')
              .toString()
              .toLowerCase();

      if (customerStreet.isNotEmpty && tailorAddress.isNotEmpty) {
        final customerWords = customerStreet
            .split(RegExp(r'[ ,]'))
            .where((w) => w.isNotEmpty)
            .toList();
        final tailorWords = tailorAddress
            .split(RegExp(r'[ ,]'))
            .where((w) => w.isNotEmpty)
            .toList();

        final hasMatch = customerWords.any(
          (word) => tailorWords.contains(word),
        );

        if (!hasMatch) continue;
      }

      final List<String> days = ((availability['days'] ?? []) as List<dynamic>)
          .map((d) => d.toString().toLowerCase())
          .toList();
      if (days.isNotEmpty && !days.contains(requestedDay.toLowerCase()))
        continue;

      final int maxCustomers = availability['maxCustomersPerDay'] ?? 999;
      final existingBookings = await _db
          .collection('Appointment Forms')
          .where('tailorId', isEqualTo: doc.id)
          .where('appointmentDate', isEqualTo: requestedDateStr)
          .get();
      if (existingBookings.docs.length >= maxCustomers) continue;

      List<Map<String, dynamic>> reviews = [];

      matches.add({
        ...data,
        'id': doc.id,
        'distance': distance,
        'street': tailorAddress,
      });
    }

    matches.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    return matches;
  }
}
