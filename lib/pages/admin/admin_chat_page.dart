import 'package:flutter/material.dart';

class AdminChatPage extends StatelessWidget {
  const AdminChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Chat dengan user akan tampil di sini.\n"
        "(1-to-1 chat admin ↔ user)",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
