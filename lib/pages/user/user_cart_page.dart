import 'dart:convert';
import 'user_checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<String, bool> selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Center(
          child: Text(
            "User tidak ditemukan",
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
      );
    }

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items');

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final buttonColor = isDark ? Colors.grey[800] : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Keranjang"),
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: textColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: buttonColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Keranjang kosong",
                style: TextStyle(fontSize: 16, color: subTextColor),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          int total = 0;
          for (var doc in docs) {
            final docId = doc.id;
            if (selectedItems[docId] == true) {
              final data = doc.data() as Map<String, dynamic>;
              final price = data['price'] ?? 0;
              final qty = data['quantity'] ?? 1;
              total += (price as num).toInt() * (qty as num).toInt();
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index < docs.length) {
                final data = docs[index].data() as Map<String, dynamic>;
                final name = data['name'] ?? '';
                final price = data['price'] ?? 0;
                final quantity = data['quantity'] ?? 1;
                final imageBase64 = data['image'] as String?;
                final docId = docs[index].id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageBase64 != null && imageBase64.isNotEmpty
                          ? Image.memory(
                              base64Decode(imageBase64),
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: subTextColor,
                            ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      "Rp $price x $quantity",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subTextColor,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: selectedItems[docId] ?? false,
                          onChanged: (val) {
                            setState(() {
                              selectedItems[docId] = val ?? false;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: cardColor,
                                title: Text(
                                  "Hapus Produk",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                content: Text(
                                  "Yakin menghapus \"$name\" dari keranjang?",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: subTextColor,
                                  ),
                                ),
                                actionsPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      "Batal",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      "Hapus",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await cartRef.doc(docId).delete();
                              setState(() {
                                selectedItems.remove(docId);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            color: isDark
                                ? Colors.black.withOpacity(0.5)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Total: Rp $total",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: total > 0
                                  ? () {
                                      final selectedDocs = docs
                                          .where(
                                            (doc) =>
                                                selectedItems[doc.id] == true,
                                          )
                                          .map(
                                            (doc) =>
                                                doc.data()
                                                    as Map<String, dynamic>,
                                          )
                                          .toList();

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserCheckoutPage(
                                            totalAmount: total,
                                            selectedProducts: selectedDocs,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Text(
                                "Lanjut Checkout",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }
}
