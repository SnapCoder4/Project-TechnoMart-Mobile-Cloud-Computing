import 'admin_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatListPage extends StatelessWidget {
  const AdminChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black45;
    final tileColor = isDark ? Colors.grey[850] : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.15);

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
                  color: subTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final userDoc = docs[i];
              final uid = userDoc.id;
              final data = userDoc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'User';
              final email = data['email'] ?? '';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                    child: Text(
                      (name.isNotEmpty ? name[0] : "?").toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(name, style: theme.textTheme.bodyLarge?.copyWith(color: textColor)),
                  subtitle: Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subTextColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: iconColor,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminChatPage(userId: uid, userName: name),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
