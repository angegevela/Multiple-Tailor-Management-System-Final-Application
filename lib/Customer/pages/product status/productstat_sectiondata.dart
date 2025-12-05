import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<List<Map<String, String>>>> getProductStatusData(
    String userId,
  ) async {
    final snapshot = await _db
        .collection('Appointment Forms')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    List<Map<String, String>> serviceTypeStatus = [];
    List<Map<String, String>> neededByProductOrder = [];
    List<Map<String, String>> tailorAssignedYield = [];
    List<Map<String, String>> receiptReport = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      serviceTypeStatus.add({
        'Service Type': data['serviceType'] ?? '',
        'Status': data['status'] ?? '',
      });

      neededByProductOrder.add({
        'Needed By Date': data['neededByDate'] ?? '',
        'Product Order': data['productOrder'] ?? '',
      });

      tailorAssignedYield.add({
        'Tailor Assigned': data['tailorAssigned'] ?? '',
        'Yeild ID': data['yieldId'] ?? '',
      });

      receiptReport.add({
        'Receipt': data['receipt'] ?? '',
        'Report': data['report'] ?? '',
      });
    }

    return [
      serviceTypeStatus,
      neededByProductOrder,
      tailorAssignedYield,
      receiptReport,
    ];
  }
}
