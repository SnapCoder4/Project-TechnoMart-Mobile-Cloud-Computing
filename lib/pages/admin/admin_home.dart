import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import 'admin_dashboard_page.dart';
import 'admin_chat_page.dart';
import 'admin_settings_page.dart';
import 'admin_add_product_dialog.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = auth.user?.email ?? "Unknown";

    final pages = [
      AdminDashboardPage(adminEmail: email),
      const AdminChatPage(),
      const AdminSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Technomart Admin",
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
        selectedItemColor: const Color(0xFF38BDF8),
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AdminAddProductDialog(),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text("Tambah Produk"),
              backgroundColor: const Color(0xFF38BDF8),
            )
          : null,
    );
  }
}
