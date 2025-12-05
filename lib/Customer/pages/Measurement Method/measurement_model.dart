import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MeasurementRecord {
  final String appointmentId;
  final String usedFor;
  final List<String> imageUrls;
  final String measurementMethod;
  final Map<String, Map<String, String>> measurements;
  final String notes;

  MeasurementRecord({
    required this.appointmentId,
    required this.usedFor,
    required this.imageUrls,
    required this.measurementMethod,
    required this.measurements,
    required this.notes,
  });

  static final supabase = Supabase.instance.client;

  /// ✅ Converts stored Supabase STORAGE PATH → Signed URL for private access
  static Future<String> _generateSignedUrl(String path) async {
    try {
      final signedUrl = await supabase.storage
          .from("customers_appointmentfile")
          .createSignedUrl(path, 60 * 60); // 1 hour
      return signedUrl;
    } catch (_) {
      return "";
    }
  }

  factory MeasurementRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<String> storedPaths = [];

    if (data['uploadedImages'] != null && data['uploadedImages'] is List) {
      storedPaths = List<String>.from(data['uploadedImages'])
          .map(
            (e) => e.replaceAll(
              "https://lyoarnvbiegjplqbakyg.supabase.co/storage/v1/object/public/customers_appointmentfile/",
              "",
            ),
          )
          .toList();
    }

    final raw =
        (data['manualMeasurements'] ?? data['assistedMeasurements'] ?? {})
            as Map<dynamic, dynamic>;

    final Map<String, Map<String, String>> formattedMeasurements = {};

    raw.forEach((part, fields) {
      if (fields is Map) {
        formattedMeasurements[part.toString()] = fields.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
      }
    });

    return MeasurementRecord(
      appointmentId: data['appointmentId']?.toString() ?? doc.id,
      usedFor: data['garmentSpec']?.toString() ?? "Unknown Garment",

      imageUrls: storedPaths,

      measurementMethod: data['measurementMethod']?.toString() ?? "Unknown",
      measurements: formattedMeasurements,
      notes:
          (data['customizationDescription']?.toString().trim().isEmpty ?? true)
          ? "No notes available"
          : data['customizationDescription'].toString(),
    );
  }

  Future<String> getSignedImage(int index) async {
    if (imageUrls.isEmpty || index >= imageUrls.length) return "";
    return await _generateSignedUrl(imageUrls[index]);
  }
}
