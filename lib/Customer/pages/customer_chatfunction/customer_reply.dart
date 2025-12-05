import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const CustomerChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required String appointmentId,
    required String customerId,
  });

  @override
  State<CustomerChatPage> createState() => _CustomerChatPageState();
}

class _CustomerChatPageState extends State<CustomerChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;
  Map<String, dynamic>? _replyingTo;

  Future<void> _sendMessage(String text, {String? imageUrl}) async {
    if (text.trim().isEmpty && imageUrl == null) return;

    final chatRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId);

    await chatRef.collection('messages').add({
      'senderId': widget.currentUserId,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'replyTo': _replyingTo,
    });

    await chatRef.set({
      'participants': [widget.currentUserId, widget.otherUserId],
      'lastMessage': imageUrl != null ? '[Image]' : text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      _replyingTo = null;
    });

    _controller.clear();
  }

  Future<void> _pickAndSendImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isEmpty) return;

      setState(() => _isSending = true);

      for (var pickedFile in pickedFiles) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${widget.currentUserId}.jpg';

        final response = await Supabase.instance.client.storage
            .from('chat_images')
            .uploadBinary('pictures/$fileName', bytes);

        if (response.isEmpty) throw Exception("Image upload failed");

        final signedUrl = Supabase.instance.client.storage
            .from('chat_images')
            .createSignedUrl('pictures/$fileName', 60 * 60 * 24 * 365);

        await _sendMessage('', imageUrl: await signedUrl);
      }
    } catch (e) {
      debugPrint("Error sending image: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send image: $e")));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF777C6D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(widget.otherUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Row(
                children: [
                  const CircleAvatar(radius: 16, backgroundColor: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "Loading...",
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final shopName = data['shopName'] ?? "Tailor";
            final profileUrl = data['profileImageUrl'];

            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                      ? NetworkImage(profileUrl)
                      : const AssetImage('assets/default_tailor_avatar.png')
                            as ImageProvider,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shopName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.crimsonPro(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe = message['senderId'] == widget.currentUserId;
                      final imageUrl = message['imageUrl'];
                      final timestamp =
                          message['createdAt']?.toDate() ?? DateTime.now();
                      final now = DateTime.now();
                      bool showDate = now.difference(timestamp).inHours >= 1;

                      return Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                                style: GoogleFonts.staatliches(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          GestureDetector(
                            onLongPress: () {
                              setState(() {
                                _replyingTo = {
                                  'text': message['text'] ?? '',
                                  'senderId': message['senderId'],
                                };
                              });
                            },
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.all(10),
                                constraints: const BoxConstraints(
                                  maxWidth: 260,
                                ),
                                decoration: BoxDecoration(
                                  color: imageUrl != null
                                      ? Colors.transparent
                                      : isMe
                                      ? const Color(0xFF5C7285)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(13),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message['replyTo'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "Reply to: ${message['replyTo']['text']}",
                                          style: GoogleFonts.dmSerifText(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (imageUrl != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: 200,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 50,
                                                  ),
                                        ),
                                      )
                                    else
                                      Text(
                                        message['text'] ?? '',
                                        style: GoogleFonts.russoOne(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 15,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Color(0xFFD9D9D9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Replying to: ${_replyingTo!['text']}",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _replyingTo = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: Scrollbar(
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: "Type your message...",
                                hintStyle: GoogleFonts.prompt(
                                  color: Colors.grey[600],
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF777C6D),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.image, color: Colors.white),
                          onPressed: _isSending ? null : _pickAndSendImages,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF777C6D),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: _isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: _isSending
                              ? null
                              : () => _sendMessage(_controller.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
