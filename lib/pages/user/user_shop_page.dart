import 'dart:convert';
import 'user_cart_page.dart';
import 'user_product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserShopPage extends StatefulWidget {
  const UserShopPage({super.key});

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final productsRef = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true);

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final searchFillColor = isDark ? Colors.grey[850] : Colors.grey[200];
    final priceColor = Colors.green[700];

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? Colors.grey[800] : Colors.black,
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: const Text("Keranjang", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartPage()),
          );
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Halo, $userName 👋",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Temukan produk terbaik untukmu",
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchC,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Cari produk...",
                  hintStyle: TextStyle(color: subTextColor),
                  prefixIcon: Icon(Icons.search, color: subTextColor),
                  filled: true,
                  fillColor: searchFillColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white70 : Colors.black,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Produk Tersedia",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: textColor,
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
                          style: TextStyle(color: subTextColor),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (_searchQuery.isEmpty) return true;
                      return name.contains(_searchQuery);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Text(
                          "Tidak ada produk yang cocok dengan pencarian.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subTextColor),
                        ),
                      );
                    }

                    return GridView.builder(
                      itemCount: filteredDocs.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Tanpa nama';
                        final price = (data['price'] ?? 0) as int;
                        final imageBase64 = data['image'] as String?;
                        final productId = doc.id;
                        final description = data['description'] ?? '';

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
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  spreadRadius: 2,
                                  blurRadius: 12,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                    child:
                                        imageBase64 != null &&
                                            imageBase64.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(imageBase64),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: double.infinity,
                                            color: isDark
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 40,
                                              color: subTextColor,
                                            ),
                                          ),
                                  ),
                                ),

                                Expanded(
                                  flex: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Rp $price",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: priceColor,
                                          ),
                                        ),
                                        const Spacer(),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDark
                                                  ? Colors.grey[800]
                                                  : Colors.black,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            onPressed: openDetail,
                                            child: const Text(
                                              "Detail",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
        ),
      ),
    );
  }
}