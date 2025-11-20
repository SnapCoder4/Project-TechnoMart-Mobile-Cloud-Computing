import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

// Pages
import 'admin_dashboard_page.dart';
import 'admin_settings_page.dart';
import 'admin_chat_list_page.dart';

// Dialogs
import 'admin_add_product_dialog.dart';
import 'admin_edit_product_dialog.dart';

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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

      const AdminChatListPage(),

      const AdminSettingsPage(),
    ];

    return Scaffold(
      // Pakai warna dari theme, jangan hardcode
      appBar: AppBar(
        title: Text(
          "Technomart Admin",
          style:
              theme.appBarTheme.titleTextStyle ??
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.logout(),
          ),
        ],
      ),

      backgroundColor: theme.scaffoldBackgroundColor,
      body: pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),

        // ❌ JANGAN set backgroundColor/selectedColor hardcode
        // biar ikut BottomNavigationBarTheme dari main.dart
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
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : null,
    );
  }
}
