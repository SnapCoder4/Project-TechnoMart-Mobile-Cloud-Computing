import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import 'user_shop_page.dart';
import 'user_chat_page.dart';
import 'user_settings_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = auth.user?.email ?? "Unknown";

    final pages = [
      UserShopPage(userEmail: email),
      const UserChatPage(),
      UserSettingsPage(userEmail: email),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Technomart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF111827), Color(0xFF1F2937)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF020617),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF020617),
        selectedItemColor: const Color(0xFF22C55E),
        unselectedItemColor: const Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: "Setting",
          ),
        ],
      ),
    );
  }
}
