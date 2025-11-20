import 'dart:convert';
import 'package:flutter/material.dart';
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
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User tidak ditemukan")));
    }

    final ordersRef = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId);

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Transaksi")),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada transaksi"));
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
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    "Total ${items.length} item",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Tanggal: ${createdAt != null ? createdAt.toDate().toLocal().toString().split(' ')[0] : '-'}\nStatus: $status",
                    style: TextStyle(color: statusColor(status)),
                  ),
                  trailing: Text("Rp $totalPrice"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Detail Order"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: items.isNotEmpty
                              ? ListView.separated(
                                  shrinkWrap: true,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 12),
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
                                          const Icon(
                                            Icons.devices_other_rounded,
                                            size: 50,
                                          ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item['name'] ?? '-'),
                                              Text(
                                                "Rp ${item['price']} x ${item['quantity']} = Rp ${item['price'] * item['quantity']}",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : const Text("Tidak ada item"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Tutup"),
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
