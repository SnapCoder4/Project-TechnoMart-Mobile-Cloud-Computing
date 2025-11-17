import 'user_shop_page.dart';
import 'user_chat_page.dart';
import 'user_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

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
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Technomart",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
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
