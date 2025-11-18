import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

      // scroll ke bawah setelah kirim
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

  /// Kirim pesan bot kalau chat baru berisi 1 pesan dari user
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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              child: Text(
                (widget.userName.isNotEmpty ? widget.userName[0] : "?")
                    .toUpperCase(),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  "Customer Technomart",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFE5E7EB),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesCol
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                // cek apakah perlu auto-reply dari bot
                if (docs.isNotEmpty) {
                  _maybeSendFirstBotReply(docs);
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada percakapan.\nSilakan mulai chat dengan user.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final text = data['text'] ?? '';
                    final role = data['senderRole'] ?? 'user';

                    // dari sudut pandang ADMIN:
                    final isFromStore = role == 'admin' || role == 'bot';

                    return Align(
                      alignment: isFromStore
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isFromStore
                              ? const Color(0xFF22C55E) // hijau untuk admin/bot
                              : Colors.white, // putih untuk user
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isFromStore
                                ? const Radius.circular(16)
                                : const Radius.circular(4),
                            bottomRight: isFromStore
                                ? const Radius.circular(4)
                                : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isFromStore ? Colors.white : Colors.black87,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // input pesan
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Tulis balasan untuk ${widget.userName}...",
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF2563EB),
                          ),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
