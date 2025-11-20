import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_chat_page.dart';

class AdminChatListPage extends StatelessWidget {
  const AdminChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();

    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: usersStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Belum ada user yang terdaftar / chat.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
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
                title: Text(name, style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                ),
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
