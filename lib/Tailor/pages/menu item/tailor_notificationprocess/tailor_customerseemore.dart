import 'package:flutter/material.dart';

class TailorCustomerSeeMore extends StatefulWidget {
  const TailorCustomerSeeMore({super.key, required Map<String, String> appointmentData});

  @override
  State<TailorCustomerSeeMore> createState() => _TailorCustomerSeeMoreState();
}

class _TailorCustomerSeeMoreState extends State<TailorCustomerSeeMore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text(
          'Customer Details',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF262633),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Image
                  Container(
                    height: 170,
                    width: 130,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade300,
                    ),
                    child: const Center(child: Icon(Icons.image, size: 48)),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: const Text(
                            'Pricing For The Product',
                            style: TextStyle(
                              fontFamily: 'HermeneusOne',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1,
                                  ), // black line separating
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: const [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 16),
                                  Icon(Icons.delete, color: Colors.red),
                                ],
                              ),
                            ),

                            // Table (connected below)
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1.8),
                                1: FlexColumnWidth(1),
                              },
                              border: const TableBorder(
                                top: BorderSide.none,

                                horizontalInside: BorderSide(
                                  color: Colors.black12,
                                  width: 1,
                                ),
                              ),
                              children: [
                                buildTableRow(
                                  label: "Given Price For\nThe Product",
                                  value: "PHP 1,300.00",
                                  leftColor: Color(0xFFE8F9FF),
                                  rightColor: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              //Personal Details
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Personal Details',
                  style: TextStyle(
                    fontFamily: 'HermeneusOne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              Container(
                width: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),

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
                        label: "Full Name",
                        value: "Ash Ketchum",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Garment Specification",
                        value: "Black gloves, Yellow backpack",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Service",
                        value: "Custom Design",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Customization Detail",
                        value:
                            "Cotton for gloves, canvas for backpack, Have a pokeball embroidery in pocket side of the backpack.",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Media Upload",
                        value: "backpack.png, gloves.png",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Address",
                        value:
                            "Purok Gumamela Wescom Road\nBarangay San Miguel, PPC",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Message",
                        value:
                            "Need a new set of gloves before my next tournament.",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Quantity",
                        value: "3",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              //Contact Details
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Contact Details',
                  style: TextStyle(
                    fontFamily: 'HermeneusOne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              Container(
                width: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),

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
                        label: "Email(Optional)",
                        value: "ash.ketchum@gmail.com",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Mobile Number",
                        value: "+9876543210",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              //Deadline Details
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Deadline Details',
                  style: TextStyle(
                    fontFamily: 'HermeneusOne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              Container(
                width: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),

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
                        label: "Mobile Number",
                        value: "+9876543210",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                      buildTableRow(
                        label: "Priorization",
                        value: "High Priority",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              //Appointment Date and Number Details
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Appointment Date and Number',
                  style: TextStyle(
                    fontFamily: 'HermeneusOne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              Container(
                width: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),

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
                        label: "Appointment Date",
                        value: "November 28,2024, 3:30 pm",
                        leftColor: const Color(0xFFE8F9FF),
                        rightColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              //See Less Button
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('SEE LESS'),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_upward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow buildTableRow({
    required String label,
    required String value,
    Color leftColor = const Color(0xFFC4E1E6),
    Color rightColor = Colors.white,
  }) {
    Color textColor = Colors.black;

    // Handle Prioritization coloring
    if (label == "Prioritization") {
      if (value.toLowerCase().contains("low")) {
        textColor = Colors.green;
      } else if (value.toLowerCase().contains("medium")) {
        textColor = Colors.yellow[800]!;
      } else if (value.toLowerCase().contains("high")) {
        textColor = Color(0xFF900707);
      }
    }

    // Handle Appointment Number
    if (label == "Appoint. Number") {
      textColor = Color(0xFF008000);
    }

    // Handle Tailor Assigned
    if (label == "Tailor Assigned") {
      textColor = Color(0xFF008000);
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'HermeneusOne',
                fontSize: 14,
              ),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            color: rightColor,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontFamily: 'HermeneusOne',
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}