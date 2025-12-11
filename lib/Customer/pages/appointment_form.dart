import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Customer/pages/Measurement%20Method/manual_measurement.dart';
import 'package:threadhub_system/Customer/pages/calendar_appoint.dart';
import 'package:threadhub_system/Customer/pages/customization.dart';
import 'package:threadhub_system/Customer/pages/duedate_product.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'package:threadhub_system/Customer/pages/product%20status/receipt/appointmentdata.dart';
import 'package:threadhub_system/Customer/pages/product%20status/receipt/customer_receipt.dart';
import 'package:path/path.dart' as p;
import 'package:mirai_dropdown_menu/mirai_dropdown_menu.dart';

class AppointmentFormPage extends StatefulWidget {
  final Map<String, Map<String, String>> measurements;
  final String? measurementType;

  final String customerId;
  final String? usedMeasurementId;

  const AppointmentFormPage({
    super.key,
    this.measurements = const {},
    this.measurementType,
    required this.customerId,
    this.usedMeasurementId,
  });
  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

enum MeasurementType { assisted, manual }

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  // Display Selected Appointment Date in Form
  DateTime? appointmentDateTime;
  String? priority;

  // Display Selected Due Date in Form
  DateTime? dueDateTime;
  String? duepriority;

  // Not Empty Measurement Method
  final bool _hasBeenPressed = false;
  MeasurementType? _selectedType;
  String? _errorText;

  // Customization
  String? _customizationDescription;
  List<String> _uploadedImages = [];

  final List<String> _servicesoffered = [
    "Alterations",
    "Custom Tailoring",
    "Repairs",
    "Restyling",
    "Embroidery and Monogramming",
    "Bridal and Formal Wear Alterations",
    "Uniform Tailoring",
    "Garment Resizing",
    "Clothing Dyeing",
    "Custom Design and Alterations",
    "Fitting Assistance",
  ];
  String _selectedService = '';
  final GlobalKey _serviceDropdownKey = GlobalKey();

  // Manual Measurement - Passing Data
  String? _measurementType;
  String? _measurementTypeFromManual;

  @override
  void initState() {
    super.initState();
    _receivedMeasurements = widget.measurements;
    _measurementType = widget.measurementType;

    if (widget.usedMeasurementId != null) {
      _loadUsedMeasurement();
    }
  }

  // Load Old Measurements
  Future<void> _loadUsedMeasurement() async {
    if (widget.usedMeasurementId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("Appointment Forms")
          .doc(widget.usedMeasurementId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final measurements = Map<String, Map<String, String>>.from(
          (data['manualMeasurements'] ?? {}).map(
            (k, v) => MapEntry(k, Map<String, String>.from(v)),
          ),
        );

        setState(() {
          _selectedType = MeasurementType.manual;
          _receivedMeasurements = measurements;
          _measurementTypeFromManual = data['manualMeasurementType'];
        });
      }
    } catch (e) {
      debugPrint("Error loading used measurement: $e");
    }
  }

  // Textfield Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phonenumberController = TextEditingController();
  final TextEditingController _garmentSpecController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phonenumberController.dispose();
    _garmentSpecController.dispose();
    _servicesController.dispose();
    _messageController.dispose();
    _quantityController.dispose();

    super.dispose();
  }

  // Firebase + Supabase Integration
  Future<AppointmentData?> _saveAppointment() async {
    try {
      final supabase = Supabase.instance.client;
      final user = FirebaseAuth.instance.currentUser;

      List<String> uploadedUrls = [];

      // Upload files to Supabase
      for (String filePath in _uploadedImages) {
        final file = File(filePath);
        if (!await file.exists()) {
          debugPrint("File does not exist: $filePath");
          continue;
        }

        final fileName = p.basename(filePath);
        final bucketName = "customers_appointmentfile";
        final storagePath =
            "appointments/${DateTime.now().millisecondsSinceEpoch}_$fileName";

        await supabase.storage.from(bucketName).upload(storagePath, file);

        final publicUrl = supabase.storage
            .from(bucketName)
            .getPublicUrl(storagePath);
        uploadedUrls.add(publicUrl);
      }

      final docRef = FirebaseFirestore.instance
          .collection("Appointment Forms")
          .doc();

      final appointmentData = AppointmentData(
        appointmentId: docRef.id,
        fullName: _fullNameController.text,
        phoneNumber: int.tryParse(_phonenumberController.text.trim()),
        garmentSpec: _garmentSpecController.text,
        services: _servicesController.text,
        quantity: int.tryParse(_quantityController.text),
        customizationDescription: _customizationDescription,
        uploadedImages: uploadedUrls,
        message: _messageController.text,
        appointmentDateTime: appointmentDateTime,
        priority: priority,
        dueDateTime: dueDateTime,
        duepriority: duepriority,
        measurementMethod: _selectedType == MeasurementType.assisted
            ? "Assisted"
            : _selectedType == MeasurementType.manual
            ? "Manual"
            : null,
        manualMeasurements: _receivedMeasurements.isNotEmpty
            ? _receivedMeasurements
            : null,
        manualMeasurementType: _measurementTypeFromManual,
        customerId: user?.uid ?? "unknown",
        tailorId: null,
        tailorAssigned: null,
      );
      if (!RegExp(r'^[0-9]+$').hasMatch(_phonenumberController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Phone number should contain numbers only."),
          ),
        );
        return null;
      }
      await docRef.set(appointmentData.toMap());

      return appointmentData;
    } catch (e) {
      debugPrint("Error saving appointment: $e");
      return null;
    }
  }

  Map<String, Map<String, String>> _receivedMeasurements = {};
  bool _isloading = false;
  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6082B6),
        title: Text(
          'Appointment Booking Form',
          style: GoogleFonts.notoSerifOldUyghur(
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      body: Scaffold(
        backgroundColor: const Color(0xFFEEEEEE),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Schedule Your Appointment Today',
                    style: GoogleFonts.medulaOne(
                      // fontSize: fontSize,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Full Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Enter your Full Name',
                          contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Phone Number TextField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phonenumberController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'e.g 09012345678',
                          contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),
                // Garment Specification
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garment Specification',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _garmentSpecController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'e.g cargo pants, dresses, etc.',
                          contentPadding: EdgeInsets.fromLTRB(18, 22, 48, 2),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                // Quantity Of the Product
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity Of The Product',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter quantity",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.fromLTRB(
                            18,
                            22,
                            48,
                            2,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),
                // Service/s availment
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service/s',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MiraiDropDownMenu<String>(
                        child: Container(
                          key: _serviceDropdownKey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedService.isEmpty
                                    ? 'Select a Service'
                                    : _selectedService,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.black87,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        children: _servicesoffered,
                        valueNotifier: ValueNotifier<String>(
                          _selectedService ?? '',
                        ),

                        onChanged: (value) {
                          setState(() {
                            _selectedService = value;
                            _servicesController.text = value;
                          });
                        },
                        radius: 15,
                        maxHeight: 300,
                        showSearchTextField: true,
                        selectedItemBackgroundColor: Color(0xFF628141),
                        itemWidgetBuilder:
                            (index, item, {isItemSelected = false}) {
                              final String displayText = item ?? '';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                color: isItemSelected
                                    ? Color(0xFF628141)
                                    : Colors.transparent,
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: isItemSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: isItemSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customization Options',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 45,
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "More Options",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: fontSize,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 145),
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_right_alt,
                                color: Colors.black,
                                size: 25,
                              ),
                              onPressed: () async {
                                final customizationData = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CustomizationPage(),
                                  ),
                                );

                                if (customizationData != null) {
                                  setState(() {
                                    _customizationDescription =
                                        customizationData["description"];
                                    _uploadedImages =
                                        customizationData["files"];
                                  });
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_customizationDescription != null ||
                    _uploadedImages.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9DC),
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_customizationDescription != null &&
                              _customizationDescription!.isNotEmpty)
                            Text(
                              "Customization: $_customizationDescription",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (_customizationDescription != null &&
                              _customizationDescription!.isNotEmpty)
                            const SizedBox(height: 8),

                          if (_uploadedImages.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _uploadedImages.map((path) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.zero,
                                  child: Image.file(
                                    File(path),
                                    width: 140,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 10),

                // Message Textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        padding: EdgeInsets.all(8),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Enter any additional messages here',
                            border: InputBorder.none,
                          ),
                          maxLines: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),
                //Select Date and Time for Appointment and Product
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Date and Time',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ElevatedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                insetPadding: EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                backgroundColor: Colors.transparent,
                                child: SingleChildScrollView(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.95,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(15.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Is this date and time for :',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();

                                                  final result =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CalendarHome(),
                                                        ),
                                                      );
                                                  if (result != null &&
                                                      result
                                                          is Map<
                                                            String,
                                                            dynamic
                                                          >) {
                                                    DateTime
                                                    selectedAppointment =
                                                        result['appointmentDateTime'];

                                                    if (dueDateTime != null &&
                                                        selectedAppointment
                                                            .isAfter(
                                                              dueDateTime!,
                                                            )) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Appointment date cannot be after the due date.",
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    setState(() {
                                                      appointmentDateTime =
                                                          selectedAppointment;
                                                      priority =
                                                          result['priority'];
                                                    });
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(
                                                    0xFF90C3D4,
                                                  ),
                                                  shape: StadiumBorder(),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Appointment',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              DueDateProductPage(),
                                                        ),
                                                      );
                                                  if (result != null &&
                                                      result
                                                          is Map<
                                                            String,
                                                            dynamic
                                                          >) {
                                                    setState(() {
                                                      dueDateTime =
                                                          result['dueDateTime'];
                                                      duepriority =
                                                          result['duepriority'];
                                                    });
                                                  }
                                                },

                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(
                                                    0xFF90C3D4,
                                                  ),
                                                  shape: StadiumBorder(),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                    vertical: 3,
                                                  ),
                                                ),
                                                child: FittedBox(
                                                  child: Text(
                                                    'Due Date of your \n Product',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                      fontSize: fontSize,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 45),
                          backgroundColor: const Color(0xFF6082B6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Select',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      //Show Appointment Date if set
                      if (appointmentDateTime != null && priority != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Confirmed Appointment:',
                                  style: TextStyle(
                                    fontFamily: 'JainiPurva',
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 205,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          DateFormat(
                                            'MMMM d, y, h:mm a',
                                          ).format(appointmentDateTime!),
                                          style: GoogleFonts.chathura(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: Text(
                                        '$priority Priority',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.chathura(
                                          color: priority == 'High'
                                              ? Color(0xFFBF360C)
                                              : priority == 'Medium'
                                              ? Colors.orange
                                              : Colors.green,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 29,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      //Show Product Due Date if set
                      if (dueDateTime != null && duepriority != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Due Date:',
                                  style: TextStyle(
                                    fontFamily: 'JainiPurva',
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 205,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          DateFormat(
                                            'MMMM d, y, h:mm a',
                                          ).format(dueDateTime!),
                                          style: GoogleFonts.chathura(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: Text(
                                        '$duepriority Priority',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.chathura(
                                          color: duepriority == 'High'
                                              ? Color(0xFFBF360C)
                                              : duepriority == 'Medium'
                                              ? Colors.orange
                                              : Colors.green,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 29,
                                        ),
                                      ),
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

                //Measurement Input Method Choices
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Measurement input method:",
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (_selectedType ==
                                      MeasurementType.assisted) {
                                    _selectedType = null;
                                  } else {
                                    _selectedType = MeasurementType.assisted;
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor:
                                    _selectedType == MeasurementType.assisted
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color:
                                        _selectedType ==
                                            MeasurementType.assisted
                                        ? Colors.blue.withOpacity(0.3)
                                        : const Color(0xFF6082B6),
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Assisted\nMeasurement',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _selectedType == MeasurementType.assisted
                                      ? const Color(0xFF6082B6).withOpacity(0.5)
                                      : const Color(0xFF6082B6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManualMeasurement(),
                                  ),
                                );

                                if (result != null &&
                                    result is Map<String, dynamic>) {
                                  setState(() {
                                    _selectedType = MeasurementType.manual;
                                    _receivedMeasurements =
                                        result["measurements"] ?? {};
                                    _measurementTypeFromManual =
                                        result["type"] ?? "";
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor:
                                    _selectedType == MeasurementType.manual
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color:
                                        _selectedType == MeasurementType.manual
                                        ? Colors.blue.withOpacity(0.3)
                                        : const Color(0xFF6082B6),
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                '  Enter\nManually',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == MeasurementType.manual
                                      ? const Color(0xFF6082B6).withOpacity(0.5)
                                      : const Color(0xFF6082B6),
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_receivedMeasurements.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 5,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9DC),
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    "Saved Measurements",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                if (_measurementTypeFromManual != null &&
                                    _measurementTypeFromManual!.isNotEmpty)
                                  Center(
                                    child: Text(
                                      "Measurement Type: $_measurementTypeFromManual",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 8),

                                ..._receivedMeasurements.entries.map((entry) {
                                  return Text(
                                    "${entry.key}: ${entry.value.entries.map((e) => "${e.key} - ${e.value}").join(", ")}",
                                    style: const TextStyle(fontSize: 14),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isloading
                            ? null
                            : () async {
                                if (_fullNameController.text.isEmpty ||
                                    _phonenumberController.text.isEmpty ||
                                    _garmentSpecController.text.isEmpty ||
                                    _servicesController.text.isEmpty ||
                                    _selectedType == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please fill in all required fields.",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isloading = true);

                                try {
                                  final appointmentData =
                                      await _saveAppointment();

                                  if (appointmentData != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReceiptPage(data: appointmentData),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Failed to save appointment. Try again later.",
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  setState(() => _isloading = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6082B6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isloading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'Confirm',
                                style: GoogleFonts.cormorantSc(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
