import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:threadhub_system/Admin/pages/sidebar/admin%20appointment/admin_receipt.dart';
import 'package:threadhub_system/Admin/pages/sidebar/admin_notification.dart';
import 'package:threadhub_system/Admin/pages/sidebar/menu.dart';

class AdminAppointmentPage extends StatefulWidget {
  const AdminAppointmentPage({super.key});

  @override
  State<AdminAppointmentPage> createState() => _AdminAppointmentPageState();
}

class _AdminAppointmentPageState extends State<AdminAppointmentPage> {
  bool isLoading = true;
  int currentPage = 0;
  int sectionPageIndex = 0;
  final int rowsPerPage = 7;
  String searchQuery = "";

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _calendarExpanded = true;
  bool _appointmentsExpanded = true;

  final List<List<String>> sectionHeaders = [
    ['Customer Name', 'Service Type'],
    ['Status', 'Needed By Date'],
    ['Order', 'Tailor Assigned'],
    ['Receipt', 'Yield ID'],
    ['Order Received', 'Review'],
  ];

  List<List<Map<String, dynamic>>> sectionData = [[], [], [], [], []];
  int totalAppointments = 0;

  Map<String, List<Map<String, dynamic>>> appointmentsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _dateToKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      final snapshot = await FirebaseFirestore.instance
          .collection('Appointment Forms')
          .orderBy('timestamp', descending: true)
          .get();

      totalAppointments = snapshot.docs.length;

      List<Map<String, dynamic>> customerService = [];
      List<Map<String, dynamic>> statusNeededBy = [];
      List<Map<String, dynamic>> orderTailor = [];
      List<Map<String, dynamic>> receiptYield = [];
      List<Map<String, dynamic>> orderReview = [];

      appointmentsByDate.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final fullName = data['fullName'] ?? 'Unknown';
        final status = data['status'] ?? '';
        final services = data['services'] ?? '';
        final garmentSpec = data['garmentSpec'] ?? '';
        final tailorAssigned =
            (data['tailorAssigned'] != null &&
                data['tailorAssigned'].toString().trim().isNotEmpty)
            ? data['tailorAssigned']
            : 'No Tailor';
        final appointmentId = doc.id;
        final dueDateTime = data['dueDateTime'];

        customerService.add({
          'Customer Name': fullName,
          'Service Type': services,
        });

        statusNeededBy.add({
          'Status': status,
          'Needed By Date': _formatCellValue(dueDateTime),
        });

        orderTailor.add({
          'Order': garmentSpec,
          'Tailor Assigned': tailorAssigned,
        });

        receiptYield.add({'Receipt': appointmentId, 'Yield ID': appointmentId});

        orderReview.add({
          'Order Received': data['orderReceived'] ?? false,
          'Review': data['reviewSubmitted'] ?? false,
        });
        DateTime dateKey;
        if (dueDateTime is Timestamp) {
          final dt = dueDateTime.toDate();
          dateKey = DateTime(dt.year, dt.month, dt.day);
        } else if (dueDateTime is DateTime) {
          dateKey = DateTime(
            dueDateTime.year,
            dueDateTime.month,
            dueDateTime.day,
          );
        } else if (dueDateTime is String) {
          try {
            final dt = DateTime.parse(dueDateTime);
            dateKey = DateTime(dt.year, dt.month, dt.day);
          } catch (e) {
            continue;
          }
        } else {
          continue;
        }

        final dateKeyString = _dateToKey(dateKey);

        if (!appointmentsByDate.containsKey(dateKeyString)) {
          appointmentsByDate[dateKeyString] = [];
        }
        appointmentsByDate[dateKeyString]!.add(data);
      }

      if (!mounted) return;
      setState(() {
        sectionData = [
          customerService,
          statusNeededBy,
          orderTailor,
          receiptYield,
          orderReview,
        ];
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headers = sectionHeaders[sectionPageIndex];
    final List<Map<String, dynamic>> allData = sectionData
        .expand((section) => section)
        .toList();

    final filteredData =
        (searchQuery.isEmpty ? sectionData[sectionPageIndex] : allData)
            .where(
              (item) => item.values.any(
                (value) => value.toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              ),
            )
            .toList();

    final totalPages = (filteredData.length / rowsPerPage).ceil();
    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filteredData.length);
    final pagedData = filteredData.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6082B6),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('toAdmin', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.black),
                  onPressed: () {},
                );
              }

              final notifications = snapshot.data!.docs;
              final unread = notifications.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final readBy = data['readBy'] ?? [];
                return !(readBy as List).contains('admin');
              }).length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminNotificationPage(),
                        ),
                      );
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      drawer: const Menu(),
      backgroundColor: const Color(0xFFD9D9D9),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Number of Appointments',
                      style: GoogleFonts.sometypeMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 35,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '$totalAppointments',
                        style: GoogleFonts.sometypeMono(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Appointment Details',
                      style: GoogleFonts.sometypeMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSearchBar(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildTableHeader(headers),
                        ...pagedData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          return _buildDataRow(
                            headers,
                            row,
                            isLast: index == pagedData.length - 1,
                          );
                        }),
                        if (totalPages > 1) _buildPagination(totalPages),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCalendar(),
                  const SizedBox(height: 12),
                  if (_selectedDay != null)
                    _buildAppointmentsListForSelectedDay(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Calendar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  _calendarExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 26,
                ),
                onPressed: () {
                  setState(() => _calendarExpanded = !_calendarExpanded);
                },
              ),
            ],
          ),

          if (_calendarExpanded)
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              availableGestures: AvailableGestures.horizontalSwipe,

              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (isSameDay(day, _selectedDay)) return null;
                  final appointments =
                      appointmentsByDate[_dateToKey(day)] ?? [];
                  if (appointments.isNotEmpty) {
                    return Positioned(
                      bottom: 3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),

              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                markersAnchor: 1.2,
              ),

              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsListForSelectedDay() {
    final dayAppointments = appointmentsByDate[_dateToKey(_selectedDay!)] ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Appointments on this day',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  _appointmentsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onPressed: () {
                  setState(() {
                    _appointmentsExpanded = !_appointmentsExpanded;
                  });
                },
              ),
            ],
          ),
          if (_appointmentsExpanded)
            dayAppointments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No appointments for this day.'),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Service')),
                        DataColumn(label: Text('Tailor')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: dayAppointments.map((data) {
                        return DataRow(
                          cells: [
                            DataCell(Text(data['fullName'] ?? '-')),
                            DataCell(Text(data['services'] ?? '-')),
                            DataCell(
                              Text(data['tailorAssigned'] ?? 'No Tailor'),
                            ),
                            DataCell(Text(data['status'] ?? '-')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onChanged: (value) => setState(() {
          searchQuery = value;
          currentPage = 0;
        }),
      ),
    );
  }

  Widget _buildTableHeader(List<String> headers) {
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
          for (final header in headers)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  header,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
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

  Widget _buildDataRow(
    List<String> headers,
    Map<String, dynamic> row, {
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Colors.grey)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? Colors.blueGrey
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCellContent(String header, Map<String, dynamic> row) {
    final value = row[header];

    switch (header) {
      case 'Customer Name':
      case 'Service Type':
        return Text(
          value?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        );

      case 'Status':
        final text = value?.toString() ?? '';
        Color borderColor, bgColor, dotColor;
        switch (text) {
          case 'Pending Tailor Response':
            borderColor = Colors.orange;
            bgColor = Colors.orange.withOpacity(0.1);
            dotColor = Colors.orange;
            break;
          case 'Accepted':
            borderColor = Colors.green;
            bgColor = Colors.green.withOpacity(0.1);
            dotColor = Colors.green;
            break;

          case 'Available':
            borderColor = Colors.green;
            bgColor = Colors.green.withOpacity(0.1);
            dotColor = Colors.green;
            break;
          case 'Canceled':
          case 'Declined':
            borderColor = Colors.red;
            bgColor = Colors.red.withOpacity(0.1);
            dotColor = Colors.red;
            break;
          case 'Completed':
            borderColor = Colors.blueGrey;
            bgColor = Colors.blueGrey.withOpacity(0.1);
            dotColor = Colors.blueGrey;
            break;
          case 'Waiting Customer Response':
            borderColor = Color(0xFF803D3B);
            bgColor = Color(0xFF803D3B).withOpacity(0.1);
            dotColor = Color(0xFF803D3B);
            break;
          default:
            borderColor = Colors.grey;
            bgColor = Colors.grey.withOpacity(0.1);
            dotColor = Colors.grey;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
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
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(color: borderColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );

      case 'Tailor Assigned':
        final text = value?.toString() ?? 'No Tailor';
        final isNoTailor = text == 'No Tailor';
        return Text(
          text,
          style: TextStyle(color: isNoTailor ? Colors.red : Colors.green),
        );

      case 'Needed By Date':
      case 'Order':
      case 'Yield ID':
        return Text(value?.toString() ?? '-');

      case 'Receipt':
        return GestureDetector(
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdminReceiptPage(appointmentId: value.toString()),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'View Receipt',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        );

      case 'Order Received':
        return Text(
          value == true ? 'Yes' : 'No',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: value == true ? Colors.green : Colors.orange,
          ),
        );

      case 'Review':
        return Text(
          value == true ? 'Submitted' : 'Not Submitted',
          style: TextStyle(color: value == true ? Colors.blue : Colors.black87),
        );

      default:
        return Text(value?.toString() ?? '-');
    }
  }
}

Widget _pageNavIcon(IconData icon, bool enabled, VoidCallback onTap) {
  return GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey[300] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 15, color: enabled ? Colors.black : Colors.grey),
    ),
  );
}

String _formatCellValue(dynamic value) {
  if (value == null) return '';

  DateTime dateTime;

  if (value is Timestamp) {
    dateTime = value.toDate();
  } else if (value is DateTime) {
    dateTime = value;
  } else if (value is String) {
    try {
      dateTime = DateTime.parse(value);
    } catch (e) {
      return value;
    }
  } else {
    return value.toString();
  }

  return DateFormat('MMMM dd, yyyy • hh:mm a').format(dateTime);
}
