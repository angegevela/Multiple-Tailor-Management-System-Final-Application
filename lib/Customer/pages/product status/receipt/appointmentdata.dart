import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentData {
  final String appointmentId;
  final String fullName;
  final int? phoneNumber;
  final String garmentSpec;
  final String services;
  final String? customizationDescription;
  final List<String> uploadedImages;
  final String message;
  final DateTime? appointmentDateTime;
  final String? priority;
  final DateTime? dueDateTime;
  final String? duepriority;
  final String? measurementMethod;
  final Map<String, Map<String, String>>? manualMeasurements;
  final String? manualMeasurementType;
  final String customerId;
  final String? tailorId;
  final double? price;
  final String? tailorAssigned;
  final int? quantity;
  final GeoPoint? customerLocation;

  AppointmentData({
    required this.appointmentId,
    required this.fullName,
    required this.phoneNumber,
    required this.garmentSpec,
    required this.services,
    this.customizationDescription,
    this.uploadedImages = const [],
    required this.message,
    this.appointmentDateTime,
    this.priority,
    this.dueDateTime,
    this.duepriority,
    this.measurementMethod,
    this.manualMeasurements,
    this.manualMeasurementType,
    required this.customerId,
    this.tailorId,
    this.price,
    required this.tailorAssigned,
    this.quantity,
    this.customerLocation,
  });

  Map<String, dynamic> toMap() {
    return {
      "appointmentId": appointmentId,
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "garmentSpec": garmentSpec,
      "services": services,
      "customizationDescription": customizationDescription,
      "uploadedImages": uploadedImages,
      "message": message,
      "appointmentDateTime": appointmentDateTime != null
          ? Timestamp.fromDate(appointmentDateTime!)
          : null,
      "priority": priority,
      "dueDateTime": dueDateTime != null
          ? Timestamp.fromDate(dueDateTime!)
          : null,
      "duepriority": duepriority,
      "measurementMethod": measurementMethod,
      "manualMeasurements": manualMeasurements,
      "manualMeasurementType": manualMeasurementType,
      "customerId": customerId,
      "tailorId": tailorId,
      "tailorAssigned": tailorAssigned,
      "quantity": quantity,
      "customerLocation": customerLocation,
    };
  }

  static AppointmentData fromMap(Map<String, dynamic> map) {
    return AppointmentData(
      appointmentId: map['appointmentId'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      garmentSpec: map['garmentSpec'] ?? '',
      services: map['services'] ?? '',
      customizationDescription: map['customizationDescription'],
      uploadedImages: map['uploadedImages'] != null
          ? List<String>.from(map['uploadedImages'])
          : [],
      message: map['message'] ?? '',
      appointmentDateTime: map['appointmentDateTime'] is Timestamp
          ? (map['appointmentDateTime'] as Timestamp).toDate()
          : null,
      priority: map['priority'],
      dueDateTime: map['dueDateTime'] is Timestamp
          ? (map['dueDateTime'] as Timestamp).toDate()
          : null,
      duepriority: map['duepriority'],
      measurementMethod: map['measurementMethod'],
      manualMeasurements: map['manualMeasurements'] != null
          ? Map<String, Map<String, String>>.from(
              (map['manualMeasurements'] as Map).map(
                (k, v) => MapEntry(k, Map<String, String>.from(v)),
              ),
            )
          : null,
      manualMeasurementType: map['manualMeasurementType'],
      customerId: map['customerId'] ?? '',
      tailorId: map['tailorId'],
      tailorAssigned: map['tailorAssigned'] as String?,
      quantity: map['quantity'] != null
          ? (map['quantity'] as num).toInt()
          : null,
      customerLocation: map['customerLocation'] is GeoPoint
          ? map['customerLocation'] as GeoPoint
          : null,
    );
  }

  factory AppointmentData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentData.fromMap(data);
  }

  String get dateStr => appointmentDateTime != null
      ? "${appointmentDateTime!.year}-${appointmentDateTime!.month.toString().padLeft(2, '0')}-${appointmentDateTime!.day.toString().padLeft(2, '0')}"
      : "No Date";
}
