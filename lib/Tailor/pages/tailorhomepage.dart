import 'dart:io';
import 'package:threadhub_system/Pages/notification_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor%20report/tailor_reportpage.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_notification.dart'
    hide AppNotification;
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/help%20center/chatbox.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_ratingsandreviews.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_shopperformancereport.dart';

class TailorHomePage extends StatefulWidget {
  final bool showAccepted;
  final String? initialTab;
  final String? selectedAppointmentId;

  const TailorHomePage({
    super.key,
    this.initialTab,
    this.selectedAppointmentId,
    required this.showAccepted,
  });

  @override
  State<TailorHomePage> createState() => _TailorHomePageState();
}

class _TailorHomePageState extends State<TailorHomePage> {
  void _openMenu() {
    final tailorfontSize = Provider.of<TailorFontprovider>(
      context,
      listen: false,
    ).fontSize;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext dialogContext) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 56),
              width: 250,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItemTap(
                    Icons.notifications,
                    "Notification",
                    backgroundColor: const Color(0xFFD9D9D9),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TailorNotificationPage(
                            tailorId:
                                FirebaseAuth.instance.currentUser?.uid ??
                                'unknown',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItemTap(
                    Icons.home,
                    "Home",
                    backgroundColor: const Color(0xFF4C516D),
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TailorHomePage(showAccepted: true),
                        ),
                      );
                    },
                  ),
                  _buildMenuItemTap(
                    Icons.person,
                    "Profile Settings",
                    backgroundColor: const Color(0xFFD9D9D9),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TailorProfileSettingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItemTap(
                    Icons.rate_review,
                    "Rating and Reviews",
                    backgroundColor: const Color(0xFF4C516D),
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TailorRatingsandreviewsPage(
                            tailorId:
                                FirebaseAuth.instance.currentUser?.uid ?? '',
                          ),
                        ),
                      );
                    },
                  ),

                  _buildMenuItemTap(
                    Icons.bar_chart,
                    "Shop Performance Report",
                    backgroundColor: const Color(0xFFD9D9D9),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TailorShopperformancereport(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Future<String> _getOrCreateChat(String customerId, String tailorId) async {
    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('customerId', isEqualTo: customerId)
        .where('tailorId', isEqualTo: tailorId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      return chatQuery.docs.first.id;
    }

    final newChat = await FirebaseFirestore.instance.collection('chats').add({
      'customerId': customerId,
      'tailorId': tailorId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  int selectedIndex = 0;

  final List<String> tabs = [
    "Pending Orders",
    "Finished Orders",
    "Canceled Orders",
  ];

  // Search Related Function
  final TextEditingController _searchbarController = TextEditingController();
  String searchQuery = '';
  bool _isSearching = false;

  String _tailorName = '';
  bool _isLoadingTailor = true;

  Future<void> _loadTailorName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _tailorName = doc.data()?['fullName'] ?? 'Unknown Tailor';
            _isLoadingTailor = false;
          });
        }
      }
    } catch (e) {
      print('Error loading tailor name: $e');
      setState(() => _isLoadingTailor = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTailorName();
    _searchbarController.addListener(() {
      setState(() {
        searchQuery = _searchbarController.text;
        _isSearching = searchQuery.isNotEmpty;
      });
    });
    _checkDueDateReminders();

    Future.delayed(const Duration(minutes: 5), () async {
      while (mounted) {
        await _checkDueDateReminders();
        await Future.delayed(const Duration(hours: 1));
      }
    });

    if (widget.selectedAppointmentId != null) {
      _fetchAppointment(widget.selectedAppointmentId!);
    }
  }

  @override
  void dispose() {
    _searchbarController.dispose();
    super.dispose();
  }

  Future<void> _checkDueDateReminders() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('Appointment Forms')
        .where('tailorId', isEqualTo: currentUid)
        .where('status', whereIn: ['Accepted', 'On going', 'Pending'])
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['dueDateTime'] == null) continue;

      final dueDate = (data['dueDateTime'] as Timestamp).toDate();
      final difference = dueDate.difference(now);
      final hoursLeft = difference.inHours;
      final daysLeft = difference.inDays;

      if (dueDate.isBefore(now)) {
        if (data['status'] != 'Overdue') {
          try {
            await FirebaseFirestore.instance
                .collection('Appointment Forms')
                .doc(doc.id)
                .update({'status': 'Overdue'});
            await FirebaseFirestore.instance.collection('notifications').add({
              'title': 'Order Overdue',
              'body':
                  "The order for ${data['garmentSpec'] ?? 'a garment'} is now overdue.",
              'appointmentId': doc.id,
              'recipientType': 'tailor',
              'recipientId': currentUid,
              'timestamp': FieldValue.serverTimestamp(),
              'readBy': <String>[],
            });

            await FirebaseFirestore.instance.collection('notifications').add({
              'title': 'Order Overdue',
              'body':
                  "Your order for ${data['garmentSpec'] ?? 'a garment'} is now overdue. Please contact your tailor for updates.",
              'appointmentId': doc.id,
              'recipientType': 'customer',
              'recipientId': data['customerId'],

              'timestamp': FieldValue.serverTimestamp(),
              'readBy': <String>[],
            });
          } catch (e) {
            print('Error updating overdue status or sending notifications: $e');
          }
        }
        continue;
      }

      String? message;
      if (daysLeft >= 2 && daysLeft <= 3) {
        message =
            "Reminder: The order for ${data['garmentSpec'] ?? 'a garment'} is due in $daysLeft days.";
      } else if (daysLeft == 1) {
        message =
            "Urgent: The order for ${data['garmentSpec'] ?? 'a garment'} is due tomorrow!";
      } else if (hoursLeft <= 12 && hoursLeft > 0) {
        message =
            "Final Reminder: The order for ${data['garmentSpec'] ?? 'a garment'} is due in $hoursLeft hours!";
      }

      if (message != null) {
        final existingNotifs = await FirebaseFirestore.instance
            .collection('notifications')
            .where('to', isEqualTo: currentUid)
            .where('body', isEqualTo: message)
            .get();

        if (existingNotifs.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'to': currentUid,
            'title': 'Upcoming Due Date',
            'body': message,
            'appointmentId': doc.id,
            'recipientType': 'tailor',
            'recipientId': currentUid,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'readBy': <String>[],
          });
        }
      }
    }
  }

  Future<void> _acceptDelay(AppNotification notif) async {
    final appointmentId = notif.appointmentId;
    final tailorId = notif.appointmentId;
    final customerId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notif.id)
        .update({'accepted': true});

    await FirebaseFirestore.instance
        .collection('Appointment Forms')
        .doc(appointmentId)
        .update({
          'dueDateTime': DateTime.now().add(const Duration(days: 3)),
          'status': 'Accepted',
        });

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Customer Response',
      'body': 'The customer agreed to extend the deadline.',
      'appointmentId': appointmentId,
      'recipientType': 'tailor',
      'receipientId': tailorId,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    });
  }

  Future<void> _messageTailor(AppNotification notif) async {
    final appointmentId = notif.appointmentId;
    final tailorId = notif.tailorId;
    final customerId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Customer Response',
      'body': 'The customer wants to discuss the order.',
      'appointmentId': appointmentId,
      'recipientType': 'tailor',
      'recipientId': tailorId,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    });
    final chatId = await _getOrCreateChat(customerId, tailorId);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          currentUserId: customerId,
          otherUserId: tailorId,
          isTailor: false,
        ),
      ),
    );
  }

  Map<String, String> activeDetailMap = {};

  Map<String, dynamic>? _selectedAppointmentData;
  bool _isLoadingAppointment = false;

  Future<void> _fetchAppointment(String appointmentId) async {
    setState(() => _isLoadingAppointment = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Appointment Forms')
          .doc(appointmentId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _selectedAppointmentData = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointment: $e');
    } finally {
      setState(() => _isLoadingAppointment = false);
    }
  }

  Future<void> _sendNotification({
    required String toUserId,
    required String title,
    required String body,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'to': toUserId,
        'title': title,
        'body': body,
        'extra': extra ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Future<void> _markAsDone(
    String appointmentId,
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('Appointment Forms')
          .doc(appointmentId)
          .update({
            'status': 'Completed',
            'completedAt': FieldValue.serverTimestamp(),
          });

      final customerId =
          appointmentData['customerId'] ??
          appointmentData['customerID'] ??
          appointmentData['toCustomerId'];

      if (customerId != null && customerId.toString().isNotEmpty) {
        await _sendNotification(
          toUserId: customerId,
          title: 'Order Completed',
          body:
              'Hi there! Your order for ${appointmentData['garmentSpec'] ?? 'a garment'} has been marked as completed by the tailor.',
          extra: {'appointmentId': appointmentId},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as done successfully!')),
        );

        setState(() {
          selectedIndex = 1;
          activeDetailMap.clear();
        });
      }
    } catch (e) {
      debugPrint('Error marking as done: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to mark as done: $e')));
      }
    }
  }

  Future<void> _cancelAppointment(
    String appointmentId,
    String reason,
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      final cancellationDate = DateTime.now();

      await FirebaseFirestore.instance
          .collection('Appointment Forms')
          .doc(appointmentId)
          .update({
            'status': 'Cancelled',
            'cancellationReason': reason,
            'canceledAt': Timestamp.fromDate(cancellationDate),
          });

      final customerId =
          appointmentData['customerId'] ?? appointmentData['customerID'];

      if (customerId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'to': customerId,
          'title': 'Appointment Cancelled',
          'body':
              'Your appointment for ${appointmentData['garmentSpec']} has been cancelled by the tailor.',
          'extra': {
            'appointmentId': appointmentId,
            'reason': reason,
            'cancelledDate': cancellationDate.toIso8601String(),
          },
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment Cancelled Successfully')),
        );

        setState(() {
          selectedIndex = 2;
          activeDetailMap.clear();
        });
      }
    } catch (e) {
      debugPrint('Error canceling appointment: $e');
    }
  }

  Future<void> _notifyCustomer(
    Map<String, dynamic> appointmentData, {
    String customMessage = 'There is an update on your order.',
  }) async {
    final customerId =
        appointmentData['customerId'] ?? appointmentData['customerID'];
    if (customerId == null) return;
    await _sendNotification(
      toUserId: customerId,
      title: 'Update from Tailor',
      body: customMessage,
      extra: {'appointmentId': appointmentData['appointmentId']},
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer notified')));
  }

  @override
  Widget build(BuildContext context) {
    final tailorfontSize = context.watch<TailorFontprovider>().fontSize;
    return WillPopScope(
      onWillPop: () async {
        if (activeDetailMap.isNotEmpty) {
          setState(() {
            Map<String, String> activeDetailMap = {};
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _isSearching
              ? const Color(0xFF262633)
              : const Color(0xFF6082B6),
          leading: IconButton(
            icon: Icon(
              Icons.menu,
              color: _isSearching ? Colors.white : Colors.black,
            ),
            onPressed: _openMenu,
          ),
          title: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 230,
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: _searchbarController,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    hintText: 'Search...',
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.search, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: const Color(0xFFD9D9D9),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  height: 50,
                  width: 330,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0C4DE),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    'Work Orders',
                    style: GoogleFonts.poppins(
                      fontSize: tailorfontSize,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: List.generate(tabs.length, (index) {
                      bool isSelected = index == selectedIndex;
                      BorderRadius radius;
                      if (index == 0) {
                        radius = const BorderRadius.horizontal(
                          left: Radius.circular(50),
                        );
                      } else if (index == tabs.length - 1) {
                        radius = const BorderRadius.horizontal(
                          right: Radius.circular(50),
                        );
                      } else {
                        radius = BorderRadius.zero;
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                              activeDetailMap.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7C9A9A)
                                  : Colors.white,
                              border: Border.all(color: Colors.black),
                              borderRadius: radius,
                            ),
                            child: Text(
                              tabs[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 15),
                _buildOrderFrame(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderFrame() {
    switch (selectedIndex) {
      case 0:
        return _buildAcceptedAppointments();
      case 1:
        return _buildFinishedAppointments();
      case 2:
        return _buildCanceledAppointments();
      default:
        return const Center(child: Text("Unknown tab"));
    }
  }

  Widget _buildAcceptedAppointments() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const Center(child: Text("Not logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointment Forms')
          .where('tailorId', isEqualTo: currentUid)
          .where('customerstatus', isEqualTo: 'Accepted')
          .where('status', whereIn: ['Pending', 'Accepted', 'Overdue'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading orders: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No customer-accepted appointments yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final filteredAppointments = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final query = searchQuery.toLowerCase();

          final searchableFields = [
            data['fullName']?.toString().toLowerCase() ?? '',
            data['garmentSpec']?.toString().toLowerCase() ?? '',
            data['paymentStatus']?.toString().toLowerCase() ?? '',
            data['priority']?.toString().toLowerCase() ?? '',
            data['status']?.toString().toLowerCase() ?? '',
            data['services']?.toString().toLowerCase() ?? '',
            data['message']?.toString().toLowerCase() ?? '',
            data['tailorAssigned']?.toString().toLowerCase() ?? '',
          ];

          return searchableFields.any((field) => field.contains(query));
        }).toList();

        if (filteredAppointments.isEmpty) {
          return const Center(
            child: Text(
              "No matching appointments found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        if (filteredAppointments.isEmpty) {
          return const Center(
            child: Text(
              "No matching appointments found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final data =
                filteredAppointments[index].data() as Map<String, dynamic>;
            final appointmentId = filteredAppointments[index].id;

            final String currentActiveDetail =
                activeDetailMap[appointmentId] ?? "";
            data['appointmentId'] = appointmentId;

            return _pendingOrdersFrame(
              activeDetail: currentActiveDetail,
              onMeasurement: () {
                setState(() {
                  activeDetailMap[appointmentId] = "measurement";
                });
              },
              onMedia: () {
                setState(() {
                  activeDetailMap[appointmentId] = "media";
                });
              },
              onOtherDetails: () {
                setState(() {
                  activeDetailMap[appointmentId] = "otherdetails";
                });
              },
              onBack: () {
                setState(() {
                  activeDetailMap.remove(appointmentId);
                });
              },
              appointmentData: data,
              appointmentNumber: index + 1,
            );
          },
        );
      },
    );
  }

  Widget _buildFinishedAppointments() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const Center(child: Text("Not logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointment Forms')
          .where('tailorId', isEqualTo: currentUid)
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No finished orders yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        final filteredAppointments = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final query = searchQuery.toLowerCase();

          final searchableFields = [
            data['fullName']?.toString().toLowerCase() ?? '',
            data['garmentSpec']?.toString().toLowerCase() ?? '',
            data['paymentStatus']?.toString().toLowerCase() ?? '',
            data['priority']?.toString().toLowerCase() ?? '',
            data['status']?.toString().toLowerCase() ?? '',
            data['services']?.toString().toLowerCase() ?? '',
            data['message']?.toString().toLowerCase() ?? '',
            data['tailorAssigned']?.toString().toLowerCase() ?? '',

            if (data['dueDateTime'] != null)
              DateFormat('MMMM dd, yyyy')
                  .format((data['dueDateTime'] as Timestamp).toDate())
                  .toLowerCase(),
            if (data['dueDateTime'] != null)
              DateFormat('MMMM yyyy')
                  .format((data['dueDateTime'] as Timestamp).toDate())
                  .toLowerCase(),
            if (data['dueDateTime'] != null)
              DateFormat('MMMM')
                  .format((data['dueDateTime'] as Timestamp).toDate())
                  .toLowerCase(),
            if (data['appointmentDateTime'] != null)
              DateFormat('MMMM dd, yyyy')
                  .format((data['appointmentDateTime'] as Timestamp).toDate())
                  .toLowerCase(),
            if (data['appointmentDateTime'] != null)
              DateFormat('MMMM yyyy')
                  .format((data['appointmentDateTime'] as Timestamp).toDate())
                  .toLowerCase(),
            if (data['appointmentDateTime'] != null)
              DateFormat('MMMM')
                  .format((data['appointmentDateTime'] as Timestamp).toDate())
                  .toLowerCase(),
            if (data['canceledAt'] != null)
              DateFormat('MMMM dd, yyyy')
                  .format((data['canceledAt'] as Timestamp).toDate())
                  .toLowerCase(),
            if (data['canceledAt'] != null)
              DateFormat('MMMM yyyy')
                  .format((data['canceledAt'] as Timestamp).toDate())
                  .toLowerCase(),
            if (data['canceledAt'] != null)
              DateFormat('MMMM')
                  .format((data['canceledAt'] as Timestamp).toDate())
                  .toLowerCase(),
          ];

          return searchableFields.any((field) => field.contains(query));
        }).toList();

        if (filteredAppointments.isEmpty) {
          return const Center(
            child: Text(
              "No matching appointments found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        if (filteredAppointments.isEmpty) {
          return const Center(
            child: Text(
              "No matching appointments found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final appointments = filteredAppointments;

        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final data = appointments[index].data() as Map<String, dynamic>;
            final appointmentId = appointments[index].id;
            data['appointmentId'] = appointmentId;
            final String currentActiveDetail =
                activeDetailMap[appointmentId] ?? "";
            return _finishedOrdersFrame(
              activeDetail: currentActiveDetail,
              onMeasurement: () {
                setState(() {
                  activeDetailMap[appointmentId] = "menu";
                });
              },
              onMedia: () {
                setState(() {
                  activeDetailMap[appointmentId] = "media";
                });
              },
              onOtherDetails: () {
                setState(() {
                  activeDetailMap[appointmentId] = "otherdetails";
                });
              },
              onBack: () {
                setState(() {
                  activeDetailMap.remove(appointmentId);
                });
              },
              appointmentData: data,
              appointmentNumber: index + 1,
            );
          },
        );
      },
    );
  }

  Widget _buildCanceledAppointments() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const Center(child: Text("Not logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Appointment Forms')
          .where('tailorId', isEqualTo: currentUid)
          .where('status', isEqualTo: 'Cancelled')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No canceled orders yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final filteredAppointments = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final query = searchQuery.toLowerCase();

          final searchableFields = [
            data['fullName']?.toString().toLowerCase() ?? '',
            data['garmentSpec']?.toString().toLowerCase() ?? '',
            data['paymentStatus']?.toString().toLowerCase() ?? '',
            data['priority']?.toString().toLowerCase() ?? '',
            data['status']?.toString().toLowerCase() ?? '',
            data['services']?.toString().toLowerCase() ?? '',
            data['message']?.toString().toLowerCase() ?? '',
            data['tailorAssigned']?.toString().toLowerCase() ?? '',
          ];

          return searchableFields.any((field) => field.contains(query));
        }).toList();

        if (filteredAppointments.isEmpty) {
          return const Center(
            child: Text(
              "No matching appointments found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final data =
                filteredAppointments[index].data() as Map<String, dynamic>;
            final appointmentId = filteredAppointments[index].id;
            data['appointmentId'] = appointmentId;
            final String currentActiveDetail =
                activeDetailMap[appointmentId] ?? "";
            return _canceledOrdersFrame(
              activeDetail: currentActiveDetail,
              onBack: () {
                setState(() {
                  activeDetailMap.remove(appointmentId);
                });
              },
              onMeasurement: () {
                setState(() {
                  activeDetailMap[appointmentId] = "expanded";
                });
              },
              appointmentData: data,
              appointmentNumber: index + 1,
            );
          },
        );
      },
    );
  }

  TableRow buildTableRow({
    required BuildContext context,
    required String label,
    required String value,
    Color leftColor = const Color(0xFFC4E1E6),
    Color rightColor = Colors.white,
    VoidCallback? onPressed,
  }) {
    final tailorFontSize = context.watch<TailorFontprovider>().fontSize;
    Color textColor = Colors.black;

    if (label == "Priority") {
      if (value.toLowerCase().contains("low")) {
        textColor = Colors.green;
      } else if (value.toLowerCase().contains("medium")) {
        textColor = Colors.yellow[800]!;
      } else if (value.toLowerCase().contains("high")) {
        textColor = const Color(0xFF900707);
      }
    }

    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.fill,
          child: Container(
            color: leftColor,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              label,
              style: GoogleFonts.bebasNeue(
                fontWeight: FontWeight.w400,
                fontSize: tailorFontSize,
              ),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            color: rightColor,
            padding: const EdgeInsets.all(8.0),
            child:
                (label == "Measurement" ||
                    label == "Media Upload" ||
                    label == "Other Details")
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF72A0C1),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                    ),
                    onPressed: onPressed,
                    child: Text(
                      value,
                      style: GoogleFonts.bebasNeue(
                        fontWeight: FontWeight.w400,
                        fontSize: tailorFontSize + 3,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: GoogleFonts.inknutAntiqua(
                      fontWeight: FontWeight.w400,
                      fontSize: tailorFontSize - 2,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _pendingOrdersFrame({
    required String activeDetail,
    required VoidCallback onMeasurement,
    required VoidCallback onMedia,
    required VoidCallback onOtherDetails,
    required VoidCallback onBack,
    required Map<String, dynamic> appointmentData,
    required int appointmentNumber,
  }) {
    final tailorFontSize = context.watch<TailorFontprovider>().fontSize;
    final appointmentId = appointmentData['appointmentId'];
    final status = appointmentData['status'] ?? "Pending";
    final dueDate = (appointmentData['dueDateTime'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    bool isOverdue = false;

    if (status == "Overdue") {
      isOverdue = true;
    } else if (dueDate != null &&
        dueDate.isBefore(now) &&
        status != "Completed") {
      isOverdue = true;
    }

    String displayStatus = status;
    Color statusColor = Colors.orange;

    if (status == "Accepted") {
      displayStatus = "On going";
      statusColor = const Color(0xFFC66E52);
    }

    if (isOverdue) {
      displayStatus = "Overdue";
      statusColor = Colors.red;
    }
    int daysLate = 0;
    if (isOverdue && dueDate != null) {
      daysLate = now.difference(dueDate).inDays;
      if (daysLate < 1) daysLate = 1;
    }

    final tailorId = FirebaseAuth.instance.currentUser!.uid;
    final customerId =
        appointmentData['customerId'] ?? appointmentData['customerID'];

    return FutureBuilder<String>(
      future: _getOrCreateChat(customerId, tailorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Failed to load chat data."));
        }

        final chatId = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              color: isOverdue ? Colors.red.withOpacity(0.20) : Colors.white,
            ),

            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                appointmentData['fullName']?.trim() ??
                                    "Unknown",
                                style: GoogleFonts.bebasNeue(
                                  fontWeight: FontWeight.bold,
                                  fontSize: tailorFontSize + 4,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              appointmentNumber.toString().padLeft(3, '0'),
                              style: GoogleFonts.noticiaText(
                                fontSize: tailorFontSize - 2,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Text(
                                  displayStatus,
                                  style: GoogleFonts.noticiaText(
                                    fontSize: tailorFontSize - 2,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isOverdue) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    "• $daysLate day${daysLate > 1 ? 's' : ''} late",
                                    style: GoogleFonts.noticiaText(
                                      fontSize: tailorFontSize - 3,
                                      color: Colors.red.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (appointmentData['measurementMethod'] == 'Assisted')
                        InkWell(
                          onTap: () => _showEditMeasurementDialog(
                            context,
                            appointmentData,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 45,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF5F7F9),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.edit,
                                color: Colors.black54,
                                size: 26,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(width: 6),

                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                chatId: chatId,
                                currentUserId: tailorId,
                                otherUserId: customerId,
                                isTailor: true,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 45,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF5F7F9),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.message_rounded,
                              color: Colors.black54,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8DA399),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (activeDetail.isEmpty) ...[
                        _buildMainPendingContent(
                          context,
                          appointmentData,
                          onMeasurement,
                          onMedia,
                          onOtherDetails,
                          onBack,
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        if (activeDetail == "measurement")
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: measurementDetailsTable(
                              context,
                              Map<String, dynamic>.from(
                                appointmentData['manualMeasurements'] ??
                                    appointmentData['measurements'] ??
                                    {},
                              ),
                            ),
                          )
                        else if (activeDetail == "media")
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: mediaDetailsTable(
                              context,
                              _extractMediaList(appointmentData) ?? [],
                            ),
                          )
                        else if (activeDetail == "otherdetails")
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: otherDetailsTable(
                              context,
                              appointmentData['toCustomerId'] as String?,
                            ),
                          ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 20,
                              bottom: 8,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF72A0C1),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onPressed: onBack,
                              child: Text(
                                "Back",
                                style: GoogleFonts.noticiaText(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainPendingContent(
    BuildContext context,
    Map<String, dynamic> appointmentData,
    VoidCallback onMeasurement,
    VoidCallback onMedia,
    VoidCallback onOtherDetails,
    VoidCallback onBack,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(2.5),
                },
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.black12),
                ),
                children: [
                  buildTableRow(
                    context: context,
                    label: "Method",
                    value: appointmentData['measurementMethod'] ?? "N/A",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Measurement",
                    value: "Details",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                    onPressed: onMeasurement,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Media Upload",
                    value: "See Media",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                    onPressed: onMedia,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Other Details",
                    value: "See Other Details",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                    onPressed: onOtherDetails,
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.fill,
                        child: Container(
                          color: const Color(0xFFE8F9FF),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Payment Status",
                            style: GoogleFonts.bebasNeue(
                              fontWeight: FontWeight.w400,
                              fontSize: context
                                  .watch<TailorFontprovider>()
                                  .fontSize,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(8.0),
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Appointment Forms')
                                .doc(appointmentData['appointmentId'])
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return SizedBox.shrink();
                              final data =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              final currentStatus =
                                  data['paymentStatus'] ?? "None";
                              List<String> allowedOptions;
                              switch (currentStatus) {
                                case "None":
                                  allowedOptions = [
                                    "Unpaid",
                                    "Partially Paid",
                                    "Fully Paid",
                                  ];
                                  break;
                                case "Unpaid":
                                  allowedOptions = [
                                    "Partially Paid",
                                    "Fully Paid",
                                  ];
                                  break;
                                case "Partially Paid":
                                  allowedOptions = ["Fully Paid"];
                                  break;
                                case "Fully Paid":
                                  allowedOptions = ["Fully Paid"];
                                  break;
                                default:
                                  allowedOptions = [
                                    "Unpaid",
                                    "Partially Paid",
                                    "Fully Paid",
                                  ];
                              }

                              return DropdownButton<String>(
                                value: currentStatus,
                                items: const [
                                  DropdownMenuItem(
                                    value: "None",
                                    child: Text("None"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Unpaid",
                                    child: Text("Unpaid"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Partially Paid",
                                    child: Text("Partially Paid"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Fully Paid",
                                    child: Text("Fully Paid"),
                                  ),
                                ],
                                onChanged: (newValue) async {
                                  if (newValue != null &&
                                      allowedOptions.contains(newValue)) {
                                    await FirebaseFirestore.instance
                                        .collection('Appointment Forms')
                                        .doc(appointmentData['appointmentId'])
                                        .update({'paymentStatus': newValue});
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Payment status updated to $newValue",
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "You can't go back to a previous payment status.",
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  buildTableRow(
                    context: context,
                    label: "Tailor Assigned",
                    value: appointmentData['tailorAssigned'] ?? "N/A",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Service Type",
                    value: appointmentData['services'] ?? "N/A",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Message",
                    value: appointmentData['message'] ?? "No message provided",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(2.5),
                },
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.black12),
                ),
                children: [
                  buildTableRow(
                    context: context,
                    label: "Order",
                    value: appointmentData['garmentSpec'] ?? "N/A",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Appointment Date",
                    value: appointmentData['appointmentDateTime'] != null
                        ? DateFormat('MMMM dd, yyyy • h:mm a').format(
                            (appointmentData['dueDateTime'] as Timestamp)
                                .toDate(),
                          )
                        : "Unknown",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Due Date",
                    value: appointmentData['dueDateTime'] != null
                        ? DateFormat('MMMM dd, yyyy • h:mm a').format(
                            (appointmentData['dueDateTime'] as Timestamp)
                                .toDate(),
                          )
                        : "Unknown",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Priority",
                    value: appointmentData['priority'] ?? "Normal",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                  buildTableRow(
                    context: context,
                    label: "Price",
                    value: appointmentData['tailorPrice'] != null
                        ? "PHP ${appointmentData['tailorPrice']}"
                        : "N/A",
                    leftColor: const Color(0xFFE8F9FF),
                    rightColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF72A0C1),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  onPressed: () => _markAsDone(
                    appointmentData['appointmentId'],
                    appointmentData,
                  ),
                  child: Text(
                    'Mark as Done',
                    style: GoogleFonts.noticiaText(fontWeight: FontWeight.w600),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB82132),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TailorReportPage(
                          appointmentId: appointmentData['appointmentId'],
                          customerName:
                              appointmentData['fullName'] ?? 'Unknown',
                          respondentName: _tailorName,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Report this User',
                    style: GoogleFonts.noticiaText(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9AA6B2),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
              onPressed: () {
                showReasonDialog(
                  context: context,
                  title: "Cancel Appointment",

                  onSave: (reason) async {
                    await _cancelAppointment(
                      appointmentData['appointmentId'],
                      reason,
                      appointmentData,
                    );
                  },
                );
              },
              child: Text(
                'Cancel Appointment',
                style: GoogleFonts.noticiaText(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget measurementDetailsTable(
    BuildContext context,
    Map<String, dynamic>? measurements,
  ) {
    if (measurements == null || measurements.isEmpty) {
      return const Text("No measurement details available.");
    }

    final List<TableRow> rows = [];

    measurements.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        value.forEach((subKey, subValue) {
          rows.add(
            buildTableRow(
              context: context,
              label: "$key • $subKey",
              value: subValue.toString(),
              leftColor: const Color(0xFFE8F9FF),
              rightColor: Colors.white,
            ),
          );
        });
      } else {
        rows.add(
          buildTableRow(
            context: context,
            label: key,
            value: value.toString(),
            leftColor: const Color(0xFFE8F9FF),
            rightColor: Colors.white,
          ),
        );
      }
    });

    return Table(
      columnWidths: const {0: FlexColumnWidth(3.5), 1: FlexColumnWidth(1.5)},
      border: TableBorder.symmetric(
        inside: const BorderSide(color: Colors.black12),
      ),
      children: rows,
    );
  }

  Widget mediaDetailsTable(BuildContext context, List<dynamic>? mediaFiles) {
    if (mediaFiles == null || mediaFiles.isEmpty) {
      return const Text("No media files uploaded.");
    }

    return FutureBuilder<List<String>>(
      future: Future.wait(
        mediaFiles.map((fileUrl) async {
          final path = _extractRelativePath(fileUrl.toString());
          final signedUrl = await getSignedUrl(path);
          return signedUrl ?? fileUrl.toString();
        }),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final signedUrls = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: signedUrls.length,
          itemBuilder: (context, index) {
            final mediaUrl = signedUrls[index];
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: InteractiveViewer(
                      child: Image.network(mediaUrl, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.redAccent),
                ),
              ),
            );
          },
        );
      },
    );
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

  Widget otherDetailsTable(BuildContext context, String? customerId) {
    if (customerId == null) return const SizedBox();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(customerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            "Customer details not available.",
            style: TextStyle(color: Colors.black54),
          );
        }

        final customerData = snapshot.data!.data() as Map<String, dynamic>?;

        if (customerData == null || customerData.isEmpty) {
          return const Text(
            "Customer details not available.",
            style: TextStyle(color: Colors.black54),
          );
        }

        return Table(
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(2.5),
          },
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Colors.black12),
          ),
          children: [
            buildTableRow(
              context: context,
              label: "Contact",
              value: customerData['phoneNumber']?.toString().trim() ?? "N/A",
              leftColor: const Color(0xFFE8F9FF),
              rightColor: Colors.white,
            ),
            buildTableRow(
              context: context,
              label: "Email",
              value: customerData['email']?.toString().trim() ?? "N/A",
              leftColor: const Color(0xFFE8F9FF),
              rightColor: Colors.white,
            ),
            buildTableRow(
              context: context,
              label: "Address",
              value: customerData['address']?.toString().trim() ?? "N/A",
              leftColor: const Color(0xFFE8F9FF),
              rightColor: Colors.white,
            ),
          ],
        );
      },
    );
  }

  void _showEditMeasurementDialog(
    BuildContext context,
    Map<String, dynamic> appointmentData,
  ) {
    final existingMeasurements = Map<String, dynamic>.from(
      appointmentData['measurements'] ?? {},
    );

    List<MapEntry<String, Map<String, Object>>> measurementControllers =
        existingMeasurements.entries
            .map(
              (entry) => MapEntry(entry.key, {
                'keyController': TextEditingController(text: entry.key),
                'valueController': TextEditingController(
                  text: entry.value.toString(),
                ),
                'unit': 'cm',
              }),
            )
            .toList();

    if (measurementControllers.isEmpty) {
      measurementControllers.add(
        MapEntry('Chest', {
          'keyController': TextEditingController(text: 'Chest'),
          'valueController': TextEditingController(text: ''),
          'unit': 'cm',
        }),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF9FAFB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Edit Measurements',
                style: GoogleFonts.acme(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Enter measurement type and value:',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: measurementControllers.length,
                        itemBuilder: (context, i) {
                          final keyController =
                              measurementControllers[i].value['keyController']
                                  as TextEditingController;
                          final valueController =
                              measurementControllers[i].value['valueController']
                                  as TextEditingController;
                          final unit =
                              measurementControllers[i].value['unit'] as String;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: keyController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Measurement Type',
                                      hintText: 'e.g. Chest, Waist, Sleeve',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (newKey) {
                                      setDialogState(() {
                                        measurementControllers[i] = MapEntry(
                                          newKey,
                                          measurementControllers[i].value,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: valueController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            labelText: 'Value',
                                            hintText: 'Enter size value',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 70,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: DropdownButton<String>(
                                          value: unit,
                                          underline: const SizedBox(),
                                          isExpanded: true,
                                          items: ['cm', 'in', 'm'].map((u) {
                                            return DropdownMenuItem<String>(
                                              value: u,
                                              child: Text(
                                                u,
                                                textAlign: TextAlign.center,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (selectedUnit) {
                                            setDialogState(() {
                                              measurementControllers[i]
                                                      .value['unit'] =
                                                  selectedUnit!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: "Remove this measurement",
                                      onPressed: () {
                                        setDialogState(() {
                                          measurementControllers.removeAt(i);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              measurementControllers.add(
                                MapEntry('', {
                                  'keyController': TextEditingController(),
                                  'valueController': TextEditingController(),
                                  'unit': 'cm',
                                }),
                              );
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Add Measurement"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF72A0C1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6082B6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final updatedMeasurements = <String, Object>{};
                    for (var entry in measurementControllers) {
                      final key = entry.key.trim();
                      if (key.isNotEmpty) {
                        final valueController =
                            entry.value['valueController']
                                as TextEditingController;
                        final unit = entry.value['unit'] as String;
                        updatedMeasurements[key] =
                            "${valueController.text.trim()} $unit";
                      }
                    }

                    await FirebaseFirestore.instance
                        .collection('Appointment Forms')
                        .doc(appointmentData['appointmentId'])
                        .update({'measurements': updatedMeasurements});

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Measurements updated successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _finishedOrdersFrame({
    required String activeDetail,
    required VoidCallback onMeasurement,
    required VoidCallback onMedia,
    required VoidCallback onOtherDetails,
    required VoidCallback onBack,
    required Map<String, dynamic> appointmentData,
    required int appointmentNumber,
  }) {
    final tailorFontSize = context.watch<TailorFontprovider>().fontSize;
    final tailorId = FirebaseAuth.instance.currentUser!.uid;

    final customerId =
        appointmentData['customerId'] ??
        appointmentData['customerID'] ??
        appointmentData['toCustomerId'];

    return FutureBuilder<String>(
      future: _getOrCreateChat(customerId, tailorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chatId = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              appointmentData['fullName'] ?? "Unknown",
                              style: GoogleFonts.bebasNeue(
                                fontWeight: FontWeight.bold,
                                fontSize: tailorFontSize + 4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              appointmentNumber.toString().padLeft(3, '0'),
                              style: GoogleFonts.noticiaText(
                                fontSize: tailorFontSize - 2,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Completed",
                              style: GoogleFonts.noticiaText(
                                color: Colors.lightGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                chatId: chatId,
                                currentUserId: tailorId,
                                otherUserId: customerId,
                                isTailor: true,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 45,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF5F7F9),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.message_rounded,
                              color: Colors.black54,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8DA399),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (activeDetail.isEmpty) ...[
                        _buildMainFinishedContent(
                          context,
                          appointmentData,
                          onMeasurement,
                          onMedia,
                          onOtherDetails,
                          onBack,
                        ),
                      ] else ...[
                        if (activeDetail == "measurement")
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: measurementDetailsTable(
                              context,
                              Map<String, dynamic>.from(
                                appointmentData['manualMeasurements'] ??
                                    appointmentData['measurements'] ??
                                    {},
                              ),
                            ),
                          )
                        else if (activeDetail == "media")
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: mediaDetailsTable(
                              context,
                              _extractMediaList(appointmentData) ?? [],
                            ),
                          )
                        else if (activeDetail == "otherdetails")
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: otherDetailsTable(context, customerId),
                          ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 20,
                              bottom: 8,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF72A0C1),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onPressed: onBack,
                              child: Text(
                                "Back",
                                style: GoogleFonts.noticiaText(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainFinishedContent(
    BuildContext context,
    Map<String, dynamic> appointmentData,
    VoidCallback onMeasurement,
    VoidCallback onMedia,
    VoidCallback onOtherDetails,
    VoidCallback onBack,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF8DA399),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(2.5),
                  },
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: Colors.black12),
                  ),
                  children: [
                    buildTableRow(
                      context: context,
                      label: "Measurement",
                      value: "Details",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                      onPressed: onMeasurement,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Media Upload",
                      value: "See Media",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                      onPressed: onMedia,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Other Details",
                      value: "See Other Details",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                      onPressed: onOtherDetails,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Payment Status",
                      value: appointmentData['paymentStatus'] ?? "Fully Paid",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Tailor Assigned",
                      value: appointmentData['tailorAssigned'] ?? "N/A",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Service Type",
                      value: appointmentData['services'] ?? "N/A",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Method",
                      value: appointmentData['measurementMethod'] ?? "N/A",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Message",
                      value:
                          appointmentData['message'] ?? "No message provided",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(2.5),
                  },
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: Colors.black12),
                  ),
                  children: [
                    buildTableRow(
                      context: context,
                      label: "Order",
                      value: appointmentData['garmentSpec'] ?? "N/A",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Due Date",
                      value: appointmentData['dueDateTime'] != null
                          ? DateFormat('MMMM dd, yyyy • h:mm a').format(
                              (appointmentData['dueDateTime'] as Timestamp)
                                  .toDate(),
                            )
                          : "Unknown",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Priority",
                      value: appointmentData['priority'] ?? "N/A",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                    buildTableRow(
                      context: context,
                      label: "Price",
                      value: appointmentData['tailorPrice'] != null
                          ? "PHP ${appointmentData['tailorPrice']}"
                          : "N/A",
                      leftColor: const Color(0xFFE8F9FF),
                      rightColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF72A0C1),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
                onPressed: () async {
                  final customerId = appointmentData['customerId'];

                  try {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .add({
                          'toCustomerId': customerId,
                          'title': 'Update from Tailor',
                          'body':
                              'Your order has been completed. You can come in the shop and get your product.',
                          'appointmentId': appointmentData['appointmentId'],
                          'timestamp': FieldValue.serverTimestamp(),
                          'readBy': [],
                        });

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Customer has been notified!'),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error sending notification: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to notify customer: $e'),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Notify this user',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),

              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB82132),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TailorReportPage(
                        appointmentId: appointmentData['appointmentId'],
                        customerName: appointmentData['fullName'] ?? 'Unknown',
                        respondentName: _tailorName,
                      ),
                    ),
                  );
                },
                child: Text(
                  "Report this Person",
                  style: GoogleFonts.noticiaText(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  List<dynamic>? _extractMediaList(Map<String, dynamic> data) {
    final possibleKeys = [
      'mediaFiles',
      'media',
      'uploadedImages',
      'manualUploads',
      'customerUploads',
    ];

    for (final key in possibleKeys) {
      final value = data[key];
      if (value is List && value.isNotEmpty) {
        return value;
      }
    }

    if (data.containsKey('customer_appointmentfile')) {
      final customerFileData = data['customer_appointmentfile'];

      if (customerFileData is Map<String, dynamic>) {
        for (final entry in customerFileData.entries) {
          if (entry.key == 'appointments' &&
              entry.value is Map<String, dynamic>) {
            final appointmentFolders = entry.value as Map<String, dynamic>;
            for (final folder in appointmentFolders.values) {
              if (folder is List && folder.isNotEmpty) {
                return folder;
              }
            }
          }
        }
      }
    }

    return null;
  }

  Widget _canceledOrdersFrame({
    required String activeDetail,
    required VoidCallback onBack,
    required VoidCallback onMeasurement,
    required Map<String, dynamic> appointmentData,
    required int appointmentNumber,
  }) {
    final tailorFontSize = context.watch<TailorFontprovider>().fontSize;
    final cancellationDate = (appointmentData['canceledAt'] as Timestamp?)
        ?.toDate();
    final cancellationReason =
        appointmentData['cancellationReason'] ?? "No reason provided";

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header (unchanged)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          appointmentData['fullName'] ?? "Unknown",
                          style: GoogleFonts.bebasNeue(
                            fontWeight: FontWeight.bold,
                            fontSize: tailorFontSize + 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appointmentNumber.toString().padLeft(3, '0'),
                          style: GoogleFonts.noticiaText(
                            fontSize: tailorFontSize - 2,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Cancelled",
                          style: GoogleFonts.noticiaText(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF8DA399),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  if (activeDetail.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.5),
                              1: FlexColumnWidth(2.5),
                            },
                            children: [
                              TableRow(
                                children: [
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.fill,
                                    child: Container(
                                      color: const Color(0xFFE8F9FF),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "Appointment Details",
                                        style: GoogleFonts.bebasNeue(
                                          fontWeight: FontWeight.w400,
                                          fontSize: tailorFontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(8.0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF72A0C1,
                                          ), // Distinct button color
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.black,
                                              width: 1.5,
                                            ),
                                          ),
                                          elevation: 3,
                                        ),
                                        onPressed: onMeasurement,
                                        child: Text(
                                          "See More",
                                          style: GoogleFonts.bebasNeue(
                                            fontWeight: FontWeight.w400,
                                            fontSize: tailorFontSize + 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              buildTableRow(
                                context: context,
                                label: "Order",
                                value: appointmentData['garmentSpec'] ?? "N/A",
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),
                              buildTableRow(
                                context: context,
                                label: "Cancellation Date",
                                value: cancellationDate != null
                                    ? DateFormat(
                                        'MMMM dd, yyyy',
                                      ).format(cancellationDate)
                                    : "Unknown",
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),
                              buildTableRow(
                                context: context,
                                label: "Reason for Cancellation",
                                value: cancellationReason,
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (activeDetail == "expanded") ...[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.5),
                              1: FlexColumnWidth(2.5),
                            },
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: Colors.black12),
                            ),
                            children: [
                              if ((appointmentData['manualMeasurements'] ??
                                      appointmentData['measurements']) !=
                                  null)
                                buildTableRow(
                                  context: context,
                                  label: "Measurement",
                                  value: "Details",
                                  leftColor: const Color(0xFFE8F9FF),
                                  rightColor: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      activeDetailMap[appointmentData['appointmentId']] =
                                          "measurement";
                                    });
                                  },
                                ),
                              if (_extractMediaList(
                                    appointmentData,
                                  )?.isNotEmpty ==
                                  true)
                                buildTableRow(
                                  context: context,
                                  label: "Media Upload",
                                  value: "See Media",
                                  leftColor: const Color(0xFFE8F9FF),
                                  rightColor: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      activeDetailMap[appointmentData['appointmentId']] =
                                          "media";
                                    });
                                  },
                                ),
                              if ((appointmentData['message'] ?? "")
                                      .isNotEmpty ||
                                  (appointmentData['otherDetails'] ?? "")
                                      .isNotEmpty)
                                buildTableRow(
                                  context: context,
                                  label: "Other Details",
                                  value: "See Other Details",
                                  leftColor: const Color(0xFFE8F9FF),
                                  rightColor: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      activeDetailMap[appointmentData['appointmentId']] =
                                          "otherDetails";
                                    });
                                  },
                                ),

                              buildTableRow(
                                context: context,
                                label: "Appointment Date",
                                value:
                                    appointmentData['appointmentDateTime'] !=
                                        null
                                    ? DateFormat(
                                        'MMMM dd, yyyy • h:mm a',
                                      ).format(
                                        (appointmentData['appointmentDateTime']
                                                as Timestamp)
                                            .toDate(),
                                      )
                                    : "Unknown",
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),
                              buildTableRow(
                                context: context,
                                label: "Due Date",
                                value: appointmentData['dueDateTime'] != null
                                    ? DateFormat(
                                        'MMMM dd, yyyy • h:mm a',
                                      ).format(
                                        (appointmentData['dueDateTime']
                                                as Timestamp)
                                            .toDate(),
                                      )
                                    : "Unknown",
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),
                              buildTableRow(
                                context: context,
                                label: "Priority",
                                value: appointmentData['priority'] ?? "Normal",
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),
                              buildTableRow(
                                context: context,
                                label: "Price",
                                value: appointmentData['tailorPrice'] != null
                                    ? "PHP ${appointmentData['tailorPrice']}"
                                    : "N/A",
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),
                              buildTableRow(
                                context: context,
                                label: "Service Type",
                                value: appointmentData['services'] ?? "N/A",
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),
                              buildTableRow(
                                context: context,
                                label: "Payment Status",
                                value:
                                    appointmentData['paymentStatus'] ?? "None",
                                leftColor: const Color(0xFFE8F9FF),
                                rightColor: Colors.white,
                              ),

                              if ((appointmentData['manualMeasurements'] ??
                                          appointmentData['measurements']) ==
                                      null &&
                                  (_extractMediaList(
                                        appointmentData,
                                      )?.isEmpty ??
                                      true) &&
                                  (appointmentData['message'] ?? "").isEmpty &&
                                  (appointmentData['otherDetails'] ?? "")
                                      .isEmpty)
                                TableRow(
                                  children: [
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        color: const Color(0xFFE8F9FF),
                                        child: Text(
                                          "No additional details available.",
                                          style: GoogleFonts.bebasNeue(
                                            fontSize: tailorFontSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        color: Colors.white,
                                        child: const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Back button (unchanged)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 8),
                        child: ElevatedButton(
                          onPressed: onBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF72A0C1),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            "Back",
                            style: GoogleFonts.noticiaText(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (activeDetail == "measurement")
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: measurementDetailsTable(
                          context,
                          Map<String, dynamic>.from(
                            appointmentData['manualMeasurements'] ??
                                appointmentData['measurements'] ??
                                {},
                          ),
                        ),
                      )
                    else if (activeDetail == "media")
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: mediaDetailsTable(
                          context,
                          _extractMediaList(appointmentData) ?? [],
                        ),
                      )
                    else if (activeDetail == "otherDetails")
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: otherDetailsTable(
                          context,
                          appointmentData['customerId'],
                        ),
                      ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              activeDetailMap[appointmentData['appointmentId']] =
                                  "expanded";
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF72A0C1),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Text("Back"),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildSimpleRow(String label, String? value) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          color: const Color(0xFFE8F9FF),
          child: Text(label, style: GoogleFonts.bebasNeue(fontSize: 16)),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Text(
            value ?? "N/A",
            style: GoogleFonts.inknutAntiqua(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemTap(
    IconData icon,
    String title, {
    required VoidCallback onTap,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
    Color iconColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}

Future<void> showReasonDialog({
  required BuildContext context,
  required String title,
  required Function(String) onSave,
}) async {
  final TextEditingController controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: const Color(0xFFF1F5F9),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.songMyung(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Enter reason...",
                  hintStyle: GoogleFonts.songMyung(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.8,
                    ),
                  ),
                ),
                style: GoogleFonts.songMyung(fontSize: 16),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.songMyung(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onSave(controller.text.trim());
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9AA6B2),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: GoogleFonts.noticiaText(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
