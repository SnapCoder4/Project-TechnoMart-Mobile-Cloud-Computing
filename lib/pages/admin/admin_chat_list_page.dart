import 'admin_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AdminChatListPage extends StatelessWidget {
  const AdminChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();

    return Container(
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: usersStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada user yang terdaftar / chat.",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final userDoc = docs[i];
              final uid = userDoc.id;
              final data = userDoc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'User';
              final email = data['email'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  child: Text((name.isNotEmpty ? name[0] : "?").toUpperCase()),
                ),
                title: Text(name, style: const TextStyle(color: Colors.black)),
                subtitle: Text(
                  email,
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminChatPage(userId: uid, userName: name),
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
}