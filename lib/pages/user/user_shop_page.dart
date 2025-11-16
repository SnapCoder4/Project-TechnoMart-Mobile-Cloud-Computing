import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserShopPage extends StatelessWidget {
  final String userEmail;
  const UserShopPage({super.key, required this.userEmail});

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
            "Selamat datang,",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            userEmail,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              "Explore gadget & elektronik kekinian.\n"
              "Tap produk untuk lihat detail dan lakukan pembelian.",
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Rekomendasi Untukmu",
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
                      "Belum ada produk tersedia.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return GridView.builder(
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'Tanpa nama';
                    final price = data['price'] ?? 0;
                    final imageUrl = data['imageUrl'] as String?;

                    return GestureDetector(
                      onTap: () {
                        // TODO: nanti bikin detail + tombol beli
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: Colors.white12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF1E293B),
                                        Color(0xFF0EA5E9),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.devices_other_rounded,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rp $price",
                              style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: proses add to cart / beli
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Fitur beli belum diimplementasi.",
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Beli",
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
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
