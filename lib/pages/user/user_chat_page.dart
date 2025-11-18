import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    await _ensureChatHeader();

    final existingMessages = await messagesRef.limit(1).get();
    final bool isFirstMessage = existingMessages.docs.isEmpty;

    await messagesRef.add({
      'text': text,
      'senderId': _userId,
      'senderRole': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await chatDocRef.set({
      'lastMessage': text,
      'lastSenderRole': 'user',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (isFirstMessage) {
      const botText =
          "Halo! 👋\n\nTerima kasih sudah menghubungi Technomart.\n"
          "Admin kami sedang online/offline bergantian.\n"
          "Pesan kamu akan segera dicek ya. "
          "Kalau mau, tulis dulu detail pesanan atau kendalanya 🙂";

      await messagesRef.add({
        'text': botText,
        'senderId': 'system',
        'senderRole': 'bot',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await chatDocRef.set({
        'lastMessage': botText,
        'lastSenderRole': 'bot',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

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
    final theme = Theme.of(context);

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.colorScheme.primary,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.onPrimary,
                child: Icon(
                  Icons.support_agent_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Chat Admin Technomart",
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Mulai chat dengan admin Technomart 👋",
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
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
                        ? theme.primaryColor.withOpacity(0.2)
                        : theme.cardColor;
                    final Color textColor =
                        theme.textTheme.bodyLarge?.color ?? Colors.black;

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
                              style: TextStyle(color: textColor, fontSize: 14),
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
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: "Ketik pesan...",
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.onPrimary,
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
