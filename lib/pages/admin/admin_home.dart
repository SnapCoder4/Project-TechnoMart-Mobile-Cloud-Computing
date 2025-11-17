import 'admin_chat_page.dart';
import 'admin_settings_page.dart';
import 'admin_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'admin_add_product_dialog.dart';
import 'package:provider/provider.dart';
import 'admin_edit_product_dialog.dart';
import '../../services/auth_service.dart';

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
      AdminDashboardPage(
        adminEmail: email,
        onEditProduct: (docId, data) {
          showDialog(
            context: context,
            builder: (_) =>
                AdminEditProductDialog(docId: docId, initialData: data),
          );
        },
      ),
      const AdminChatPage(),
      const AdminSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Technomart Admin",
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AdminAddProductDialog(),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text("Tambah Produk"),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
