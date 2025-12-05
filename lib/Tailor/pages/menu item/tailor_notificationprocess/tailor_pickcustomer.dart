import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_notificationprocess/tailor_customerdetail.dart';

class TailorPickCustomer extends StatefulWidget {
  const TailorPickCustomer({
    super.key,
    required Map<String, dynamic> appointmentData,
    required List<Map<String, dynamic>> customers,
  });

  @override
  State<TailorPickCustomer> createState() => _TailorPickCustomerState();
}

class _TailorPickCustomerState extends State<TailorPickCustomer> {
  final Map<String, Map<String, dynamic>> widgetTempData = {};
  bool isLoading = true;
  List<Map<String, dynamic>> customers = [];
  // Use appointmentId as unique identifier for selection
  final Set<String> selectedAppointmentIds = {};

  @override
  void initState() {
    super.initState();
    _loadPendingTailorCustomers();
  }

  Future<void> _loadPendingTailorCustomers() async {
    setState(() => isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final query = await FirebaseFirestore.instance
          .collection('Appointment Forms')
          .where('tailorId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'Pending Tailor Response')
          .get();

      final data = query.docs.map((doc) {
        final map = doc.data();
        map['appointmentId'] = doc.id;
        return map;
      }).toList();

      // attempt to fetch profile images for each customer (non-blocking)
      for (var i = 0; i < data.length; i++) {
        final cust = data[i];
        final customerId = cust['customerId'];
        if (customerId != null) {
          final img = await _fetchFirestoreImage(customerId);
          if (img != null) data[i]['profileImageUrl'] = img;
        }
      }

      setState(() {
        customers = data;
      });
    } catch (e) {
      debugPrint('Error loading customers: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> _fetchFirestoreImage(String customerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(customerId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['profileImageUrl'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching Firestore image: $e');
    }
    return null;
  }

  Widget _getCustomerImage(Map<String, dynamic> customer) {
    final imageUrl = customer['profileImageUrl'] ?? '';
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 280,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
            errorBuilder: (_, __, ___) => _defaultAvatar(),
          ),
        ),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() => Container(
    color: Colors.grey[300],
    alignment: Alignment.center,
    child: const Icon(Icons.person, size: 60, color: Colors.grey),
  );

  bool get _hasSelection => selectedAppointmentIds.isNotEmpty;

  bool get _allSelectedArePending {
    if (!_hasSelection) return false;
    for (final apptId in selectedAppointmentIds) {
      final c = customers.firstWhere(
        (e) => e['appointmentId'] == apptId,
        orElse: () => {},
      );
      if (c.isEmpty) return false;
      final status = c['status'] ?? '';
      if (status != 'Pending Tailor Response') return false;
    }
    return true;
  }

  Future<void> _batchDecline() async {
    if (!_hasSelection) return;
    final tailorId = FirebaseAuth.instance.currentUser?.uid;
    if (tailorId == null) return;

    final List<String> toProcess = selectedAppointmentIds.toList();
    for (final apptId in toProcess) {
      try {
        // find customer data
        final cust = customers.firstWhere(
          (c) => c['appointmentId'] == apptId,
          orElse: () => {},
        );
        if (cust.isEmpty) continue;
        final customerId = cust['customerId'];
        // update appointment doc
        await FirebaseFirestore.instance
            .collection('Appointment Forms')
            .doc(apptId)
            .update({
              'status': 'Available',
              'tailorId': null,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        // send notification to customer
        if (customerId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'appointmentId': apptId,
            'title': 'Appointment Declined',
            'body':
                'The tailor has declined your appointment. You can choose another tailor.',
            'timestamp': FieldValue.serverTimestamp(),
            'toCustomerId': customerId,
            'recipientType': 'customer',
            'readBy': [],
          });
        }
        // optional: tailor notification log (keeps track)
        await FirebaseFirestore.instance.collection('notifications').add({
          'appointmentId': apptId,
          'title': 'You declined an appointment',
          'body':
              'You have declined the appointment request from ${cust['fullName'] ?? 'customer'}.',
          'timestamp': FieldValue.serverTimestamp(),
          'toTailorId': tailorId,
          'recipientType': 'tailor',
          'readBy': [],
        });
      } catch (e) {
        debugPrint('Error declining $apptId: $e');
      }
    }

    // refresh list and clear selection
    await _loadPendingTailorCustomers();
    selectedAppointmentIds.clear();
    setState(() {});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected appointments declined.')),
      );
    }
  }

  Future<void> _batchAccept() async {
    if (!_hasSelection) return;
    final tailorId = FirebaseAuth.instance.currentUser?.uid;
    if (tailorId == null) return;

    final List<String> toProcess = selectedAppointmentIds.toList();
    for (final apptId in toProcess) {
      try {
        final cust = customers.firstWhere(
          (c) => c['appointmentId'] == apptId,
          orElse: () => {},
        );
        if (cust.isEmpty) continue;
        final customerId = cust['customerId'];
        final tempData = widgetTempData[customerId] ?? {};

        await FirebaseFirestore.instance
            .collection('Appointment Forms')
            .doc(apptId)
            .update({
              'status': 'Waiting Customer Response',
              'tailorId': tailorId,
              'tailorPrice': tempData['price'] ?? 0,
              'tailorMessage': tempData['messages'] ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (tempData['assignedTailor'] != null) {
          await FirebaseFirestore.instance
              .collection('Appointment Forms')
              .doc(apptId)
              .update({'tailorAssigned': tempData['assignedTailor']});
        }

        if (customerId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'appointmentId': apptId,
            'title': 'Tailor responded to your request',
            'body':
                'The tailor has provided details. Please review and confirm.',
            'timestamp': FieldValue.serverTimestamp(),
            'toCustomerId': customerId,
            'recipientType': 'customer',
            'readBy': [],
          });
        }

        await FirebaseFirestore.instance.collection('notifications').add({
          'appointmentId': apptId,
          'title': 'Waiting for Customer Response',
          'body':
              'You have accepted this appointment. Waiting for the customer to respond.',
          'timestamp': FieldValue.serverTimestamp(),
          'toTailorId': tailorId,
          'recipientType': 'tailor',
          'readBy': [],
        });
      } catch (e) {
        debugPrint('Error accepting $apptId: $e');
      }
    }

    // refresh list and clear selection
    await _loadPendingTailorCustomers();
    selectedAppointmentIds.clear();
    setState(() {});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected appointments accepted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF6082B6),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
          ? const Center(child: Text("No pending customers"))
          : Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  height: 50,
                  width: 310,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB0C4DE),
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  child: const Text(
                    "Customers Available in the Area",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: customers.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.55,
                        ),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final appointmentId =
                          customer['appointmentId'] as String?;
                      final isSelected =
                          appointmentId != null &&
                          selectedAppointmentIds.contains(appointmentId);
                      return GarmentCard(
                        customer: customer,
                        imageWidget: _getCustomerImage(customer),
                        name: customer['fullName'] ?? "No Name",
                        garmentSpec: customer['garmentSpec'] ?? "Unknown",
                        service: customer['services'] ?? "Unknown",
                        status: customer['status'] ?? "Pending Tailor Response",
                        customization:
                            customer['customizationDescription'] ?? "None",
                        phone: (customer['phoneNumber'] ?? "").toString(),

                        email: customer['email'] ?? "",
                        message: customer['message'] ?? "",
                        customerId: customer['customerId'] ?? "",
                        appointmentId: appointmentId ?? "",
                        onTempDataSaved: (id, data) {
                          widgetTempData[id] = data;
                        },
                        onToggleSelect: () {
                          if (appointmentId == null) return;
                          setState(() {
                            if (selectedAppointmentIds.contains(
                              appointmentId,
                            )) {
                              selectedAppointmentIds.remove(appointmentId);
                            } else {
                              selectedAppointmentIds.add(appointmentId);
                            }
                          });
                        },
                        isSelected: isSelected,
                        neededBy: customer['dueDateTime'] != null
                            ? (customer['dueDateTime'] as Timestamp)
                                  .toDate()
                                  .toString()
                            : "Unknown",
                        appointmentDate: customer['appointmentDateTime'] != null
                            ? (customer['appointmentDateTime'] as Timestamp)
                                  .toDate()
                                  .toString()
                            : "Unknown",
                        priority:
                            customer['priority'] ??
                            customer['duepriority'] ??
                            "Unknown",
                        quantity: customer['quantity'] ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decline All Selected
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: (_hasSelection && _allSelectedArePending)
                    ? _batchDecline
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_hasSelection && _allSelectedArePending)
                      ? const Color(0xFF7C3030)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Decline"),
              ),
            ),
            const SizedBox(width: 12),
            // Accept All Selected
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: (_hasSelection && _allSelectedArePending)
                    ? _batchAccept
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_hasSelection && _allSelectedArePending)
                      ? const Color(0xFF478778)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Accept"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GarmentCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final Widget imageWidget;
  final String name;
  final String garmentSpec;
  final String service;
  final String status;
  final String customization;
  final String phone;
  final String email;
  final String message;
  final String customerId;
  final String appointmentId;
  final String? neededBy;
  final String? appointmentDate;
  final String? priority;
  final int? quantity;
  final Function(String, Map<String, dynamic>) onTempDataSaved;
  final VoidCallback onToggleSelect;
  final bool isSelected;

  const GarmentCard({
    super.key,
    required this.customer,
    required this.imageWidget,
    required this.name,
    required this.garmentSpec,
    required this.service,
    required this.status,
    required this.customization,
    required this.phone,
    required this.email,
    required this.message,
    required this.customerId,
    required this.appointmentId,
    this.neededBy,
    this.appointmentDate,
    this.priority,
    this.quantity,
    required this.onTempDataSaved,
    required this.onToggleSelect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = status == "Pending Tailor Response"
        ? const Color(0xFFD32828)
        : const Color(0xFF25651A);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.green : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: imageWidget,
                ),
                Positioned(
                  top: -20,
                  right: -20,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelect(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    checkColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 32,
              color: const Color(0xFFC4C4C4),
              alignment: Alignment.center,
              child: Text(
                service,
                style: GoogleFonts.poppins(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: 35,
              color: const Color(0xFFC4C4C4),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF25651A),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 2),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailPage(
                      customerId: customerId,
                      appointmentId: appointmentId,
                      name: name,
                      garmentSpec: garmentSpec,
                      service: service,
                      customization: customization,
                      phone: phone,
                      email: email,
                      message: message,
                      neededBy: neededBy,
                      appointmentDate: appointmentDate,
                      priority: priority,
                      quantity: quantity,
                      customizationImage:
                          customer['uploadedImages'] ??
                          customer['customizationImages'] ??
                          customer['images'] ??
                          [],
                      measurementMethod: customer['measurementMethod'] ?? '',
                      manualMeasurements: customer['manualMeasurements'] != null
                          ? Map<String, dynamic>.from(
                              customer['manualMeasurements'],
                            )
                          : {},
                    ),
                  ),
                );

                if (result != null) {
                  onTempDataSaved(customerId, {
                    'price': result['price'],
                    'messages': result['messages'],
                    'assignedTailor': result['assignedTailor'],
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Temporary updates saved.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6082B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('SEE MORE', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
