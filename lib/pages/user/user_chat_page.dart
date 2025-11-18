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

  String get _userId => FirebaseAuth.instance.currentUser!.uid;
  String get _userEmail => FirebaseAuth.instance.currentUser!.email ?? '';

  /// Pastikan dokumen header chats/{userId} sudah ada
  Future<void> _ensureChatHeader() async {
    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_userId);

    final snap = await chatDocRef.get();
    if (!snap.exists) {
      String displayName = _userEmail;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        displayName = (data['name'] ?? _userEmail) as String;
      }

      await chatDocRef.set({
        'userId': _userId,
        'userName': displayName,
        'lastMessage': '',
        'lastSenderRole': 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();

    final firestore = FirebaseFirestore.instance;
    final chatDocRef = firestore.collection('chats').doc(_userId);
    final messagesRef = chatDocRef.collection('messages');

    // 0) Pastikan header ada
    await _ensureChatHeader();

    // Cek apakah ini pesan pertama di chat
    final existingMessages = await messagesRef.limit(1).get();
    final bool isFirstMessage = existingMessages.docs.isEmpty;

    // 1) Simpan pesan user
    await messagesRef.add({
      'text': text,
      'senderId': _userId,
      'senderRole': 'user', // user
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 2) Update header chat (pakai pesan user dulu)
    await chatDocRef.set({
      'lastMessage': text,
      'lastSenderRole': 'user',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3) Kalau ini pesan pertama, kirim auto-reply dari "bot"
    if (isFirstMessage) {
      const botText =
          "Halo! 👋\n\nTerima kasih sudah menghubungi Technomart.\n"
          "Admin kami sedang online/offline bergantian.\n"
          "Pesan kamu akan segera dicek ya. "
          "Kalau mau, tulis dulu detail pesanan atau kendalanya 🙂";

      await messagesRef.add({
        'text': botText,
        'senderId': 'system',
        'senderRole': 'bot', // <== penting, supaya dianggap lawan bicara
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Header di-update pakai pesan bot (biar paling atas di list admin)
      await chatDocRef.set({
        'lastMessage': botText,
        'lastSenderRole': 'bot',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 4) Scroll ke paling bawah
    await Future.delayed(const Duration(milliseconds: 150));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Tandai pesan admin/bot sebagai sudah dibaca di sisi user
  Future<void> _markAdminMessagesAsRead(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    bool hasUpdate = false;

    for (final doc in snap.docs) {
      final data = doc.data();
      final role = data['senderRole'] ?? 'user';
      final isRead = data['isRead'] as bool? ?? false;

      if ((role == 'admin' || role == 'bot') && !isRead) {
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
        .doc(_userId)
        .collection('messages')
        .orderBy('createdAt')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .snapshots();

    return Column(
      children: [
        // Header ala WA
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
                    final role = data['senderRole'] ?? 'user';

                    final bool isUser = role == 'user';
                    final Alignment align = isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final CrossAxisAlignment crossAlign = isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start;
                    final Color bubbleColor = isUser
                        ? const Color(0xFFDCF8C6) // hijau muda
                        : Colors.white; // admin/bot putih

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
