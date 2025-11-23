import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatefulWidget {
  final String adminEmail;
  final void Function(String docId, Map<String, dynamic> data) onEditProduct;

  const AdminDashboardPage({
    super.key,
    required this.adminEmail,
    required this.onEditProduct,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final TextEditingController _searchC = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
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

  Future<bool?> _confirmDelete(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          "Konfirmasi Hapus",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus produk ini?",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
            child: Text(
              "Batal",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              "Hapus",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Halo, Admin 👋",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.adminEmail,
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
              const SizedBox(height: 24),

              // SEARCH
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
                "Daftar Produk",
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
                          "Belum ada produk.\nTap tombol + untuk menambah.",
                          textAlign: TextAlign.center,
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

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;

                        // --- RESPONSIVE GRID ---
                        // HP sangat kecil (<= 360)    -> 1 kolom
                        // HP normal (361 - 600)      -> 2 kolom
                        // Tablet kecil (601 - 900)   -> 3 kolom
                        // Tablet / web sedang        -> 4-5 kolom
                        int crossAxisCount = 2;
                        if (width <= 360) {
                          crossAxisCount = 1;
                        } else if (width > 1200) {
                          crossAxisCount = 5;
                        } else if (width > 900) {
                          crossAxisCount = 4;
                        } else if (width > 600) {
                          crossAxisCount = 3;
                        }

                        final bool isVerySmall = width <= 360;
                        final bool isSmallPhone = width > 360 && width <= 420;

                        // Atur tinggi gambar & rasio kartu berdasarkan lebar
                        final double imageHeight = isVerySmall
                            ? 120
                            : isSmallPhone
                            ? 130
                            : 140;

                        final double childAspectRatio = isVerySmall
                            ? 0.80
                            : 0.65;

                        // Helper font biar mengecil di layar kecil
                        double font(double normal, double small) =>
                            (isVerySmall || isSmallPhone) ? small : normal;

                        return GridView.builder(
                          itemCount: filteredDocs.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: childAspectRatio,
                              ),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            final name = data['name'] ?? 'Tanpa nama';
                            final price = data['price'] ?? 0;
                            final stock = data['stock'] ?? 0;
                            final desc = data['description'] ?? '';
                            final imageBase64 = data['image'] as String?;

                            return Container(
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
                                children: [
                                  // Gambar
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                    child:
                                        imageBase64 != null &&
                                            imageBase64.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(imageBase64),
                                            height: imageHeight,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: imageHeight,
                                            alignment: Alignment.center,
                                            color: isDark
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: font(40, 32),
                                              color: subTextColor,
                                            ),
                                          ),
                                  ),

                                  // Isi card
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: font(16, 14),
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Rp $price",
                                                style: TextStyle(
                                                  fontSize: font(15, 13),
                                                  fontWeight: FontWeight.bold,
                                                  color: priceColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Stok: $stock",
                                                style: TextStyle(
                                                  fontSize: font(13, 12),
                                                  color: subTextColor,
                                                ),
                                              ),
                                              if (desc
                                                  .toString()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  desc,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: font(12, 11),
                                                    color: subTextColor,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          // Tombol Edit & Hapus
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blueAccent,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: isVerySmall
                                                              ? 4
                                                              : 6,
                                                        ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  icon: Icon(
                                                    Icons.edit,
                                                    size: font(18, 16),
                                                    color: Colors.white,
                                                  ),
                                                  label: FittedBox(
                                                    child: Text(
                                                      "Edit",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: font(13, 11),
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      widget.onEditProduct(
                                                        doc.id,
                                                        data,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: isVerySmall
                                                              ? 4
                                                              : 6,
                                                        ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  icon: Icon(
                                                    Icons.delete,
                                                    size: font(18, 16),
                                                    color: Colors.white,
                                                  ),
                                                  label: FittedBox(
                                                    child: Text(
                                                      "Hapus",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: font(13, 11),
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    final confirm =
                                                        await _confirmDelete(
                                                          context,
                                                        );
                                                    if (confirm == true) {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                            'products',
                                                          )
                                                          .doc(doc.id)
                                                          .delete();
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
