import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final bool isTailor;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.isTailor,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;
  Map<String, dynamic>? _replyingTo;

  Future<void> _sendMessage(String text, {String? imageUrl}) async {
    if (text.trim().isEmpty && imageUrl == null) return;

    final chatRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId);

    final draft = text.trim();
    _controller.clear();
    setState(() {
      _replyingTo = null;
    });

    chatRef.collection('messages').add({
      'senderId': widget.currentUserId,
      'text': draft,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'replyTo': _replyingTo,
    });

    chatRef.set({
      'participants': [widget.currentUserId, widget.otherUserId],
      'lastMessage': imageUrl != null ? '[Image]' : draft,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _pickAndSendImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isEmpty) return;

      setState(() => _isSending = true);

      for (var pickedFile in pickedFiles) {
        final file = File(pickedFile.path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${widget.currentUserId}.jpg';

        final uploadPath = 'pictures/$fileName';
        await Supabase.instance.client.storage
            .from('chat_images')
            .upload(uploadPath, file);

        final publicUrl = await Supabase.instance.client.storage
            .from('chat_images')
            .createSignedUrl(uploadPath, 60 * 60 * 24 * 365);

        await _sendMessage('', imageUrl: publicUrl);
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
    final isTailor = widget.isTailor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isTailor
            ? const Color(0xFF262633)
            : const Color(0xFF777C6D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(widget.otherUserId)
              .snapshots(),
          builder: (context, snapshot) {
            String displayName = "Customer";
            String? profileUrl;

            if (snapshot.hasData) {
              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final firstName = data['firstName'] ?? '';
              final surname = data['surname'] ?? '';
              displayName = (firstName.isNotEmpty || surname.isNotEmpty)
                  ? '$firstName $surname'
                  : displayName;
              profileUrl = data['profileImageUrl'];
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                      ? NetworkImage(profileUrl)
                      : null,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
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
      backgroundColor: const Color(0xFFD9D9D9),
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
                      final timestamp =
                          message['createdAt']?.toDate() ?? DateTime.now();
                      final now = DateTime.now();
                      final showDate = now.difference(timestamp).inHours >= 1;

                      final myBubbleColor = isTailor
                          ? Color(0xFF4682A9)
                          : Colors.blueAccent;
                      final otherBubbleColor = isTailor
                          ? Colors.white
                          : Colors.green.shade100;

                      return Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                                style: GoogleFonts.prompt(
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
                                  color: message['imageUrl'] != null
                                      ? Colors.transparent
                                      : isMe
                                      ? myBubbleColor
                                      : otherBubbleColor,
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
                                    if (message['imageUrl'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: FutureBuilder<String>(
                                          future: _getImageUrl(
                                            message['imageUrl'],
                                          ),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const SizedBox(
                                                width: 200,
                                                height: 150,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }

                                            return Image.network(
                                              snapshot.data!,
                                              width: 200,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                            );
                                          },
                                        ),
                                      ),

                                    if (message['text'] != null &&
                                        message['text'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          message['text'],
                                          style: GoogleFonts.russoOne(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: const Color(0xFFF6F5F5),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Replying to: ${_replyingTo!['text']}",
                              style: GoogleFonts.prompt(
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
                              style: GoogleFonts.prompt(),
                              decoration: InputDecoration(
                                hintText: isTailor
                                    ? "Message customer..."
                                    : "Message tailor...",
                                hintStyle: GoogleFonts.prompt(
                                  color: Colors.grey[600],
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: isTailor ? Color(0xFF749BC2) : Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.image, color: Colors.white),
                          onPressed: _isSending ? null : _pickAndSendImages,
                        ),
                      ),
                      const SizedBox(width: 6),

                      Container(
                        decoration: BoxDecoration(
                          color: isTailor ? Color(0xFF749BC2) : Colors.black,
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

  Future<String> _getImageUrl(String storedValue) async {
    if (storedValue.startsWith("http")) {
      return storedValue;
    }

    return await Supabase.instance.client.storage
        .from('chat_images')
        .createSignedUrl(storedValue, 60 * 60 * 24 * 365);
  }
}
