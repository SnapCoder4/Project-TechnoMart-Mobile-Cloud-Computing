import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProductDetailPage extends StatefulWidget {
  final String productId;
  final String name;
  final int price;
  final String? imageBase64;
  final String description;

  const UserProductDetailPage({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageBase64,
    required this.description,
  });

  @override
  State<UserProductDetailPage> createState() => _UserProductDetailPageState();
}

class _UserProductDetailPageState extends State<UserProductDetailPage> {
  int quantity = 1;
  bool loading = false;

  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.imageBase64 != null && widget.imageBase64!.isNotEmpty) {
      try {
        _imageBytes = base64Decode(widget.imageBase64!);
      } catch (_) {
        _imageBytes = null;
      }
    }
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(widget.productId);

      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        final currentQty = (cartDoc['quantity'] ?? 1) as num;
        await cartRef.update({'quantity': currentQty.toInt() + quantity});
      } else {
        await cartRef.set({
          'productId': widget.productId,
          'name': widget.name,
          'price': widget.price,
          'quantity': quantity,
          'image': widget.imageBase64 ?? '',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.name} ditambahkan ke keranjang.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey[100];
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final buttonColor = isDark ? Colors.grey[800] : Colors.black;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        centerTitle: true,
        title: Text(
          widget.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 22,
            letterSpacing: 0.3,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: iconColor,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.6)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _imageBytes != null
                    ? Image.memory(
                        _imageBytes!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
                        alignment: Alignment.center,
                        color: cardColor,
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: subTextColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 22),

            // NAME & PRICE
            Text(
              widget.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Rp ${widget.price}",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 22),

            // DESCRIPTION
            Text(
              "Deskripsi Produk",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description.isNotEmpty
                  ? widget.description
                  : "Tidak ada deskripsi.",
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 28),

            // QUANTITY
            Text(
              "Jumlah",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                    icon: Icon(Icons.remove, color: textColor),
                  ),
                  Text(
                    "$quantity",
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  IconButton(
                    onPressed: () => setState(() => quantity++),
                    icon: Icon(Icons.add, color: textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Tambah ke Keranjang",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
