import 'package:flutter/material.dart';

class UserChatPage extends StatelessWidget {
  const UserChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Chat dengan Admin Technomart akan tampil di sini.\n"
        "Kamu bisa tanya stok, spesifikasi, dll.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}