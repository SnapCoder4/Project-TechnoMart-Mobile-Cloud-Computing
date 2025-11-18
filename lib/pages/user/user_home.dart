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
    final theme = Theme.of(context);
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = auth.user?.email ?? "Unknown";

    final pages = [
      UserShopPage(),
      const UserChatPage(),
      UserSettingsPage(userEmail: email),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 1,
        iconTheme: theme.iconTheme,
        title: Text(
          "Technomart",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: Icon(Icons.logout_rounded, color: theme.iconTheme.color),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.iconTheme.color?.withOpacity(0.6),
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
