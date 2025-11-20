import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'admin_change_password_page.dart';
import 'admin_transaction_history_page.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text(
            "Pengaturan Admin",
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Ubah Password
          ListTile(
            leading: Icon(Icons.lock, color: theme.iconTheme.color),
            title: Text("Ubah Password", style: theme.textTheme.bodyLarge),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: theme.textTheme.bodySmall?.color,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminChangePasswordPage(),
                ),
              );
            },
          ),
          Divider(color: theme.dividerColor),

          // Riwayat Transaksi
          ListTile(
            leading: Icon(Icons.history, color: theme.iconTheme.color),
            title: Text("Riwayat Transaksi", style: theme.textTheme.bodyLarge),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: theme.textTheme.bodySmall?.color,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminTransactionHistoryPage(),
                ),
              );
            },
          ),
          Divider(color: theme.dividerColor),

          const SizedBox(height: 16),

          // Mode Gelap / Terang
          SwitchListTile(
            value: themeProvider.isDarkMode,
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.withAlpha((0.5 * 255).toInt()),
            secondary: Icon(
              themeProvider.isDarkMode
                  ? Icons.nightlight_round
                  : Icons.wb_sunny,
              color: theme.iconTheme.color,
            ),
            title: Text("Ubah Tema", style: theme.textTheme.bodyLarge),
            onChanged: (val) => themeProvider.toggleTheme(val),
          ),
        ],
      ),
    );
  }
}
