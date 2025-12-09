import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';

class TailorAvailabilitySettings extends StatefulWidget {
  const TailorAvailabilitySettings({super.key});

  @override
  State<TailorAvailabilitySettings> createState() =>
      _TailorAvailabilitySettingsState();
}

class _TailorAvailabilitySettingsState
    extends State<TailorAvailabilitySettings> {
  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  List<String> _selectedDays = [];
  bool _isAvailable = true;

  final TextEditingController _assignedToController = TextEditingController();

  // Working Hours Per Day
  Map<String, Map<String, String?>> _workingHours = {
    "Monday": {"start": null, "end": null},
    "Tuesday": {"start": null, "end": null},
    "Wednesday": {"start": null, "end": null},
    "Thursday": {"start": null, "end": null},
    "Friday": {"start": null, "end": null},
    "Saturday": {"start": null, "end": null},
    "Sunday": {"start": null, "end": null},
  };

  Map<String, bool> _expandedDays = {};
  // Days Dropdown State
  bool _isDayDropdownOpen = false;
  final LayerLink _dayLayerLink = LayerLink();
  final GlobalKey _dayDropdownKey = GlobalKey();
  OverlayEntry? _dayOverlayEntry;

  // Times Dropdown State
  List<String> _timeslots = [];
  String? _selectedTime;
  bool _isTimeDropdownOpen = false;
  final LayerLink _timeLayerLink = LayerLink();
  final GlobalKey _timeDropdownKey = GlobalKey();
  OverlayEntry? _timeOverlayEntry;

  void _safeInsertOverlay(OverlayEntry? entry) {
    if (entry == null) return;
    final overlay = Overlay.of(context);
    if (!mounted) return;
    overlay.insert(entry);
  }

  final TextEditingController _numberofCustomerController =
      TextEditingController();
  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _pickTime(String day, bool isStart) async {
    final initial = TimeOfDay.now();

    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (result == null) return;

    final formatted =
        "${result.hourOfPeriod.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')} "
        "${result.period == DayPeriod.am ? "AM" : "PM"}";

    setState(() {
      if (isStart) {
        _workingHours[day]!["start"] = formatted;
      } else {
        _workingHours[day]!["end"] = formatted;
      }
    });
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) {
    if (a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute)) return -1;
    if (a.hour == b.hour && a.minute == b.minute) return 0;
    return 1;
  }

  // Day Dropdown
  void _toggleDayDropdown() {
    if (_isDayDropdownOpen) {
      _dayOverlayEntry?.remove();
    } else {
      _dayOverlayEntry = _createDayOverlay();
      _safeInsertOverlay(_dayOverlayEntry);
    }
    setState(() {
      _isDayDropdownOpen = !_isDayDropdownOpen;
    });
  }

  // Day Overlay Choices
  OverlayEntry _createDayOverlay() {
    final tailorfontSize = context.read<TailorFontprovider>().fontSize;

    RenderBox renderBox =
        _dayDropdownKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B5998),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._days.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(
                      day,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: tailorfontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                        _dayOverlayEntry?.remove();
                        _dayOverlayEntry = _createDayOverlay();
                        _safeInsertOverlay(_dayOverlayEntry);
                      });
                    },
                  );
                }),
                const Divider(color: Colors.white),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDays.clear();
                            _dayOverlayEntry?.remove();
                            _dayOverlayEntry = _createDayOverlay();
                            Overlay.of(context).insert(_dayOverlayEntry!);
                          });
                        },
                        child: const Text(
                          "Deselect All",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDays = List.from(_days);
                            _dayOverlayEntry?.remove();
                            _dayOverlayEntry = _createDayOverlay();
                            _safeInsertOverlay(_dayOverlayEntry);
                          });
                        },
                        child: Text(
                          "Select All",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: tailorfontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Services Offered
  final List<String> _servicesoffered = [
    "Alterations",
    "Custom Tailoring",
    "Repairs",
    "Restyling",
    "Embroidery and Monogramming",
    "Bridal and Formal Wear Alterations",
    "Uniform Tailoring",
    "Garment Resizing",
    "Custom Design and Alterations",
    "Formal Wear Rental",
    "Clothing Rental",
    "Dress Rental",
  ];

  List<String> _selectedServicesOffered = [];

  bool _isServicesdropdownopen = false;
  // Services Overlay Choices
  OverlayEntry? _serviceOverlayEntry;
  final GlobalKey _serviceDropdownKey = GlobalKey();

  void _toggleServiceDropdown() {
    if (_isServicesdropdownopen) {
      _serviceOverlayEntry?.remove();
    } else {
      _serviceOverlayEntry = _createServiceOverlay();
      _safeInsertOverlay(_serviceOverlayEntry);
    }
    setState(() {
      _isServicesdropdownopen = !_isServicesdropdownopen;
    });
  }

  OverlayEntry _createServiceOverlay() {
    final tailorfontSize = context.read<TailorFontprovider>().fontSize;
    RenderBox renderBox =
        _serviceDropdownKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayHeight = (_servicesoffered.length * 56.0) > screenHeight * 0.5
        ? screenHeight * 0.5
        : _servicesoffered.length * 56.0;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B5998),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._servicesoffered.map((service) {
                      final isSelected = _selectedServicesOffered.contains(
                        service,
                      );
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(
                          service,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: tailorfontSize,
                          ),
                        ),
                        activeColor: Colors.white,
                        checkColor: Colors.black,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedServicesOffered.add(service);
                            } else {
                              _selectedServicesOffered.remove(service);
                            }
                            _serviceOverlayEntry?.remove();
                            _serviceOverlayEntry = _createServiceOverlay();
                            _safeInsertOverlay(_serviceOverlayEntry);
                          });
                        },
                      );
                    }),
                    const Divider(color: Colors.white),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedServicesOffered.clear();
                                _serviceOverlayEntry?.remove();
                                _serviceOverlayEntry = _createServiceOverlay();
                                _safeInsertOverlay(_serviceOverlayEntry);
                              });
                            },
                            child: Text(
                              "Deselect All",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: tailorfontSize,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedServicesOffered = List.from(
                                  _servicesoffered,
                                );
                                _serviceOverlayEntry?.remove();
                                _serviceOverlayEntry = _createServiceOverlay();
                                Overlay.of(
                                  context,
                                ).insert(_serviceOverlayEntry!);
                              });
                            },
                            child: Text(
                              "Select All",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: tailorfontSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Load the picked choice unto the tailors/tailor shops profile
  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    final availability = data['availability'] ?? {};

    setState(() {
      _isAvailable = availability['isAvailable'] ?? true;
      _selectedDays = List<String>.from(availability['days'] ?? []);

      final hours = availability['workingHours'] ?? {};
      hours.forEach((day, map) {
        _workingHours[day] = {"start": map["start"], "end": map["end"]};
      });
      _numberofCustomerController.text =
          (availability['maxCustomersPerDay'] ?? '').toString();
      _selectedServicesOffered = List<String>.from(
        availability['servicesOffered'] ?? [],
      );
      _assignedToController.text = availability['assignedTo'] ?? '';
    });
  }

  @override
  void dispose() {
    if (_dayOverlayEntry?.mounted ?? false) {
      _dayOverlayEntry?.remove();
    }
    if (_timeOverlayEntry?.mounted ?? false) {
      _timeOverlayEntry?.remove();
    }
    if (_serviceOverlayEntry?.mounted ?? false) {
      _serviceOverlayEntry?.remove();
    }
    _numberofCustomerController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  // This is the standard role for handling the application - owner first.
  String _selectedRole = "Owner";

  @override
  Widget build(BuildContext context) {
    final tailorfontSize = context.watch<TailorFontprovider>().fontSize;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Availability Settings",
                    style: GoogleFonts.prompt(
                      fontSize: tailorfontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Availability Text with Dropdown
                Text(
                  "Availability",
                  style: GoogleFonts.prompt(
                    fontSize: tailorfontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  key: _dayDropdownKey,
                  onTap: _toggleDayDropdown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDays.isEmpty
                                ? "Select day that apply"
                                : _selectedDays.join(", "),
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: tailorfontSize,
                            ),
                          ),
                        ),
                        Icon(
                          _isDayDropdownOpen
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Working Hours",
                  style: GoogleFonts.prompt(
                    fontSize: tailorfontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedDays.map((day) {
                    final start = _workingHours[day]!["start"];
                    final end = _workingHours[day]!["end"];
                    final isOpen = _expandedDays[day] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedDays[day] = !(isOpen);
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: tailorfontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Icon(
                                  isOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                ),
                              ],
                            ),
                          ),

                          if (isOpen) ...[
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickTime(day, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        start ?? "Start time",
                                        style: TextStyle(
                                          fontSize: tailorfontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickTime(day, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        end ?? "End time",
                                        style: TextStyle(
                                          fontSize: tailorfontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Services Offered Text with Dropdown
                Text(
                  "Services Offered",
                  style: GoogleFonts.prompt(
                    fontSize: tailorfontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  key: _serviceDropdownKey,
                  onTap: _toggleServiceDropdown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedServicesOffered.isEmpty
                                ? "Pick Services/s That You Expert With"
                                : _selectedServicesOffered.join(", "),
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: tailorfontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Icon(
                          _isServicesdropdownopen
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Assigned To (Owner / Manager)",
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          color: const Color(0xFFA2AF9B),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              dropdownColor: const Color(0xFFB8C4A9),
                              iconEnabledColor: const Color(0xFF0F2C59),
                              items: ['Owner', 'Manager', 'Staff']
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(
                                        role,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedRole = value);
                                }
                              },
                            ),
                          ),
                        ),
                        Container(width: 1, color: Colors.grey.shade400),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              controller: _assignedToController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter name (e.g., Toni Fowler)",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Number of Customers Per Day",
                            style: GoogleFonts.prompt(
                              fontSize: 12,
                              // fontSize: tailorfontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 50,
                            width: 200,
                            child: TextField(
                              controller: _numberofCustomerController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: "Enter number",
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 15),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Availability button",
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              value: _isAvailable,
                              onChanged: (bool value) {
                                setState(() {
                                  _isAvailable = value;
                                });
                              },
                              activeColor: Color(0xFF415E72),
                              activeTrackColor: Color(0xFFA2AF9B),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.blueGrey.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF72A0C1),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(user.uid)
                    .set({
                      "availability": {
                        "isAvailable": _isAvailable,
                        "days": _selectedDays,
                        "timeSlot": _selectedTime,
                        "maxCustomersPerDay":
                            int.tryParse(_numberofCustomerController.text) ?? 0,
                        "servicesOffered": _selectedServicesOffered,
                        "assignedTo": _assignedToController.text,
                      },
                    }, SetOptions(merge: true));

                if (!mounted) return;

                if (_dayOverlayEntry?.mounted ?? false) {
                  _dayOverlayEntry?.remove();
                }
                if (_timeOverlayEntry?.mounted ?? false) {
                  _timeOverlayEntry?.remove();
                }
                if (_serviceOverlayEntry?.mounted ?? false) {
                  _serviceOverlayEntry?.remove();
                }

                Navigator.of(context, rootNavigator: true).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Availability saved successfully!"),
                  ),
                );

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const TailorProfileSettingsPage(),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
              }
            },
            child: Text(
              "Confirm",
              style: GoogleFonts.chauPhilomeneOne(
                fontWeight: FontWeight.w600,
                fontSize: tailorfontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
