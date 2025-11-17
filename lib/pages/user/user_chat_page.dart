import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserChatPage extends StatefulWidget {
  const UserChatPage({super.key});

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String get _chatId => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
          'text': text,
          'sender': 'user',
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

  Future<void> _markAdminMessagesAsRead(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    bool hasUpdate = false;

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['sender'] == 'admin' &&
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
        .doc(_chatId)
        .collection('messages')
        .orderBy('createdAt')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .snapshots();

    return Column(
      children: [
        // header kecil biar vibes WA dikit
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF075E54),
          child: Row(
            children: const [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFF075E54),
                ),
              ),
              SizedBox(width: 10),
              Text(
                "Chat Admin Technomart",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFE5DDD5),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Mulai chat dengan admin Technomart 👋",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                // tandai pesan admin sebagai sudah dibaca
                _markAdminMessagesAsRead(snapshot.data!);

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

                    final bool isUser = sender == 'user';
                    // user = hijau kanan, admin = putih kiri
                    final Alignment align = isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final CrossAxisAlignment crossAlign = isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start;
                    final Color bubbleColor = isUser
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
                    hintText: "Ketik pesan...",
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
    );
  }
}
