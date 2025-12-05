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

  //Days dropdown state
  bool _isDayDropdownOpen = false;
  final LayerLink _dayLayerLink = LayerLink();
  final GlobalKey _dayDropdownKey = GlobalKey();
  OverlayEntry? _dayOverlayEntry;

  //Times dropdown state
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
    _generateTimeslots();
    _loadData();
  }

  void _generateTimeslots() {
    final starttime = TimeOfDay(hour: 7, minute: 0);
    final endtime = TimeOfDay(hour: 21, minute: 0);

    List<String> slots = [];
    TimeOfDay current = starttime;

    while (_compareTime(current, endtime) <= 0) {
      final hour = current.hourOfPeriod == 0 ? 12 : current.hourOfPeriod;
      final minute = current.minute.toString().padLeft(2, '0');
      final period = current.period == DayPeriod.am ? "AM" : "PM";
      slots.add("$hour:$minute $period");

      int newMinute = current.minute + 30;
      int newHour = current.hour;
      if (newMinute >= 60) {
        newMinute = 0;
        newHour++;
      }
      current = TimeOfDay(hour: newHour, minute: newMinute);
    }

    _timeslots = slots;
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) {
    if (a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute)) return -1;
    if (a.hour == b.hour && a.minute == b.minute) return 0;
    return 1;
  }

  //DAY DROPDOWN
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

  //TIME DROPDOWN
  final List<String> _timeSlots = [
    "7:00 AM - 10:00 AM",
    "7:00 AM - 11:00 AM",
    "7:30 AM - 10:30 AM",
    "7:30 AM - 11:30 AM",
    "8:00 AM - 12:00 NN",
    "8:30 AM - 12:00 NN",
    "9:00 AM - 1:00 PM",
    "9:30 AM - 1:30 PM",
    "10:00 AM - 2:00 PM",
    "1:30 PM - 5:30 PM",
    "2:00 PM - 6:00 PM",
    "2:30 PM - 6:30 PM",
    "2:30 PM - 7:00 PM",
    "3:00 PM - 7:30 PM",
    "3:30 PM - 8:00 PM",
    "4:00 PM - 08:30 PM",
    "4:30 PM - 09:00 PM",
  ];
  void _toggleTimeDropdown() {
    if (_isTimeDropdownOpen) {
      _timeOverlayEntry?.remove();
      _isTimeDropdownOpen = false;
    } else {
      _timeOverlayEntry = _createTimeOverlay();
      _safeInsertOverlay(_timeOverlayEntry);
      _isTimeDropdownOpen = true;
    }
    setState(() {});
  }

  OverlayEntry _createTimeOverlay() {
    final tailorfontSize = context.read<TailorFontprovider>().fontSize;
    RenderBox renderBox =
        _timeDropdownKey.currentContext!.findRenderObject() as RenderBox;
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
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF3B5998),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _timeSlots.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white24, thickness: 1, height: 1),
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                return ListTile(
                  title: Center(
                    child: Text(
                      slot,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: tailorfontSize,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  onTap: () {
                    setState(() {
                      _selectedTime = slot;
                    });
                    _toggleTimeDropdown();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  //Services Offered
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
      _selectedTime = availability['timeSlot'];
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
                //Title/s
                Center(
                  child: Text(
                    "Availability Settings",
                    style: GoogleFonts.prompt(
                      // fontSize: 20,
                      fontSize: tailorfontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                //Availability
                Text(
                  "Availability",
                  style: GoogleFonts.prompt(
                    fontSize: tailorfontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                //Day dropdown
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _selectedDays.isEmpty
                                ? "Select day that apply"
                                : _selectedDays.join(", "),
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: tailorfontSize,
                            ),
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                            softWrap: true,
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

                //Time Hours
                Text(
                  "Time Hours",
                  style: GoogleFonts.prompt(
                    fontSize: tailorfontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  key: _timeDropdownKey,
                  onTap: _toggleTimeDropdown,
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
                        Text(
                          _selectedTime ?? "Select a time",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: tailorfontSize,
                          ),
                        ),
                        Icon(
                          _isTimeDropdownOpen
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                //Services Offered
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
