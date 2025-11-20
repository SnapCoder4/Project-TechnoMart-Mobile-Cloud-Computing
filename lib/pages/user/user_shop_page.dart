import 'dart:convert';
import 'user_cart_page.dart';
import 'user_product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserShopPage extends StatefulWidget {
  UserShopPage({super.key});

  @override
  State<UserShopPage> createState() => _UserShopPageState();
}

class _UserShopPageState extends State<UserShopPage> {
  String userName = "User";

  final TextEditingController _searchC = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadUserName();

    _searchC.addListener(() {
      setState(() {
        _searchQuery = _searchC.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    String name = currentUser?.displayName ?? "";

    if (name.isEmpty && currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      name = userDoc.data()?['name'] ?? "";
    }

    if (mounted) {
      setState(() {
        userName = name.isNotEmpty ? name : "User";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsRef = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartPage()),
          );
        },
        child: const Icon(Icons.shopping_cart),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Halo, $userName 👋", style: textTheme.bodySmall),
            const SizedBox(height: 16),
            Text(
              "Produk Tersedia",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // SEARCH BAR USER
            TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: "Cari produk...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: productsRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Belum ada produk tersedia.",
                        style: textTheme.bodySmall,
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    if (_searchQuery.isEmpty) return true;
                    return name.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Text(
                        "Tidak ada produk yang cocok dengan pencarian.",
                        style: textTheme.bodySmall,
                      ),
                    );
                  }

                  return GridView.builder(
                    itemCount: filteredDocs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Tanpa nama';
                      final price = (data['price'] ?? 0) as int;
                      final imageBase64 = data['image'] as String?;
                      final productId = doc.id;
                      final description = (data['description'] ?? '') as String;

                      void openDetail() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProductDetailPage(
                              productId: productId,
                              name: name,
                              price: price,
                              imageBase64: imageBase64,
                              description: description,
                            ),
                          ),
                        );
                      }

                      return InkWell(
                        onTap: openDetail,
                        borderRadius: BorderRadius.circular(12),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          color: colorScheme.surface,
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
                                    child: Builder(
                                      builder: (context) {
                                        try {
                                          return Image.memory(
                                            base64Decode(imageBase64),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          );
                                        } catch (e) {
                                          return Container(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.1),
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 40,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.5),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.devices_other_rounded,
                                    size: 40,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rp $price",
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                        ),
                                        onPressed: openDetail,
                                        child: const Text("Detail"),
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
