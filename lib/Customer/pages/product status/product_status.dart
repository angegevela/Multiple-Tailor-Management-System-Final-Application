import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:threadhub_system/Customer/pages/customer_chatfunction/chat.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'package:threadhub_system/Customer/pages/product%20status/receipt/product_finalreceipt.dart';
import 'package:threadhub_system/Customer/pages/product%20status/customer%20report/customer_report.dart';
import 'package:threadhub_system/Customer/pages/review.dart';
import 'package:threadhub_system/Customer/signup/customer_homepage.dart';

class ProductFilter {
  String? status;
  bool? hasTailor;

  ProductFilter({this.status, this.hasTailor});
}

class ProductStatusPage extends StatefulWidget {
  final String customerId;
  const ProductStatusPage({super.key, required this.customerId});

  @override
  State<ProductStatusPage> createState() => _ProductStatusPageState();
}

class _ProductStatusPageState extends State<ProductStatusPage> {
  bool isLoading = true;
  int currentPage = 0;
  int sectionPageIndex = 0;
  final int rowsPerPage = 7;
  String searchQuery = "";
  ProductFilter activeFilter = ProductFilter();
  final TextEditingController _searchController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final List<List<String>> sectionHeaders = [
    ['Service Type', 'Status'],
    ['Needed By Date', 'Order'],
    ['Tailor Assigned', 'Yield ID'],
    ['Receipt', 'Report'],
    ['Order Received', 'Review'],
  ];

  List<List<Map<String, dynamic>>> sectionData = [[], [], [], [], []];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('Appointment Forms')
          .where('customerId', isEqualTo: user.uid)
          .get();

      final allDocs = snapshot.docs.map((doc) {
        final data = doc.data();
        final firstName = (data['firstName'] ?? '').toString().trim();
        final surname = (data['surname'] ?? '').toString().trim();
        final username = (data['username'] ?? '').toString().trim();
        final assignedTailor = (data['assignedTailor'] ?? '').toString();

        final customerName = (firstName.isNotEmpty || surname.isNotEmpty)
            ? '$firstName $surname'
            : (username.isNotEmpty ? username : 'Unknown Customer');

        final shopName = assignedTailor.isNotEmpty
            ? assignedTailor
            : 'Unknown Shop';

        return {
          ...data,
          'appointmentId': doc.id,
          'customerName': customerName,
          'shopName': shopName,
        };
      }).toList();

      final filteredDocs = allDocs.where((data) {
        bool matchesStatus =
            activeFilter.status == null ||
            data['status'] == activeFilter.status;
        bool matchesTailor =
            activeFilter.hasTailor == null ||
            (activeFilter.hasTailor!
                ? (data['tailorId'] != null &&
                      data['tailorId'].toString().trim().isNotEmpty)
                : (data['tailorId'] == null ||
                      data['tailorId'].toString().trim().isEmpty));
        return matchesStatus && matchesTailor;
      }).toList();

      List<Map<String, dynamic>> serviceTypeStatus = [];
      List<Map<String, dynamic>> neededByProductOrder = [];
      List<Map<String, dynamic>> tailorAssignedYield = [];
      List<Map<String, dynamic>> receiptReport = [];
      List<Map<String, dynamic>> orderReceivedData = [];

      for (var doc in filteredDocs) {
        
        // Section 1: Service Type & Status
        serviceTypeStatus.add({
          'Service Type': doc['services'] ?? '',
          'Status': doc['status'] ?? '',
          'Order': doc['garmentSpec'] ?? '',
          'Tailor Assigned': doc['tailorAssigned'] ?? 'No Tailor',
          'customerName': doc['customerName'],
          'shopName': doc['shopName'],
          'appointmentId': doc['appointmentId'],
        });

        // Section 2: Needed By Date & Order
        neededByProductOrder.add({
          'Needed By Date': _formatCellValue(
            'Needed By Date',
            doc['dueDateTime'],
          ),
          'Order': doc['garmentSpec'] ?? '',
          'Service Type': doc['services'] ?? '',
          'Tailor Assigned': doc['tailorAssigned'] ?? 'No Tailor',
          'customerName': doc['customerName'],
          'shopName': doc['shopName'],
          'appointmentId': doc['appointmentId'],
        });

        // Section 3: Tailor Assigned & Yield ID
        tailorAssignedYield.add({
          'Tailor Assigned': doc['tailorAssigned'] ?? 'No Tailor',
          'Yield ID': doc['appointmentId'],
          'Service Type': doc['services'] ?? '',
          'Order': doc['garmentSpec'] ?? '',
          'customerName': doc['customerName'],
          'shopName': doc['shopName'],
        });

        // Section 4: Receipt & Report
        receiptReport.add({
          'Receipt': doc['appointmentId'],
          'Report': doc['appointmentId'],
          'Service Type': doc['services'] ?? '',
          'Order': doc['garmentSpec'] ?? '',
          'customerName': doc['customerName'],
          'shopName': doc['shopName'],
        });

        // Section 5: Order Received & Review
        orderReceivedData.add({
          'Order Received': doc['appointmentId'],
          'status': doc['status'] ?? '',
          'orderReceived': doc['orderReceived'] ?? false,
          'reviewSubmitted': doc['reviewSubmitted'] ?? false,
          'Tailor Assigned': doc['tailorAssigned'] ?? 'No Tailor',
          'Service Type': doc['services'] ?? '',
          'Order': doc['garmentSpec'] ?? '',
          'customerName': doc['customerName'],
          'shopName': doc['shopName'],
          'tailorId': doc['tailorId'] ?? '',
        });
      }

      if (!mounted) return;
      setState(() {
        sectionData = [
          serviceTypeStatus,
          neededByProductOrder,
          tailorAssignedYield,
          receiptReport,
          orderReceivedData,
        ];
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _markOrderReceived(String appointmentId) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            'Confirm',
            style: GoogleFonts.poltawskiNowy(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Do you want to mark this order as received?',
            style: GoogleFonts.poltawskiNowy(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF335E7A),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Yes',
                style: GoogleFonts.poltawskiNowy(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB373A),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'No',
                style: GoogleFonts.poltawskiNowy(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await FirebaseFirestore.instance
          .collection('Appointment Forms')
          .doc(appointmentId)
          .update({'orderReceived': true});

      if (!mounted) return;

      final writeReview = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            'Write a Review?',
            style: GoogleFonts.poltawskiNowy(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Do you want to write a review for this tailor or tailor shop?',
            style: GoogleFonts.poltawskiNowy(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (writeReview == true) {
        final appointmentDoc = await FirebaseFirestore.instance
            .collection('Appointment Forms')
            .doc(appointmentId)
            .get();

        if (!appointmentDoc.exists) return;

        final tailorId = appointmentDoc.data()?['tailorId'] ?? '';
        final tailorDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(tailorId)
            .get();

        if (!tailorDoc.exists) return;

        final tailorData = tailorDoc.data()!;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RatingandReviewPage(
              appointmentId: appointmentId,
              tailorId: tailorId,
              tailorName: tailorData['ownerName'] ?? '',
              tailorPhone: tailorData['businessNumber'] ?? '',
              tailorEmail: tailorData['email'] ?? '',
              tailorImage: tailorData['profileImageUrl'] ?? '',
              tailorShop: tailorData['shopName'] ?? '',
              availability: tailorData['availability'] ?? {},
              expertise: tailorData['servicesOffered'] ?? [],
              status: tailorData['isAvailable'] == true
                  ? 'Available'
                  : 'Unavailable',
              location: tailorData['fullAddress'] ?? '',
            ),
          ),
        );
      }

      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked as received.')),
      );
    } catch (e) {
      print('Error marking order as received: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark order as received.')),
      );
    }
  }

  Future<String> _getOrCreateChat(String customerId, String tailorName) async {
    final chatCollection = FirebaseFirestore.instance.collection('Chats');

    final existingSnapshot = await chatCollection
        .where('participants', arrayContains: customerId)
        .get();

    for (var doc in existingSnapshot.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);

      if (participants.contains(tailorName) && participants.length == 2) {
        return doc.id;
      }
    }

    final newChat = await chatCollection.add({
      'participants': [customerId, tailorName],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;
    final headers = sectionHeaders[sectionPageIndex];
    final filteredData = sectionData[sectionPageIndex].where((item) {
      bool matchesSearch =
          searchQuery.isEmpty ||
          item.values.any(
            (value) =>
                value != null &&
                value.toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          );

      bool matchesStatus =
          activeFilter.status == null ||
          (item['Status'] != null &&
              item['Status'].toString().trim().toLowerCase() ==
                  activeFilter.status!.trim().toLowerCase());

      bool matchesTailor =
          activeFilter.hasTailor == null ||
          (activeFilter.hasTailor!
              ? item['Tailor Assigned'] != 'No Tailor'
              : item['Tailor Assigned'] == 'No Tailor');

      return matchesSearch && matchesStatus && matchesTailor;
    }).toList();

    final totalPages = (filteredData.length / rowsPerPage).ceil();
    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filteredData.length);
    final pagedData = filteredData.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6082B6),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CustomerHomePage()),
              (route) => false,
            );
          },
        ),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      floatingActionButton: _buildChatButton(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    'Product Status',
                    style: TextStyle(
                      fontFamily: 'JainiPurva',
                      fontSize: 25,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        _buildTableHeader(headers),
                        ...pagedData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          return _buildDataRow(
                            headers,
                            row,
                            index == pagedData.length - 1,
                          );
                        }),
                        if (totalPages > 1) _buildPagination(totalPages),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    final fontSize = context.watch<FontProvider>().fontSize;
    return Container(
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showModalBottomSheet<ProductFilter>(
                context: context,
                builder: (_) => FilterSheet(currentFilter: activeFilter),
              );
              if (result != null) {
                setState(() {
                  activeFilter = result;
                  currentPage = 0;
                  isLoading = true;
                });
                await _loadData();
              }
            },
            icon: const Icon(Icons.tune, size: 18),
            label: Text('Filter', style: TextStyle(fontSize: fontSize)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search_sharp),
                hintText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() {
                searchQuery = value;
                currentPage = 0;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF6082B6),
      onPressed: () async {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('Appointment Forms')
              .where('customerId', isEqualTo: currentUserId)
              .where('tailorId', isNotEqualTo: null)
              .get();

          if (snapshot.docs.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No tailor has been assigned yet.")),
            );
            return;
          }

          Map<String, String> tailorMap = {};

          for (var doc in snapshot.docs) {
            final tailorId = doc['tailorId']?.toString();
            if (tailorId != null && !tailorMap.containsKey(tailorId)) {
              final tailorDoc = await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(tailorId)
                  .get();
              if (tailorDoc.exists) {
                final tailorName =
                    tailorDoc.data()?['shopName'] ?? 'Unknown Tailor';
                tailorMap[tailorId] = tailorName;
              }
            }
          }

          if (tailorMap.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No valid tailor found.")),
            );
            return;
          }

          String selectedTailorId;
          if (tailorMap.length == 1) {
            selectedTailorId = tailorMap.keys.first;
          } else {
            final result = await showDialog<String>(
              context: context,
              builder: (context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  backgroundColor: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Select a Tailor",
                          style: GoogleFonts.chauPhilomeneOne(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: ListView(
                            children: tailorMap.entries.map((entry) {
                              return GestureDetector(
                                onTap: () => Navigator.pop(context, entry.key),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 30,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[50],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.blueGrey.shade100,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.blueGrey,
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.red[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            if (result == null) return;
            selectedTailorId = result;
          }

          final chatId = await _getOrCreateChat(
            currentUserId,
            selectedTailorId,
          );

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerChatFunction(
                chatId: chatId,
                currentUserId: currentUserId,
                otherUserId: selectedTailorId,
                customerId: currentUserId,
              ),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Failed to open chat.")));
          print("Error opening chat: $e");
        }
      },
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    final fontSize = context.watch<FontProvider>().fontSize;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey),
          bottom: BorderSide(color: Colors.grey),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                headers[0],
                style: TextStyle(
                  fontSize: fontSize + 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                headers[1],
                style: TextStyle(
                  fontSize: fontSize + 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              _pageNavIcon(Icons.arrow_back_ios, sectionPageIndex > 0, () {
                setState(() {
                  sectionPageIndex--;
                  currentPage = 0;
                });
              }),
              const SizedBox(width: 5),
              _pageNavIcon(
                Icons.arrow_forward_ios,
                sectionPageIndex < sectionHeaders.length - 1,
                () {
                  setState(() {
                    sectionPageIndex++;
                    currentPage = 0;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageNavIcon(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Tooltip(
        message: icon == Icons.arrow_back_ios
            ? 'Previous section'
            : 'Next section',
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey[300] : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 15,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(
    List<String> headers,
    Map<String, dynamic> row,
    bool isLast,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Colors.grey)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final header in headers)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildCellContent(header, row),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          return GestureDetector(
            onTap: () => setState(() => currentPage = index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? Colors.blueGrey
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCellContent(String header, Map<String, dynamic> row) {
    final fontSize = context.watch<FontProvider>().fontSize;
    final value = row[header];

    // --- Customer Name ---
    if (header == 'Customer Name' || header == 'customerName') {
      final customerName = row['customerName']?.toString() ?? '-';
      return Text(
        customerName.isNotEmpty ? customerName : '-',
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
      );
    }

    // --- Shop Name ---
    if (header == 'Shop' || header == 'shopName') {
      final shopName = row['shopName']?.toString() ?? '-';
      return Text(
        shopName.isNotEmpty ? shopName : '-',
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
      );
    }

    // --- Tailor Assigned ---
    if (header == 'Tailor Assigned') {
      final text = value?.toString() ?? 'No Tailor';
      final isNoTailor = text == 'No Tailor';
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: isNoTailor ? Colors.red : const Color(0xFF3A8326),
          fontWeight: isNoTailor ? FontWeight.bold : FontWeight.w500,
        ),
      );
    }

    // --- Status ---
    if (header == 'Status') {
      final text = value?.toString() ?? '';
      Color borderColor, backgroundColor, dotColor;
      switch (text) {
        case 'Pending Tailor Response':
          borderColor = Colors.orange;
          backgroundColor = Colors.orange.withOpacity(0.1);
          dotColor = Colors.orange;
          break;
        case 'Accepted':
          borderColor = Colors.green;
          backgroundColor = Colors.green.withOpacity(0.1);
          dotColor = Colors.green;
          break;
        case 'Available':
          borderColor = Colors.green;
          backgroundColor = Colors.green.withOpacity(0.1);
          dotColor = Colors.green;
          break;

        case 'Cancelled':
        case 'Rejected':
          borderColor = Colors.red;
          backgroundColor = Colors.red.withOpacity(0.1);
          dotColor = Colors.red;
          break;
        case 'Completed':
          borderColor = Colors.blueGrey;
          backgroundColor = Colors.blueGrey.withOpacity(0.1);
          dotColor = Colors.blueGrey;
          break;
        case 'Overdue':
          borderColor = const Color(0xFF9A3F3F);
          backgroundColor = const Color(0xFF9A3F3F).withOpacity(0.1);
          dotColor = const Color(0xFF9A3F3F);
          break;
        case 'Waiting Customer Response':
          borderColor = const Color(0xFFF87B1B);
          backgroundColor = const Color(0xFFF87B1B).withOpacity(0.1);
          dotColor = const Color(0xFFF87B1B);
          break;
        default:
          borderColor = Colors.grey;
          backgroundColor = Colors.grey.withOpacity(0.1);
          dotColor = Colors.grey;
      }
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (header == 'Receipt') {
      final appointmentId = value?.toString() ?? '';
      if (appointmentId.isEmpty) {
        return const Text('-', style: TextStyle(color: Colors.grey));
      }

      return GestureDetector(
        onTap: () async {
          try {
            final docSnapshot = await FirebaseFirestore.instance
                .collection('Appointment Forms')
                .doc(appointmentId)
                .get();

            if (!docSnapshot.exists) return;

            final data = docSnapshot.data()!;
            final price = data['price'];
            final tailorAssigned = data['tailorAssigned']?.toString() ?? '';

            if (price == null ||
                price.toString().isEmpty ||
                tailorAssigned.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Receipt not available yet. Tailor or price is pending.',
                    ),
                  ),
                );
              }
              return;
            }

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptPage(appointmentId: appointmentId),
              ),
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to open receipt.')),
              );
            }
            print('Error opening receipt: $e');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1565C0), width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.receipt_long, color: Color(0xFF1565C0), size: 18),
                SizedBox(width: 6),
                Text(
                  'View Receipt',
                  style: TextStyle(color: Color(0xFF1565C0)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (header == 'Report') {
      final reportId = value?.toString() ?? '';
      if (reportId.isEmpty) {
        return const Text('-', style: TextStyle(color: Colors.grey));
      }
      return GestureDetector(
        onTap: () async {
          try {
            final docSnapshot = await FirebaseFirestore.instance
                .collection('Appointment Forms')
                .doc(reportId)
                .get();

            if (!docSnapshot.exists) throw 'Report not found';
            final data = docSnapshot.data()!;
            final customerDisplay = (data['fullName'] ?? 'Unknown Customer')
                .toString();
            final tailorAssigned = (data['tailorAssigned'] ?? '').toString();
            final tailorId = (data['tailorId'] ?? '').toString();

            final tailorDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(tailorId)
                .get();

            final shopName = tailorDoc.exists
                ? (tailorDoc.data()?['shopName'] ?? 'Unknown Shop')
                : 'Unknown Shop';

            final tailorDisplay =
                (tailorAssigned.isNotEmpty && shopName.isNotEmpty)
                ? '$tailorAssigned - $shopName'
                : tailorAssigned.isNotEmpty
                ? tailorAssigned
                : shopName.isNotEmpty
                ? shopName
                : 'Unknown Shop';

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportPage(
                  customerName: customerDisplay,
                  shopName: tailorDisplay,
                ),
              ),
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to open report')),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A6FA5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4A6FA5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, color: Color(0xFF4A6FA5), size: 18),
              const SizedBox(width: 6),
              Text(
                'View Report',
                style: TextStyle(
                  fontSize: fontSize,
                  color: const Color(0xFF4A6FA5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (header == 'Order Received') {
      final received = row['orderReceived'] ?? false;
      final status = row['status'] ?? '';

      if (status != 'Completed') {
        return Text('-', style: TextStyle(color: Colors.grey));
      }
      return Text(
        received ? 'Received' : 'Pending',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: received ? Colors.green : Colors.orange,
        ),
      );
    }

    if (header == 'Review') {
      final received = row['orderReceived'] ?? false;
      final reviewSubmitted = row['reviewSubmitted'] ?? false;
      final appointmentId = row['Order Received'] ?? '';
      final tailorId = row['tailorId'] ?? '';

      if (!received) return const SizedBox();

      if (reviewSubmitted) {
        return Text(
          'Reviewed',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        );
      }

      return GestureDetector(
        onTap: () async {
          if (tailorId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tailor not assigned yet.')),
            );
            return;
          }

          try {
            final tailorDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(tailorId)
                .get();

            if (!tailorDoc.exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tailor data not found.')),
              );
              return;
            }

            final data = tailorDoc.data()!;

            final availabilityMap =
                data['availability'] as Map<String, dynamic>? ?? {};
            final servicesList =
                availabilityMap['servicesOffered'] as List<dynamic>? ?? [];
            final expertiseString = servicesList.isNotEmpty
                ? servicesList.join(', ')
                : 'Not specified';

            final availabilityData = data['availability'] ?? {};
            final days = (availabilityData['days'] ?? []).join(', ');
            final timeSlot = availabilityData['timeSlot'] ?? '';
            final availabilityString = (days.isNotEmpty || timeSlot.isNotEmpty)
                ? "$days | $timeSlot"
                : 'Not specified';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RatingandReviewPage(
                  appointmentId: appointmentId,
                  tailorId: tailorId,
                  tailorName: data['shopName'] ?? 'Unknown Tailor',
                  tailorPhone: data['businessNumber'] ?? 'N/A',
                  tailorEmail: data['email'] ?? 'N/A',
                  tailorImage: data['profileImageUrl'] ?? '',
                  tailorShop: data['shopName'] ?? 'N/A',
                  availability: availabilityString,
                  expertise: expertiseString,
                  status: data['isAvailable'] == true
                      ? 'Available'
                      : 'Unavailable',
                  location: data['fullAddress'] ?? 'N/A',
                ),
              ),
            );
          } catch (e) {
            print('Error opening review page: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to open review page.')),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Text('Write Review', style: TextStyle(color: Colors.blue)),
        ),
      );
    }
    return Text(
      value?.toString() ?? '',
      style: TextStyle(fontSize: fontSize),
      textAlign: TextAlign.left,
    );
  }
}

String _formatCellValue(String header, dynamic value) {
  if (value == null) return '';
  if (value is Timestamp) {
    return DateFormat('MMMM dd, yyyy • hh:mm a').format(value.toDate());
  }
  return value.toString();
}

class FilterSheet extends StatefulWidget {
  final ProductFilter currentFilter;
  const FilterSheet({super.key, required this.currentFilter});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? status;
  bool? hasTailor;

  @override
  void initState() {
    super.initState();
    status = widget.currentFilter.status;
    hasTailor = widget.currentFilter.hasTailor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Text(
            'Filter Appointments',
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 25),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Status',
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: status,
                isExpanded: true,
                hint: const Text('Select Status'),
                items: ['Pending', 'Accepted', 'Rejected']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => status = v),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SwitchListTile(
              title: const Text('Has Tailor Assigned'),
              subtitle: const Text(
                'Toggle off to show appointments without a tailor',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: hasTailor ?? false,
              activeColor: const Color(0xFF4CAF50),
              onChanged: (v) => setState(() => hasTailor = v),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    status = null;
                    hasTailor = null;
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Reset',
                  style: GoogleFonts.novaSquare(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB44646),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(
                    context,
                    ProductFilter(status: status, hasTailor: hasTailor),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6082B6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  'Apply Filter',
                  style: GoogleFonts.novaSquare(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
