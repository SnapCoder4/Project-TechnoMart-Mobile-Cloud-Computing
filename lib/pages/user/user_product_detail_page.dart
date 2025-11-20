import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        SnackBar(
          content: Text(
            "${widget.name} x$quantity berhasil ditambahkan ke keranjang",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambahkan ke keranjang: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    widget.imageBase64 != null && widget.imageBase64!.isNotEmpty
                    ? Image.memory(
                        base64Decode(widget.imageBase64!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: colorScheme.onSurface.withOpacity(0.1),
                        child: Icon(
                          Icons.devices_other_rounded,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              widget.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Rp ${widget.price}",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Deskripsi Produk",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.description.isNotEmpty
                  ? widget.description
                  : "Belum ada deskripsi.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            Text("Jumlah", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() => quantity--);
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text("$quantity", style: theme.textTheme.titleMedium),
                IconButton(
                  onPressed: () {
                    setState(() => quantity++);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : _addToCart,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_shopping_cart),
                label: const Text("Tambahkan ke Keranjang"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
