import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_change_password_page.dart';
import '../providers/theme_provider.dart';
import 'admin_transaction_history_page.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey.shade100;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;

    Widget buildSettingTile({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(title, style: TextStyle(color: textColor)),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: subTextColor,
              size: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: onTap,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: iconColor),
        title: Text(
          "Pengaturan Admin",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            buildSettingTile(
              icon: Icons.lock,
              title: "Ubah Password",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminChangePasswordPage(),
                  ),
                );
              },
            ),
            Divider(color: dividerColor, height: 20),

            buildSettingTile(
              icon: Icons.history,
              title: "Riwayat Transaksi",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminTransactionHistoryPage(),
                  ),
                );
              },
            ),
            Divider(color: dividerColor, height: 20),

            SwitchListTile(
              value: isDark,
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withAlpha(120),
              secondary: Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny,
                color: iconColor,
              ),
              title: Text("Ubah Tema", style: TextStyle(color: textColor)),
              tileColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
          ],
        ),
      ),
    );
  }
}
