import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameC = TextEditingController();
  final addressC = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      nameC.text = data["name"] ?? "";
      addressC.text = data["address"] ?? "";
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameC.text.trim().isEmpty && addressC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Tidak ada perubahan yang disimpan.",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          backgroundColor: Theme.of(context).cardColor,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
        {
          "name": nameC.text.trim(),
          "address": addressC.text.trim(),
          "email": user.email ?? "",
          "role": "user",
          "createdAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Profil berhasil diperbarui",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          backgroundColor: Theme.of(context).cardColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal menyimpan: $e",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          backgroundColor: Theme.of(context).cardColor,
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    addressC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        iconTheme: theme.iconTheme,
        title: Text(
          "Edit Profil",
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nameC,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: "Nama",
                labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressC,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: "Alamat",
                labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            loading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  )
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Simpan Perubahan",
                        style: TextStyle(color: theme.scaffoldBackgroundColor),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
