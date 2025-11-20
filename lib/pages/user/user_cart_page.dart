import 'dart:convert';
import 'user_checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User tidak ditemukan")));
    }

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items');

    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Keranjang kosong"));
          }

          final docs = snapshot.data!.docs;

          int total = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = data['price'] ?? 0;
            final qty = data['quantity'] ?? 1;
            total += (price as num).toInt() * (qty as num).toInt();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index < docs.length) {
                final data = docs[index].data() as Map<String, dynamic>;
                final name = data['name'] ?? '';
                final price = data['price'] ?? 0;
                final quantity = data['quantity'] ?? 1;
                final imageBase64 = data['image'] as String?;
                final docId = docs[index].id;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: imageBase64 != null && imageBase64.isNotEmpty
                        ? Image.memory(
                            base64Decode(imageBase64),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.devices_other_rounded, size: 40),
                    title: Text(name),
                    subtitle: Text("Rp $price x $quantity"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Hapus item"),
                            content: Text(
                              "Apakah Anda yakin ingin menghapus $name dari keranjang?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Batal"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("Hapus"),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await cartRef.doc(docId).delete();
                        }
                      },
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        "Total: Rp $total",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserCheckoutPage(totalAmount: total),
                            ),
                          );
                        },
                        child: const Text("Checkout"),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
