import 'user_edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_change_password_page.dart';
import '../providers/theme_provider.dart';
import 'user_transaction_history_page.dart';

class UserSettingsPage extends StatelessWidget {
  final String userEmail;
  const UserSettingsPage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey[100]!;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: iconColor),
        title: Text(
          "Pengaturan",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              userEmail,
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: Icon(Icons.person, color: iconColor),
              title: Text("Edit Profil", style: TextStyle(color: textColor)),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: subTextColor,
                size: 16,
              ),
              tileColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
            ),
            Divider(color: dividerColor, height: 20),

            ListTile(
              leading: Icon(Icons.lock, color: iconColor),
              title: Text("Ubah Password", style: TextStyle(color: textColor)),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: subTextColor,
                size: 16,
              ),
              tileColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
            ),
            Divider(color: dividerColor, height: 20),

            ListTile(
              leading: Icon(Icons.history, color: iconColor),
              title: Text(
                "Riwayat Transaksi",
                style: TextStyle(color: textColor),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: subTextColor,
                size: 16,
              ),
              tileColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserTransactionHistoryPage(),
                  ),
                );
              },
            ),
            Divider(color: dividerColor, height: 20),

            SwitchListTile(
              value: themeProvider.isDarkMode,
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withAlpha(120),
              secondary: Icon(
                themeProvider.isDarkMode
                    ? Icons.nightlight_round
                    : Icons.wb_sunny,
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
