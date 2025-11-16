import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminAddProductDialog extends StatefulWidget {
  const AdminAddProductDialog({super.key});

  @override
  State<AdminAddProductDialog> createState() => _AdminAddProductDialogState();
}

class _AdminAddProductDialogState extends State<AdminAddProductDialog> {
  final nameC = TextEditingController();
  final priceC = TextEditingController();
  final stockC = TextEditingController();

  XFile? _pickedImage;
  bool saving = false;

  @override
  void dispose() {
    nameC.dispose();
    priceC.dispose();
    stockC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  Future<String?> _uploadImageAndGetUrl() async {
    if (_pickedImage == null) return null;

    final file = File(_pickedImage!.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('product_images')
        .child(fileName);

    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF020617),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Tambah Produk",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Nama produk",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceC,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Harga (angka)",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockC,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Stok",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_rounded, color: Colors.white),
                label: const Text(
                  "Pilih Foto Produk",
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_pickedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_pickedImage!.path),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Text(
                "Belum ada foto dipilih.",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Batal"),
          onPressed: () => Navigator.pop(context),
        ),
        saving
            ? const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                ),
                child: const Text("Simpan"),
                onPressed: () async {
                  if (nameC.text.isEmpty || priceC.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Nama dan harga produk tidak boleh kosong.",
                        ),
                      ),
                    );
                    return;
                  }

                  setState(() => saving = true);

                  try {
                    final price = int.tryParse(priceC.text) ?? 0;
                    final stock = int.tryParse(stockC.text) ?? 0;

                    final imageUrl = await _uploadImageAndGetUrl();

                    await FirebaseFirestore.instance
                        .collection('products')
                        .add({
                          'name': nameC.text.trim(),
                          'price': price,
                          'stock': stock,
                          'imageUrl': imageUrl ?? "",
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal menyimpan produk: $e")),
                    );
                  } finally {
                    if (mounted) setState(() => saving = false);
                  }
                },
              ),
      ],
    );
  }
}
