import 'admin_settings_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_chat_list_page.dart';
import 'package:flutter/material.dart';
import 'admin_add_product_dialog.dart';
import 'package:provider/provider.dart';
import 'admin_edit_product_dialog.dart';
import '../../services/auth_service.dart';
import '../providers/theme_provider.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final email = auth.user?.email ?? "Tidak diketahui";

    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

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
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(
                    "Technomart Admin",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: textColor,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: "Logout",
                      onPressed: () => auth.logout(),
                      icon: Icon(Icons.logout_rounded, color: iconColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: pages[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: cardColor,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: textColor,
        unselectedItemColor: textColor.withOpacity(0.5),
        showSelectedLabels: true,
        showUnselectedLabels: false,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 26),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded, size: 26),
            label: "Pesan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded, size: 26),
            label: "Pengaturan",
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: isDark ? Colors.grey[800] : Colors.black,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Tambah Produk",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AdminAddProductDialog(),
                );
              },
            )
          : null,
    );
  }
}
