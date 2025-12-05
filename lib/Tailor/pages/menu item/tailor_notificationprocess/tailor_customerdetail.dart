import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerDetailPage extends StatefulWidget {
  final String customerId;
  final String appointmentId;
  final String? name;
  final String? garmentSpec;
  final String? service;
  final String? customization;
  final String? phone;
  final String? email;
  final String? message;
  final String? price;
  final String? priority;
  final String? appointmentDate;
  final String? neededBy;
  final int? quantity;
  final List<dynamic>? customizationImage;
  final String? measurementMethod;
  final Map<String, dynamic>? manualMeasurements;

  const CustomerDetailPage({
    super.key,
    required this.customerId,
    required this.appointmentId,
    this.name,
    this.garmentSpec,
    this.service,
    this.customization,
    this.phone,
    this.email,
    this.message,
    this.price,
    this.priority,
    this.appointmentDate,
    this.neededBy,
    this.quantity,
    this.customizationImage,
    this.measurementMethod,
    this.manualMeasurements,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  String? currentPrice;
  String? _customerAddress;
  String? _currentEmail;
  String? _customerImageUrl;
  String? _assignedTailor;
  final TextEditingController _assignedTailorController =
      TextEditingController();
  final List<String> _messages = [];
  List<String> _customizationImages = [];

  @override
  void initState() {
    super.initState();
    currentPrice = widget.price;
    _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.customerId)
          .get();

      final appointmentDoc = await FirebaseFirestore.instance
          .collection("Appointment Forms")
          .doc(widget.appointmentId)
          .get();

      if (!mounted) return;

      List<String> signedUrls = [];

      // Process user data
      if (userDoc.exists) {
        final data = userDoc.data();
        _customerAddress = data?['fullAddress'] ?? "No address available";
        _currentEmail = data?['email'] ?? "No email available";
        _assignedTailor = data?['assignedTailor'] ?? "";
        _assignedTailorController.text = _assignedTailor ?? "";
        _customerImageUrl = data?['profileImageUrl'] ?? "";
      } else {
        _customerAddress = "Address not found";
        _currentEmail = "Email not indicated";
      }

      if (appointmentDoc.exists) {
        final a = appointmentDoc.data();
        final List<dynamic>? uploadedImages = a?['uploadedImages'];

        if (uploadedImages != null && uploadedImages.isNotEmpty) {
          for (var url in uploadedImages) {
            final path = _extractRelativePath(url.toString());
            if (path.isNotEmpty) {
              final signedUrl = await getSignedUrl(path);
              if (signedUrl != null) signedUrls.add(signedUrl);
            }
          }
        }
      }

      setState(() {
        _customizationImages = signedUrls;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _customerAddress = "Error loading address";
        _currentEmail = "Error loading email";
      });
      print('Error fetching customer data: $e');
    }
  }

  String _extractRelativePath(String fullUrl) {
    const prefix =
        'https://lyoarnvbiegjplqbakyg.supabase.co/storage/v1/object/public/customers_appointmentfile/';
    if (fullUrl.startsWith(prefix)) {
      return fullUrl.substring(prefix.length);
    }
    return '';
  }

  Future<String?> getSignedUrl(String path) async {
    try {
      return await Supabase.instance.client.storage
          .from('customers_appointmentfile')
          .createSignedUrl(path, 3600);
    } catch (e) {
      print('Error generating signed URL for $path: $e');
      return null;
    }
  }

  Future<void> _saveAssignedTailor({required String appointmentId}) async {
    final input = _assignedTailorController.text.trim();

    try {
      final docRef = FirebaseFirestore.instance
          .collection("Appointment Forms")
          .doc(appointmentId);

      await docRef.update({
        'tailorAssigned': input.isEmpty ? _assignedTailor : input,
        'price': currentPrice ?? "",
        'messages': _messages,
      });

      if (!mounted) return;
      setState(() => _assignedTailor = input);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved successfully.")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving data: $e")));
    }
  }

  Widget _circleButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF5F7F9),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.blueGrey),
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Container(
      color: isHeader ? const Color(0xFFE8F9FF) : Colors.white,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  void _openMessageBox() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() => _messages.add(controller.text));
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerImage() {
    if (_customerImageUrl == null) {
      return Container(
        height: 195,
        width: 130,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_customerImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _customerImageUrl!,
          height: 195,
          width: 130,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 195,
              width: 130,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 195,
              width: 130,
              decoration: BoxDecoration(
                color: const Color(0xFFC3BA85),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person, size: 60, color: Colors.grey),
            );
          },
        ),
      );
    }

    return Container(
      height: 195,
      width: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFC3BA85),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  Widget _buildAssignTailorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Assign Tailor to Appointment",
                style: GoogleFonts.songMyung(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _assignedTailorController,
                decoration: InputDecoration(
                  hintText: "Enter tailor name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, right: 12),
          child: Text(
            "Pricing & Messages",
            style: GoogleFonts.songMyung(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(top: 8, right: 12, bottom: 12),
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _circleButton(Icons.edit, _editPrice),
                    const SizedBox(width: 8),
                    _circleButton(Icons.message_outlined, _openMessageBox),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(2),
                  },
                  border: const TableBorder(
                    top: BorderSide(color: Colors.black),
                    horizontalInside: BorderSide(color: Colors.black26),
                  ),
                  children: [
                    TableRow(
                      children: [
                        _tableCell("Given Price", isHeader: true),
                        _tableCell(
                          currentPrice == null || currentPrice!.isEmpty
                              ? "Not set"
                              : "₱ $currentPrice",
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                if (_messages.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.person_2_outlined,
                                  color: Colors.black54,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    msg,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Center(
                    child: Text(
                      "No messages",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editPrice() async {
    final controller = TextEditingController(text: currentPrice ?? "");
    final newPrice = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F8CAA), Color(0xFF626F47)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter Product Price",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "PHP 0.00",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: GoogleFonts.acme()),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: Text("Save", style: GoogleFonts.acme()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newPrice != null && newPrice.isNotEmpty) {
      setState(() => currentPrice = newPrice);
    }
  }

  Widget _buildSeeLessButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 110, vertical: 10),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.black, width: 1.2),
            ),
          ),
          onPressed: () async {
            await _saveAssignedTailor(appointmentId: widget.appointmentId);

            if (!mounted) return;

            Navigator.pop(context, {
              'price': currentPrice ?? "",
              'messages': _messages,
              'assignedTailor': _assignedTailor ?? "",
            });

            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: '',
              transitionDuration: const Duration(milliseconds: 350),
              pageBuilder: (context, animation, secondaryAnimation) {
                return const SizedBox.shrink();
              },
              transitionBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFDFCFB), Color(0xFFE2DCC8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFD3CBB8),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3E3E3E),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFFE6C266),
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 18),

                            Text(
                              "Saved Temporarily",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),

                            Text(
                              "Your updates have been saved temporarily.\nThey will be sent to the customer once you confirm.",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 25),

                            SizedBox(
                              width: 110,
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3E3E3E),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Okay",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFE6C266),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "SEE LESS",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_upward, color: Colors.black, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String formatDateTime(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      final bool isTimeEmpty = date.hour == 0 && date.minute == 0;

      final dateFormat = DateFormat("MMMM d, y");
      final timeFormat = DateFormat("h:mm a");

      if (isTimeEmpty) {
        return dateFormat.format(date);
      } else {
        return "${dateFormat.format(date)} – ${timeFormat.format(date)}";
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Customer Details",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildCustomerImage(),
                ),
                Expanded(child: _buildPriceCard()),
              ],
            ),
            _buildAssignTailorSection(),

            buildSection("Personal Details", [
              ["Full Name", widget.name],
              ["Garment Specification", widget.garmentSpec],
              ["Quantity", (widget.quantity?.toString() ?? "Not Specified")],
              ["Service", widget.service],
              ["Customization Detail", widget.customization],
              ["Address", _customerAddress ?? "Loading..."],
              ["Message", widget.message],
            ]),
            if (_customizationImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Customization Images",
                      style: GoogleFonts.songMyung(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _customizationImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final imageUrl = _customizationImages[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _customizationImages[index],
                              width: 150,
                              height: 180,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 150,
                                      height: 180,
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 150,
                                  height: 180,
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            buildSection("Contact Details", [
              ["Email (Optional)", _currentEmail ?? "Loading..."],
              ["Mobile Number", widget.phone],
            ]),

            buildSection("Deadline Details", [
              [
                "Needed by Date",
                widget.neededBy != null
                    ? formatDateTime(widget.neededBy!)
                    : "Not Provided",
              ],
              [
                "Prioritization",
                widget.priority ?? "Unknown",
                _priorityColor(widget.priority),
              ],
            ]),

            buildSection("Appointment Details", [
              [
                "Appointment Date",
                widget.appointmentDate != null
                    ? formatDateTime(widget.appointmentDate!)
                    : "Not Provided",
              ],
              [
                "Priority",
                widget.priority ?? "Unknown",
                _priorityColor(widget.priority),
              ],
            ]),

            if (widget.measurementMethod != null)
              buildSection("Measurement Details", [
                ["Measurement Method", widget.measurementMethod],
              ]),

            if (widget.manualMeasurements != null &&
                widget.manualMeasurements!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Manual Measurements",
                          style: GoogleFonts.songMyung(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.manualMeasurements!.entries.map((entry) {
                          final part = entry.key;
                          final values = entry.value as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                part,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(1.5),
                                  1: FlexColumnWidth(1.5),
                                },
                                border: TableBorder.all(
                                  color: Colors.black12,
                                  width: 0.8,
                                ),
                                children: values.entries.map((v) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          v.key,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          v.value.toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            _buildSeeLessButton(context),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case "high":
        return const Color(0xFF800000);
      case "medium":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}

Widget buildSection(String title, List<List<dynamic>> rows) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(color: Colors.black26, width: 0.8),
          ),
          child: Column(
            children: rows.map((row) {
              final label = row[0] as String;
              final value = row[1] ?? "Not Provided";
              final valueColor = row.length > 2
                  ? row[2] as Color
                  : Colors.black;

              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black26, width: 0.6),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          color: const Color(0xFFE8F3FF),
                          alignment: Alignment.topLeft,
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          alignment: Alignment.topLeft,
                          child: Text(
                            value.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: valueColor,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}
