import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddProductDialog extends StatefulWidget {
  const AdminAddProductDialog({super.key});

  @override
  State<AdminAddProductDialog> createState() => _AdminAddProductDialogState();
}

class _AdminAddProductDialogState extends State<AdminAddProductDialog> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  Uint8List? imageBytes;
  File? imageFile;

  bool loading = false;

  Future<void> pickImage() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) {
          imageFile = File(picked.path);
          imageBytes = await picked.readAsBytes();
          setState(() {});
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result != null) {
          imageBytes = result.files.first.bytes;
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> saveProduct() async {
    if (nameCtrl.text.isEmpty ||
        priceCtrl.text.isEmpty ||
        stockCtrl.text.isEmpty) {
      return;
    }

    setState(() => loading = true);

    try {
      final base64Image = imageBytes != null ? base64Encode(imageBytes!) : null;

      await FirebaseFirestore.instance.collection('products').add({
        "name": nameCtrl.text.trim(),
        "price": int.tryParse(priceCtrl.text) ?? 0,
        "stock": int.tryParse(stockCtrl.text) ?? 0,
        "description": descCtrl.text.trim(),
        "image": base64Image ?? "",
        "createdAt": Timestamp.now(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving product: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final buttonColor = isDark ? Colors.grey[700]! : Colors.black;
    final buttonTextColor = Colors.white;
    final saveButtonColor = const Color(0xFF2563EB);

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Tambah Produk",
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Nama Produk", nameCtrl),
            _buildTextField("Harga", priceCtrl, keyboard: TextInputType.number),
            _buildTextField("Stok", stockCtrl, keyboard: TextInputType.number),
            _buildTextField("Deskripsi Produk", descCtrl, maxLines: 3),
            const SizedBox(height: 16),

            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 150,
                  height: 150,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: imageBytes != null
                      ? Image.memory(imageBytes!, fit: BoxFit.cover)
                      : imageFile != null
                      ? Image.file(imageFile!, fit: BoxFit.cover)
                      : Icon(Icons.image, size: 50, color: subTextColor),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.image, color: buttonTextColor),
                label: Text(
                  "Upload Gambar",
                  style: TextStyle(color: buttonTextColor),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Batal",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: loading ? null : saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: saveButtonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Simpan"),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
