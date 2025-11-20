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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 1,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        title: Text(
          "Pengaturan",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              userEmail,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: Icon(
                Icons.person,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                "Edit Profil",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
            ),
            const Divider(color: Colors.black12),

            ListTile(
              leading: Icon(
                Icons.lock,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                "Ubah Password",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
            ),
            const Divider(color: Colors.black12),

            ListTile(
              leading: Icon(
                Icons.history,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                "Riwayat Transaksi",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).textTheme.bodySmall?.color,
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
            const Divider(color: Colors.black12),

            SwitchListTile(
              value: themeProvider.isDarkMode,
              activeThumbColor: Colors.blue,
              activeTrackColor: Colors.blue.withAlpha((0.5 * 255).toInt()),
              secondary: Icon(
                themeProvider.isDarkMode
                    ? Icons.nightlight_round
                    : Icons.wb_sunny,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                "Ubah Tema",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
          ],
        ),
      ),
    );
  }
}
