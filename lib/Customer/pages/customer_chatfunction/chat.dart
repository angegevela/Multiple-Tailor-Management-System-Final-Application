import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadhub_system/Customer/pages/customer_chatfunction/customer_reply.dart';

class CustomerChatFunction extends StatefulWidget {
  final String customerId;

  const CustomerChatFunction({
    super.key,
    required this.customerId,
    required String chatId,
    required String currentUserId,
    required otherUserId,
  });

  @override
  State<CustomerChatFunction> createState() => _CustomerChatFunctionState();
}

class _CustomerChatFunctionState extends State<CustomerChatFunction> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD9D9D9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF777C6D),
        title: Text(
          "Chatbox",
          style: GoogleFonts.prompt(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Chats')
            .where('participants', arrayContains: widget.customerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                "No messages yet.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              final tailorId = (data['participants'] as List).firstWhere(
                (id) => id != widget.customerId,
              );

              final lastMessage = data['lastMessage'] ?? "No messages yet";
              final updatedAt = data['updatedAt'] != null
                  ? (data['updatedAt'] as Timestamp).toDate()
                  : null;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(tailorId)
                    .snapshots(),
                builder: (context, tailorSnapshot) {
                  if (!tailorSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final tailorData =
                      tailorSnapshot.data!.data() as Map<String, dynamic>? ??
                      {};

                  final profilePicUrl = tailorData['profileImageUrl'];
                  final shopName = tailorData['shopName'] ?? "Tailor";

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerChatPage(
                            chatId: chat.id,
                            currentUserId: widget.customerId,
                            otherUserId: tailorId,
                            appointmentId: '',
                            customerId: widget.customerId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                (profilePicUrl != null &&
                                    profilePicUrl.toString().isNotEmpty)
                                ? NetworkImage(profilePicUrl.toString())
                                : const AssetImage(
                                        'assets/icons/threadhub-applogo.png',
                                      )
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shopName,
                                  style: GoogleFonts.prompt(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.russoOne(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (updatedAt != null)
                            Text(
                              _formatChatTime(updatedAt),
                              style: GoogleFonts.prompt(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $period";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else {
      return "${time.month}/${time.day}";
    }
  }
}
