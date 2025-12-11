import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';

class DueDateProductPage extends StatefulWidget {
  const DueDateProductPage({super.key});
  @override
  State<DueDateProductPage> createState() => _DueDateProductPageState();
}

class _DueDateProductPageState extends State<DueDateProductPage> {
  DateTime _currentDate = DateTime.now();
  DateTime _targetDateTime = DateTime.now();
  String _currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  TimeOfDay? selectedTime;
  DateTime? dueDateTime;
  String? duepriority;

  DateTime? finalAppointmentDateTime;
  String? finalPriority;

  void _goToNextMonth() {
    setState(() {
      _targetDateTime = DateTime(
        _targetDateTime.year,
        _targetDateTime.month + 1,
      );
      _currentMonth = DateFormat('MMMM yyyy').format(_targetDateTime);
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _targetDateTime = DateTime(
        _targetDateTime.year,
        _targetDateTime.month - 1,
      );
      _currentMonth = DateFormat('MMMM yyyy').format(_targetDateTime);
    });
  }

  String _calculatePriority(DateTime appointmentDateTime) {
    final now = DateTime.now();
    final diff = appointmentDateTime.difference(now).inDays;

    if (diff <= 3) return 'High';
    if (diff <= 7) return 'Medium';
    return 'Low';
  }

  void _confirmAppointment(BuildContext context) {
    final fontSize = context.read<FontProvider>().fontSize;
    if (dueDateTime != null && selectedTime != null) {
      Navigator.pop(context, {
        'dueDateTime': dueDateTime,
        'duepriority': duepriority,
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.blueGrey[100],
            title: Text(
              'Missing Information',
              style: GoogleFonts.songMyung(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
            content: Text(
              'Please select both a date and time.',
              style: GoogleFonts.songMyung(fontSize: fontSize),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Confirm',
                  style: GoogleFonts.songMyung(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;
    if (selectedTime != null) {
      dueDateTime = DateTime(
        _currentDate.year,
        _currentDate.month,
        _currentDate.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      duepriority = _calculatePriority(dueDateTime!);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF262633),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(10.0),
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFF618CF1), width: 1.5),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                "Please select your preferred date and time for due date of the product",
                style: GoogleFonts.songMyung(fontSize: fontSize),
              ),
            ),

            Container(
              margin: EdgeInsets.all(5.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFB3C8CF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                        onPressed: _goToPreviousMonth,
                      ),
                      Text(
                        _currentMonth,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                        ),
                        onPressed: _goToNextMonth,
                      ),
                    ],
                  ),
                  CalendarCarousel(
                    customDayBuilder:
                        (
                          bool isSelectable,
                          int index,
                          bool isSelectedDay,
                          bool isToday,
                          bool isPrevMonthDay,
                          TextStyle textStyle,
                          bool isNextMonthDay,
                          bool isThisMonthDay,
                          DateTime day,
                        ) {
                          Color tileColor;

                          if (isSelectedDay) {
                            tileColor = Colors.blueGrey;
                          } else if (isToday) {
                            tileColor = Color(0xFF3366FF);
                          } else if (day.weekday == DateTime.saturday ||
                              day.weekday == DateTime.sunday) {
                            tileColor = Colors.white;
                          } else {
                            tileColor = Colors.white;
                          }

                          TextStyle dayTextStyle = textStyle.copyWith(
                            color: (isToday || isSelectedDay)
                                ? Colors.white
                                : Colors.black87,
                          );

                          return Container(
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text('${day.day}', style: dayTextStyle),
                          );
                        },
                    showHeader: false,
                    todayBorderColor: Colors.transparent,

                    onDayPressed: (DateTime date, List<dynamic> _) {
                      setState(() {
                        _currentDate = date;
                      });
                    },
                    daysTextStyle: TextStyle(
                      color: Colors.black87,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    weekdayTextStyle: TextStyle(
                      color: Colors.black,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    daysHaveCircularBorder: false,
                    thisMonthDayBorderColor: Color(0xFFB3C8CF),
                    weekendTextStyle: TextStyle(
                      color: Colors.black87,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    showOnlyCurrentMonthDate: false,
                    height: 330,
                    selectedDateTime: _currentDate,
                    targetDateTime: _targetDateTime,
                    customGridViewPhysics: NeverScrollableScrollPhysics(),
                    selectedDayTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    todayTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    todayButtonColor: Colors.transparent,
                    selectedDayButtonColor: Colors.transparent,
                    selectedDayBorderColor: Colors.transparent,
                    onCalendarChanged: (DateTime date) {
                      setState(() {
                        _targetDateTime = date;
                        _currentMonth = DateFormat(
                          'MMMM yyyy',
                        ).format(_targetDateTime);
                      });
                    },
                  ),
                ],
              ),
            ),

            Center(
              child: Container(
                width: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(7.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                margin: EdgeInsets.all(10.0),
                child: Center(
                  child: Text(
                    "Selected Date: ${DateFormat.yMMMMEEEEd().format(_currentDate)}",
                    style: TextStyle(
                      fontFamily: 'JainiPurva',
                      fontSize: fontSize,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            InkWell(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime ?? TimeOfDay.now(),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        timePickerTheme: TimePickerThemeData(
                          backgroundColor: Colors.white,
                          hourMinuteColor: Colors.blue.shade100,
                          hourMinuteTextColor: Colors.blue.shade900,
                          dialHandColor: Colors.blue,
                          dialBackgroundColor: Colors.blue.shade50,
                          entryModeIconColor: Colors.black,
                        ),
                        colorScheme: ColorScheme.light(
                          primary: Colors.black,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != selectedTime) {
                  setState(() {
                    selectedTime = picked;
                  });
                }
              },

              child: Container(
                width: 340,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey, width: 1.5),
                  borderRadius: BorderRadius.circular(7.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
                margin: EdgeInsets.only(bottom: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedTime != null
                            ? "Selected Time: ${selectedTime!.format(context)}"
                            : "Select Time",
                        style: GoogleFonts.zillaSlab(
                          fontSize: fontSize,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.access_time, color: Colors.black),
                  ],
                ),
              ),
            ),

            if (selectedTime != null &&
                dueDateTime != null &&
                duepriority != null)
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                padding: EdgeInsets.all(5),
                width: 340,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Date and Time',
                      style: TextStyle(
                        fontFamily: 'JainiPurva',
                        fontSize: fontSize,
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
                            horizontal: 10,
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
                                fontSize: fontSize,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ), // spacing between container and text
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

                              fontSize: fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _confirmAppointment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6082B6),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                textStyle: GoogleFonts.chauPhilomeneOne(
                  fontSize: fontSize,
                  color: Colors.black,
                ),
              ),
              child: Text('Confirm'),
            ),

            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
