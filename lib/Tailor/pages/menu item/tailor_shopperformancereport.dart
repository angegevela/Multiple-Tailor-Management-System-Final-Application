import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_notification.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_ratingsandreviews.dart';
import 'package:threadhub_system/Tailor/pages/tailorhomepage.dart';

class TailorShopperformancereport extends StatefulWidget {
  const TailorShopperformancereport({super.key});

  @override
  State<TailorShopperformancereport> createState() =>
      _TailorShopperformancereportState();
}

class _TailorShopperformancereportState
    extends State<TailorShopperformancereport> {
  String _selectedGraph = "This 6 Months";
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = true;

  double totalRevenue = 0;
  double prevRevenue = 0;
  int totalAppointments = 0;
  int prevAppointments = 0;
  int cancelledAppointments = 0;
  int prevCancelled = 0;
  int newCustomers = 0;
  int prevNewCustomers = 0;
  int returnees = 0;
  int prevReturnees = 0;

  double revenueChange = 0;
  double appointmentsChange = 0;
  double newCustChange = 0;
  double cancelledChange = 0;

  Map<String, Map<String, int>> performanceData = {};
  List<String> labels = [];

  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
    setState(() => _loading = true);

    try {
      final tailorId = _auth.currentUser?.uid;
      if (tailorId == null) {
        setState(() => _loading = false);
        return;
      }

      final now = DateTime.now();
      DateTime startDate;
      List<String> dynamicLabels = [];

      switch (_selectedGraph) {
        case "This Month":
          startDate = DateTime(now.year, now.month, 1);
          dynamicLabels = ["W1", "W2", "W3", "W4"];
          break;
        case "Last Month":
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          startDate = lastMonth;
          dynamicLabels = ["W1", "W2", "W3", "W4"];
          break;
        case "Past 6 Months":
        case "This 6 Months":
        default:
          startDate = now.subtract(Duration(days: 30 * 6));
          dynamicLabels = List.generate(
            6,
            (i) => _monthShort((now.month - 5 + i - 1) % 12 + 1),
          );
          break;
      }

      performanceData.clear();
      totalRevenue = 0.0;
      totalAppointments = 0;
      cancelledAppointments = 0;
      newCustomers = 0;
      returnees = 0;

      String getKey(DateTime date) {
        if (_selectedGraph == "This Month" || _selectedGraph == "Last Month") {
          int week = ((date.day - 1) ~/ 7) + 1;
          return "W$week";
        } else {
          return _monthShort(date.month);
        }
      }

      final appointmentsSnapshot = await _firestore
          .collection('Appointment Forms')
          .where('tailorId', isEqualTo: tailorId)
          .get();

      Set<String> previousCustomerIds = {};
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final ts = data['timestamp'];
        if (ts is! Timestamp) continue;
        final date = ts.toDate();
        final customerId = data['customerId'];
        if (customerId == null) continue;

        if (date.isBefore(startDate)) {
          previousCustomerIds.add(customerId);
        }
      }

      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final ts = data['timestamp'];
        if (ts is! Timestamp) continue;
        final date = ts.toDate();

        final status = (data['status'] ?? '').toString().toLowerCase();
        final customerId = data['customerId'];
        final priceStr = data['price']?.toString().replaceAll(',', '') ?? "0";
        final price = double.tryParse(priceStr) ?? 0.0;

        final key = getKey(date);

        performanceData.putIfAbsent(
          key,
          () => {"returnee": 0, "cancelled": 0, "new": 0},
        );

        if (status == "cancelled") {
          cancelledAppointments++;
          performanceData[key]!["cancelled"] =
              (performanceData[key]!["cancelled"] ?? 0) + 1;
          print(
            "Cancelled counted for $key, totalCancelled: $cancelledAppointments",
          );

          continue;
        }

        if (date.isBefore(startDate)) continue;

        totalRevenue += price;
        totalAppointments++;

        if (status == "accepted" ||
            status == "completed" ||
            status == "pending") {
          if (customerId != null) {
            if (previousCustomerIds.contains(customerId)) {
              returnees++;
              performanceData[key]!["returnee"] =
                  (performanceData[key]!["returnee"] ?? 0) + 1;
            } else {
              newCustomers++;
              performanceData[key]!["new"] =
                  (performanceData[key]!["new"] ?? 0) + 1;
              previousCustomerIds.add(customerId);
            }
          }
        }
      }
      revenueChange = appointmentsChange = newCustChange = cancelledChange = 0;

      setState(() {
        labels = dynamicLabels;
        _loading = false;
      });
    } catch (e, st) {
      setState(() => _loading = false);
    }
  }

  double _getDynamicMaxY() {
    double maxVal = 0;
    for (var m in performanceData.values) {
      final total =
          (m["returnee"] ?? 0) + (m["cancelled"] ?? 0) + (m["new"] ?? 0);
      if (total > maxVal) maxVal = total.toDouble();
    }
    return maxVal < 5 ? 5 : maxVal * 1.2;
  }

  List<BarChartGroupData> _getBarGroups() {
    if (_loading || performanceData.isEmpty) return [];

    return List.generate(labels.length, (i) {
      final data =
          performanceData[labels[i]] ??
          {"returnee": 0, "cancelled": 0, "new": 0};

      return makeGroupData(
        i,
        (data["returnee"] ?? 0).toDouble(),
        (data["cancelled"] ?? 0).toDouble(),
        (data["new"] ?? 0).toDouble(),
      );
    });
  }

  String _monthShort(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6082B6),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
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
              child: const TextField(
                decoration: InputDecoration(
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Container(
                      height: 50,
                      width: 300,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0C4DE),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        'Shop Performance Report',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _buildInfoCard(
                          "₱${totalRevenue.toStringAsFixed(2)}",
                          "Total Revenue",
                          "${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(1)}%",
                          isNegative: revenueChange < 0,
                        ),
                        _buildInfoCard(
                          "$totalAppointments",
                          "Total Appointments",
                          "${appointmentsChange >= 0 ? '+' : ''}${appointmentsChange.toStringAsFixed(1)}%",
                          isNegative: appointmentsChange < 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _buildInfoCard(
                          "$newCustomers",
                          "New Customers",
                          "${newCustChange >= 0 ? '+' : ''}${newCustChange.toStringAsFixed(1)}%",
                          isNegative: newCustChange < 0,
                        ),
                        _buildInfoCard(
                          "$cancelledAppointments",
                          "Cancelled",
                          "${cancelledChange >= 0 ? '+' : ''}${cancelledChange.toStringAsFixed(1)}%",
                          isNegative: cancelledChange > 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildChartCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CUSTOMER GROWTH',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedGraph,
                  items:
                      [
                            "This Month",
                            "Last Month",
                            "Past 6 Months",
                            "This 6 Months",
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGraph = newValue!;
                      _fetchPerformanceData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot(Colors.blue, "Returnee"),
                const SizedBox(width: 15),
                _buildLegendDot(Colors.redAccent, "Cancelled"),
                const SizedBox(width: 15),
                _buildLegendDot(Colors.grey, "New Customer"),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 400,
              child: BarChart(
                BarChartData(
                  maxY: _getDynamicMaxY(),
                  barGroups: _getBarGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (_getDynamicMaxY() / 5),
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          if (value.toInt() < labels.length) {
                            return Text(labels[value.toInt()]);
                          }
                          return const Text("");
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMenu() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
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
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TailorNotificationPage(
                            tailorId: _auth.currentUser?.uid ?? 'unknown',
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
                      Navigator.pop(context);
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
                    onTap: () {
                      Navigator.pop(context);
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TailorRatingsandreviewsPage(
                            tailorId: _auth.currentUser?.uid ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItemTap(
                    Icons.bar_chart,
                    "Shop Performance Report",
                    onTap: () {
                      Navigator.pop(context);
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

Widget _buildInfoCard(
  String value,
  String title,
  String percent, {
  bool isNegative = false,
}) {
  return Card(
    elevation: 4.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
    child: Container(
      width: 150,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            percent,
            style: TextStyle(
              color: isNegative ? Colors.red : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLegendDot(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13)),
    ],
  );
}

BarChartGroupData makeGroupData(
  int x,
  double returnee,
  double cancelled,
  double newCustomer,
) {
  return BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: returnee + cancelled + newCustomer,
        width: 20,
        borderRadius: const BorderRadius.all(Radius.circular(0)),
        rodStackItems: [
          BarChartRodStackItem(0, returnee, Colors.blue),

          BarChartRodStackItem(
            returnee,
            returnee + cancelled,
            Colors.redAccent,
          ),

          BarChartRodStackItem(
            returnee + cancelled,
            returnee + cancelled + newCustomer,
            Colors.grey,
          ),
        ],
      ),
    ],
  );
}
