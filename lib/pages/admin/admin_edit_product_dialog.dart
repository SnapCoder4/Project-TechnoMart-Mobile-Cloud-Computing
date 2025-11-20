import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEditProductDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const AdminEditProductDialog({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<AdminEditProductDialog> createState() => _AdminEditProductDialogState();
}

class _AdminEditProductDialogState extends State<AdminEditProductDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController descCtrl;

  Uint8List? imageBytes;
  File? imageFile;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialData['name'] ?? "");
    priceCtrl = TextEditingController(
      text: (widget.initialData['price'] ?? 0).toString(),
    );
    stockCtrl = TextEditingController(
      text: (widget.initialData['stock'] ?? 0).toString(),
    );
    descCtrl = TextEditingController(
      text: widget.initialData['description'] ?? "",
    );

    final img = widget.initialData['image'] as String?;
    if (img != null && img.isNotEmpty) {
      imageBytes = base64Decode(img);
    }
  }

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
      debugPrint("Error pick image: $e");
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

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.docId)
          .update({
            "name": nameCtrl.text.trim(),
            "price": int.tryParse(priceCtrl.text) ?? 0,
            "stock": int.tryParse(stockCtrl.text) ?? 0,
            "description": descCtrl.text.trim(),
            "image": base64Image ?? (widget.initialData['image'] ?? ""),
          });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error update product: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Edit Produk",
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nama Produk"),
            ),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Harga"),
            ),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stok"),
            ),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Deskripsi Produk",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // PREVIEW IMAGE
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes!,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              )
            else if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile!,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),

            TextButton.icon(
              onPressed: pickImage,
              icon: Icon(Icons.image, color: colorScheme.primary),
              label: Text(
                "Upload Gambar",
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Batal", style: theme.textTheme.labelLarge),
        ),
        ElevatedButton(
          onPressed: loading ? null : saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Simpan"),
        ),
      ],
    );
  }
}
