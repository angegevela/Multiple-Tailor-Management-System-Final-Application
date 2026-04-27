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
  final String? status;

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
    this.status,
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
      "status": status,
    };
  }

  static AppointmentData fromMap(Map<String, dynamic> map, {String? docId}) {
    return AppointmentData(
      appointmentId: docId ?? map['appointmentId']?.toString() ?? '',

      fullName: map['fullName']?.toString() ?? '',

      phoneNumber: map['phoneNumber'] is int
          ? map['phoneNumber']
          : int.tryParse(map['phoneNumber']?.toString() ?? ''),

      garmentSpec: map['garmentSpec']?.toString() ?? '',
      services: map['services']?.toString() ?? '',

      customizationDescription: map['customizationDescription']?.toString(),

      uploadedImages: map['uploadedImages'] != null
          ? List<String>.from(
              (map['uploadedImages'] as List).map((e) => e.toString()),
            )
          : [],

      message: map['message']?.toString() ?? '',

      appointmentDateTime: map['appointmentDateTime'] is Timestamp
          ? (map['appointmentDateTime'] as Timestamp).toDate()
          : null,

      priority: map['priority']?.toString(),

      dueDateTime: map['dueDateTime'] is Timestamp
          ? (map['dueDateTime'] as Timestamp).toDate()
          : null,

      duepriority: map['duepriority']?.toString(),

      measurementMethod: map['measurementMethod']?.toString(),

      manualMeasurements: map['manualMeasurements'] != null
          ? Map<String, Map<String, String>>.from(
              (map['manualMeasurements'] as Map).map(
                (k, v) => MapEntry(
                  k.toString(),
                  Map<String, String>.from(
                    (v as Map).map(
                      (a, b) => MapEntry(a.toString(), b.toString()),
                    ),
                  ),
                ),
              ),
            )
          : null,

      manualMeasurementType: map['manualMeasurementType']?.toString(),

      customerId: map['customerId']?.toString() ?? '',

      tailorId: map['tailorId']?.toString(),

      tailorAssigned: map['tailorAssigned']?.toString(),

      quantity: map['quantity'] is int
          ? map['quantity']
          : int.tryParse(map['quantity']?.toString() ?? ''),

      customerLocation: map['customerLocation'] is GeoPoint
          ? map['customerLocation']
          : null,

      status: map['status']?.toString(),
    );
  }

  factory AppointmentData.fromFirestore(DocumentSnapshot doc) {
    return AppointmentData.fromMap(
      doc.data() as Map<String, dynamic>,
      docId: doc.id,
    );
  }

  String get dateStr => appointmentDateTime != null
      ? "${appointmentDateTime!.year}-${appointmentDateTime!.month.toString().padLeft(2, '0')}-${appointmentDateTime!.day.toString().padLeft(2, '0')}"
      : "No Date";
}
