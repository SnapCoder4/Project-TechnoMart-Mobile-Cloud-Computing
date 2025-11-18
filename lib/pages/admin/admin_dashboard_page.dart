import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatelessWidget {
  final String adminEmail;

  final void Function(String docId, Map<String, dynamic> data) onEditProduct;

  const AdminDashboardPage({
    super.key,
    required this.adminEmail,
    required this.onEditProduct,
  });

  @override
  Widget build(BuildContext context) {
    final productsRef = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            "Halo, Admin 👋",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            adminEmail,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            "Daftar Produk",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: productsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada produk.\nTap tombol + untuk menambah.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'Tanpa nama';
                    final price = data['price'] ?? 0;
                    final stock = data['stock'] ?? 0;
                    final imageBase64 = data['image'] as String?;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageBase64 != null && imageBase64.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Image.memory(
                                  base64Decode(imageBase64),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Rp $price",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                Text(
                                  "Stok: $stock",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => onEditProduct(doc.id, data),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(doc.id)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
