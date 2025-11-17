import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatPage extends StatefulWidget {
  final String userId; // UID user
  final String userName; // nama user buat judul

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

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .collection('messages')
        .add({
          'text': text,
          'sender': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

    await Future.delayed(const Duration(milliseconds: 150));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markUserMessagesAsRead(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    bool hasUpdate = false;

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['sender'] == 'user' &&
          (data['isRead'] == false || data['isRead'] == null)) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdate = true;
      }
    }

    if (hasUpdate) await batch.commit();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .collection('messages')
        .orderBy('createdAt')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : "?",
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.userName, style: const TextStyle(fontSize: 17)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada chat dari user ini.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                _markUserMessagesAsRead(snapshot.data!);

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final text = data['text'] ?? '';
                    final sender = data['sender'] ?? 'user';

                    final bool isAdmin = sender == 'admin';
                    // POV admin: admin hijau kanan, user putih kiri
                    final Alignment align = isAdmin
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final CrossAxisAlignment crossAlign = isAdmin
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start;
                    final Color bubbleColor = isAdmin
                        ? const Color(0xFFDCF8C6)
                        : Colors.white;

                    return Align(
                      alignment: align,
                      child: Column(
                        crossAxisAlignment: crossAlign,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.black87,
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

          // input bar
          Container(
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: "Balas pesan user...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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
