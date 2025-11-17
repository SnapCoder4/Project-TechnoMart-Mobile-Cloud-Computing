import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsPage extends StatefulWidget {
  final String userEmail;
  const UserSettingsPage({super.key, required this.userEmail});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final nameC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      nameC.text = data['name'] ?? '';
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameC.text.trim().isEmpty && passC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada perubahan yang disimpan.")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (nameC.text.trim().isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': nameC.text.trim()});
      }

      if (passC.text.trim().isNotEmpty) {
        await user.updatePassword(passC.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perubahan profil berhasil disimpan.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menyimpan perubahan: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          const Text(
            "Pengaturan Akun",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.userEmail,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameC,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Nama profil",
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passC,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Password baru",
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text("Simpan Perubahan"),
                  onPressed: _saveChanges,
                ),
        ],
      ),
    );
  }
}
