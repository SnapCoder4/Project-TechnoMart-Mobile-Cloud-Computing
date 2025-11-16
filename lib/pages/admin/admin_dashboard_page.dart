import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatelessWidget {
  final String adminEmail;
  const AdminDashboardPage({super.key, required this.adminEmail});

  @override
  Widget build(BuildContext context) {
    final productsRef = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Halo, Admin 👋",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            adminEmail,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // kartu hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              "Kelola katalog elektronik Technomart.\n"
              "Tambah, ubah, dan hapus produk dengan mudah.",
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            "Daftar Produk",
            style: TextStyle(
              color: Colors.white,
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
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'Tanpa nama';
                    final price = data['price'] ?? 0;
                    final stock = data['stock'] ?? 0;
                    final imageUrl = data['imageUrl'] as String?;

                    return Card(
                      color: const Color(0xFF020617),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFF111827),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : const Icon(
                                    Icons.devices_other_rounded,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "Rp $price • Stok: $stock",
                          style: const TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: const Color(0xFF020617),
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                          ),
                          onSelected: (value) async {
                            if (value == "delete") {
                              await FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(doc.id)
                                  .delete();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: "delete",
                              child: Text("Hapus"),
                            ),
                          ],
                        ),
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
