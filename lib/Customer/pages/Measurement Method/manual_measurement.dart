import 'package:body_part_selector/body_part_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Customer/pages/Measurement%20Method/measurement_history.dart';
import 'package:threadhub_system/Customer/pages/help.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ManualMeasurement extends StatefulWidget {
  const ManualMeasurement({super.key});
  @override
  State<ManualMeasurement> createState() => _ManualMeasurementState();
}

class _ManualMeasurementState extends State<ManualMeasurement> {
  BodyParts bodyParts = const BodyParts();
  var selectedparts = [];

  Map<String, Map<String, String>> measurements = {};

  Map<String, TextEditingController> controllers = {};
  String? customerId;

  final Map<String, List<String>> measurementFields = {
    //Upper Body
    "Neck": ["Circumference"],
    "Arm": ["Length", "Circumference"],
    "Forearm": ["Length", "Circumference"],
    "Wrist": ["Circumference"],
    "Chest": ["Width", "Circumference"],
    "Shoulder": ["Width"],
    "Torso": ["Length", "Circumference"],
    "Bicep": ["Circumference"],
    "Back": ["Length"],

    //Lower Body
    "Leg": ["Length"],
    "Waist": ["Circumference"],
    "Thigh": ["Length", "Circumference"],
    "Knee": ["Circumference"],
    "Crus": ["Length", "Circumference"],
    "Hip": ["Circumference"],
    "Ankle": ["Circumference"],
    "Calf": ["Circumference"],
    "Inseam": ["Length"],
  };

  String? currentPart;
  String? selectedMeasurementType;

  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController circumferenceController = TextEditingController();

  Future<void> saveMeasurements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('measurements', jsonEncode(measurements));
  }

  Future<void> loadMeasurements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('measurements');
    if (data != null) {
      setState(() {
        measurements = Map<String, Map<String, String>>.from(
          jsonDecode(
            data,
          ).map((k, v) => MapEntry(k, Map<String, String>.from(v))),
        );
      });
    }
  }

  Future<void> clearSavedMeasurement() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('measurements');
  }

  @override
  void initState() {
    super.initState();
    loadMeasurements();
    _loadCustomerId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNoticeDialog();
    });
  }

  void _loadCustomerId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        customerId = user.uid;
      });
    }
  }

  void _showNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/gif/manualmeasure.gif",
                height: 120,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome!",
                style: GoogleFonts.b612(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            "Please select a body part and input your measurements. You can also input data in the needed textfield, leaving the other empty.",
            textAlign: TextAlign.center,
            style: GoogleFonts.b612(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Got it",
                style: GoogleFonts.b612(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Center(
                child: Text(
                  "Two-Dimensional Body",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),

              // 3D Body Selector
              SizedBox(
                height: 400,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: BodyPartSelectorTurnable(
                      bodyParts: bodyParts,
                      onSelectionUpdated: (p) => setState(() {
                        bodyParts = p;
                        selectedparts = p
                            .toMap()
                            .entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList();
                        if (selectedparts.isNotEmpty) {
                          currentPart = selectedparts.last;
                          controllers.clear();
                          for (var field
                              in measurementFields[currentPart] ?? []) {
                            controllers[field] = TextEditingController();
                          }
                        }
                      }),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                hint: Text(
                  "PICK A MEASUREMENT TYPE",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                value: selectedMeasurementType,
                items: ["Inches", "Centimeters", "Meter"]
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMeasurementType = value;
                  });
                },
                validator: (value) =>
                    value == null ? "Please select a type" : null,
              ),

              const SizedBox(height: 10),
              if (currentPart != null) ...[
                Text(
                  "Measurements for $currentPart",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...?measurementFields[currentPart]?.map((field) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: TextField(
                      controller: controllers[field],
                      decoration: InputDecoration(
                        labelText: field,
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  );
                }),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: lengthController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Enter Length",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: widthController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Enter Width",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: circumferenceController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Enter Circumference",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),

              SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        if (currentPart == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a body part."),
                            ),
                          );
                          return;
                        }

                        if (selectedMeasurementType == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please pick a measurement type."),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          measurements[currentPart!] = {
                            for (var f in measurementFields[currentPart] ?? [])
                              f: controllers[f]?.text.trim() ?? "",

                            if (lengthController.text.trim().isNotEmpty)
                              "Length": lengthController.text.trim(),
                            if (widthController.text.trim().isNotEmpty)
                              "Width": widthController.text.trim(),
                            if (circumferenceController.text.trim().isNotEmpty)
                              "Circumference": circumferenceController.text
                                  .trim(),
                          };

                          for (var controller in controllers.values) {
                            controller.clear();
                          }
                          lengthController.clear();
                          widthController.clear();
                          circumferenceController.clear();

                          currentPart = null;
                          controllers.clear();
                        });

                        saveMeasurements();
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: GoogleFonts.lisuBosa(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      child: const Text("Save"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          measurements.clear();
                        });

                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.remove('measurements');
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: GoogleFonts.lisuBosa(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      child: Text("Remove All"),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),
              Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerHelpPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF7E99A3),
                          child: Icon(
                            Icons.menu_book,
                            size: 20,
                            color: const Color(0xFF292D32),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        final user = FirebaseAuth.instance.currentUser;

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please sign in first."),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductMeasurementHistory(customerId: user.uid),
                          ),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF7E99A3),
                          child: Icon(
                            Icons.bookmark_border_rounded,
                            size: 20,
                            color: const Color(0xFF292D32),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),
              if (measurements.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "Saved Measurements",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (selectedMeasurementType != null)
                  Text(
                    "Measurement Type: $selectedMeasurementType",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ...measurements.entries.map((entry) {
                  final formattedValues = entry.value.entries
                      .map((e) => "${e.value} (${e.key})")
                      .join("   ");

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Flexible(
                            child: Text(
                              formattedValues,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              SizedBox(height: 10),
              Align(
                child: Row(
                  children: [
                    //Cancel Button
                    ElevatedButton(
                      onPressed: () {
                        // if (controllers.values.any((c) => c.text.isNotEmpty) ||
                        //     lengthController.text.isNotEmpty ||
                        //     widthController.text.isNotEmpty ||
                        //     circumferenceController.text.isNotEmpty) {
                        //   showDialog(
                        //     context: context,
                        //     builder: (context) => AlertDialog(
                        //       title: const Text("Discard unsaved input?"),
                        //       content: const Text(
                        //         "Your already saved measurements will remain, but unsaved inputs will be lost.",
                        //       ),
                        //       actions: [
                        //         TextButton(
                        //           onPressed: () => Navigator.pop(context),
                        //           child: const Text("Cancel"),
                        //         ),
                        //         TextButton(
                        //           onPressed: () {
                        //             Navigator.pop(context);
                        //             Navigator.pop(context);
                        //           },
                        //           child: const Text("Discard"),
                        //         ),
                        //       ],
                        //     ),
                        //   );
                        // } else {
                        //   Navigator.pop(context);
                        // }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Cancel",
                            style: GoogleFonts.lisuBosa(fontSize: 17),
                          ),
                          const SizedBox(width: 25),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 85),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedMeasurementType == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please select a measurement type.",
                              ),
                            ),
                          );
                          return;
                        }

                        if (measurements.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please save at least one measurement.",
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context, {
                          "measurements": measurements,
                          "type": selectedMeasurementType,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text("Proceed"),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
