import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _botSentForFirst = false;

  DocumentReference<Map<String, dynamic>> get _chatDoc =>
      FirebaseFirestore.instance.collection('chats').doc(widget.userId);

  CollectionReference<Map<String, dynamic>> get _messagesCol =>
      _chatDoc.collection('messages');

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureChatDoc() async {
    await _chatDoc.set({
      'userId': widget.userId,
      'userName': widget.userName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      await _ensureChatDoc();

      final admin = FirebaseAuth.instance.currentUser;
      final adminId = admin?.uid ?? 'admin';

      await _messagesCol.add({
        'text': text,
        'senderId': adminId,
        'senderRole': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': true,
      });

      await _chatDoc.set({
        'lastMessage': text,
        'lastSenderRole': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _msgCtrl.clear();

      await Future.delayed(const Duration(milliseconds: 150));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim pesan: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _maybeSendFirstBotReply(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (_botSentForFirst) return;
    if (docs.length != 1) return;

    final first = docs.first.data();
    if (first['senderRole'] != 'user') return;

    _botSentForFirst = true;

    const botText =
        "Hai kak 👋\n\n"
        "Terima kasih sudah menghubungi Technomart.\n"
        "Saat ini admin mungkin belum bisa membalas secara langsung.\n\n"
        "Sambil menunggu, kakak bisa kirim detail berikut ya:\n"
        "• Nama produk / tipe barang\n"
        "• Pertanyaan atau kendala\n"
        "• Nomor pesanan (kalau ada)\n\n"
        "Admin kami akan cek dan balas secepat mungkin 🙏";

    final admin = FirebaseAuth.instance.currentUser;
    final adminId = admin?.uid ?? 'bot';

    await _messagesCol.add({
      'text': botText,
      'senderId': adminId,
      'senderRole': 'bot',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await _chatDoc.set({
      'lastMessage': botText,
      'lastSenderRole': 'bot',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey[100]!;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: iconColor),
                  onPressed: () => Navigator.pop(context),
                ),
                CircleAvatar(
                  backgroundColor: iconColor,
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : "?",
                    style: TextStyle(color: cardColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: bgColor,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messagesCol.orderBy('createdAt').snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isNotEmpty) {
                    _maybeSendFirstBotReply(docs);
                  }

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Belum ada percakapan.\nSilakan mulai chat dengan user.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subTextColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final text = data['text'] ?? '';
                      final role = data['senderRole'] ?? 'user';

                      final isAdmin = role == 'admin' || role == 'bot';
                      final align = isAdmin ? Alignment.centerRight : Alignment.centerLeft;
                      final crossAlign =
                          isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                      final bubbleColor = isAdmin ? cardColor.withOpacity(0.2) : cardColor;
                      final bubbleTextColor = textColor;

                      return Align(
                        alignment: align,
                        child: Column(
                          crossAxisAlignment: crossAlign,
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: bubbleTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          Container(
            color: bgColor,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Ketik balasan...",
                      hintStyle: TextStyle(color: subTextColor),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: textColor),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.send_rounded, color: cardColor, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
