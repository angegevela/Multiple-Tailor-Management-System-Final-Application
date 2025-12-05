import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import 'package:threadhub_system/Admin/pages/sidebar/menu.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String filterBy = "All";
  final List<String> filters = ["Customer", "Tailor", "Administrator"];
  String? selectedUserName;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final usersStream = _firestore.collection('Users').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        final role = data['role'] ?? '';
        String name = '';

        if (role == 'Tailor') {
          name = data['ownerName'] ?? data['username'] ?? 'Unknown Tailor';
        } else if (role == 'Customer') {
          final firstName = data['firstName'] ?? '';
          final surname = data['surname'] ?? '';
          name = (firstName + ' ' + surname).trim();
          if (name.isEmpty) name = data['username'] ?? 'Unknown Customer';
        }

        return {'id': doc.id, 'name': name, 'type': role};
      }).toList();
    });

    final adminsStream = _firestore.collection('admins').snapshots().map((
      snap,
    ) {
      return snap.docs.map((doc) {
        final data = doc.data();
        final adminName =
            data['adminName'] ?? data['username'] ?? 'Unknown Administrator';
        return {'id': doc.id, 'name': adminName, 'type': 'Administrator'};
      }).toList();
    });

    return Rx.combineLatest2<
      List<Map<String, dynamic>>,
      List<Map<String, dynamic>>,
      List<Map<String, dynamic>>
    >(usersStream, adminsStream, (users, admins) => [...users, ...admins]);
  }

  void _deleteSelected() async {
    if (selectedUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user selected to delete')),
      );
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('Users')
          .where('username', isEqualTo: selectedUserName)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      setState(() => selectedUserName = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF6082B6)),
      drawer: const Menu(),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const SizedBox(height: 5),
              Container(
                width: 150,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Users',
                    style: TextStyle(
                      fontFamily: 'HermeneusOne',
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 13),
              Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text("Delete"),
                            onPressed: _deleteSelected,
                          ),

                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            offset: const Offset(0, 40),
                            color: Colors.transparent,
                            elevation: 0,
                            onSelected: (value) {
                              setState(() {
                                filterBy = value;
                              });
                            },
                            itemBuilder: (context) {
                              final options = filterBy == "All"
                                  ? filters
                                  : ["All", ...filters];
                              return options.map((filter) {
                                final isSelected = filterBy == filter;
                                return PopupMenuItem<String>(
                                  value: filter,
                                  padding: EdgeInsets.zero,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                      border: const Border(
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        filter,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            child: OutlinedButton.icon(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(
                                Icons.filter_alt,
                                size: 18,
                                color: Colors.grey,
                              ),
                              label: Text(
                                filterBy == "All" ? "Filter by" : filterBy,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Search bar
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.white,
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.search, color: Colors.grey),
                                  hintText: "Search",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() => searchQuery = value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 0),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              "Name",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "User Type",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 0),

                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: getUsersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              "Error loading users: ${snapshot.error}",
                            ),
                          );
                        }

                        final users = snapshot.data ?? [];

                        final filteredUsers = users.where((user) {
                          final matchesFilter =
                              filterBy == "All" || user['type'] == filterBy;
                          final matchesSearch =
                              searchQuery.isEmpty ||
                              user['name'].toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              );
                          return matchesFilter && matchesSearch;
                        }).toList();

                        if (filteredUsers.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No users available'
                                  : 'No results for "$searchQuery"',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredUsers.length,
                          separatorBuilder: (_, __) => const Divider(height: 0),
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final name = user['name'] ?? "-";
                            final type = user['type'] ?? "-";
                            final isSelected = selectedUserName == name;

                            final rowColor = isSelected
                                ? (type == "Tailor"
                                      ? const Color(0xFF004D40)
                                      : Colors.grey.shade700)
                                : (index % 2 == 0
                                      ? Colors.white
                                      : Colors.grey[100]!);

                            final textStyle = TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            );

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedUserName = selectedUserName == name
                                      ? null
                                      : name;
                                });
                              },
                              child: Container(
                                color: rowColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        name,
                                        style: GoogleFonts.archivo(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        type,
                                        style: GoogleFonts.archivo(),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
