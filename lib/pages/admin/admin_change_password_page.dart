import 'package:flutter/material.dart';
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

      // Re-authenticate user
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldC.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      // Update password
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ubah Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: oldC,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password Lama"),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: newC,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password Baru"),
            ),
            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: changePassword,
                    child: const Text("Simpan Perubahan"),
                  ),
          ],
        ),
      ),
    );
  }
}
