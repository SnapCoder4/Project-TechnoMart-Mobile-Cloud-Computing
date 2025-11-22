import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTransactionHistoryPage extends StatelessWidget {
  const UserTransactionHistoryPage({super.key});

  Color statusColor(String status) {
    switch (status) {
      case "Paid":
        return Colors.green;
      case "Pending":
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final theme = Theme.of(context);
    final bgColor = isDark ? Colors.black : Colors.grey[100]!;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            "User tidak ditemukan",
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    final ordersRef = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "Riwayat Transaksi",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: textColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Belum ada transaksi",
                style: TextStyle(color: textColor),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;
              final totalPrice = data['totalPrice'] ?? 0;
              final status = data['status'] ?? 'Pending';
              final items = List<Map<String, dynamic>>.from(
                data['items'] ?? [],
              );

              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    "Total ${items.length} item",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    "Tanggal: ${createdAt != null ? createdAt.toDate().toLocal().toString().split(' ')[0] : '-'}\nStatus: $status",
                    style: TextStyle(color: statusColor(status)),
                  ),
                  trailing: Text(
                    "Rp $totalPrice",
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: cardColor,
                        title: Text(
                          "Detail Order",
                          style: TextStyle(color: textColor),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: items.isNotEmpty
                              ? ListView.separated(
                                  shrinkWrap: true,
                                  separatorBuilder: (_, __) =>
                                      Divider(height: 12, color: subTextColor),
                                  itemCount: items.length,
                                  itemBuilder: (context, i) {
                                    final item = items[i];
                                    return Row(
                                      children: [
                                        if (item['image'] != null &&
                                            (item['image'] as String)
                                                .isNotEmpty)
                                          Image.memory(
                                            base64Decode(item['image']),
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        else
                                          Icon(
                                            Icons.devices_other_rounded,
                                            size: 50,
                                            color: subTextColor,
                                          ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'] ?? '-',
                                                style: TextStyle(
                                                  color: textColor,
                                                ),
                                              ),
                                              Text(
                                                "Rp ${item['price']} x ${item['quantity']} = Rp ${item['price'] * item['quantity']}",
                                                style: TextStyle(
                                                  color: subTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : Text(
                                  "Tidak ada item",
                                  style: TextStyle(color: textColor),
                                ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Tutup",
                              style: TextStyle(color: theme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
