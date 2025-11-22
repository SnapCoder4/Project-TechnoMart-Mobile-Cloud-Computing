import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChangePasswordPage extends StatefulWidget {
  const AdminChangePasswordPage({super.key});

  @override
  State<AdminChangePasswordPage> createState() =>
      _AdminChangePasswordPageState();
}

class _AdminChangePasswordPageState extends State<AdminChangePasswordPage> {
  final oldC = TextEditingController();
  final newC = TextEditingController();
  bool loading = false;

  Future<void> changePassword() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldC.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newC.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password berhasil diubah")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    oldC.dispose();
    newC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey.shade100;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final buttonColor = isDark ? Colors.grey.shade800 : Colors.black;
    final buttonTextColor = Colors.white;

    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: cardColor == Colors.white ? Colors.black26 : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
        title: Text("Ubah Password", style: TextStyle(color: textColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: oldC,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: buildInputDecoration("Password Lama"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newC,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: buildInputDecoration("Password Baru"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: loading
                  ? CircularProgressIndicator(color: Colors.blue)
                  : ElevatedButton(
                      onPressed: changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Simpan Perubahan",
                        style: TextStyle(color: buttonTextColor),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
