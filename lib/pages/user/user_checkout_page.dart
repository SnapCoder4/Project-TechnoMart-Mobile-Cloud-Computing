import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCheckoutPage extends StatefulWidget {
  final int totalAmount;
  const UserCheckoutPage({super.key, required this.totalAmount});

  @override
  State<UserCheckoutPage> createState() => _UserCheckoutPageState();
}

class _UserCheckoutPageState extends State<UserCheckoutPage> {
  String? address;
  String paymentMethod = "Cash";
  final int shippingFee = 8000;
  bool isLoading = true;

  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final cartSnapshot = await FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items')
        .get();

    setState(() {
      address = userDoc.exists ? userDoc['address'] ?? '' : '';
      cartItems = cartSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'productId': data['productId'],
          'name': data['name'],
          'image': data['image'] ?? '',
          'price': data['price'],
          'quantity': data['quantity'],
        };
      }).toList();
      isLoading = false;
    });
  }

  Future<void> _checkout() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Keranjang kosong")));
      return;
    }

    final totalPrice = widget.totalAmount + shippingFee;
    final orderRef = FirebaseFirestore.instance.collection('orders').doc();

    final status = paymentMethod == "Transfer" ? "Paid" : "Pending";

    await orderRef.set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'items': cartItems,
      'paymentMethod': paymentMethod,
      'status': status,
      'shippingAddress': address ?? '',
      'shippingFee': shippingFee,
      'totalPrice': totalPrice,
    });

    for (var item in cartItems) {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(item['productId'])
          .delete();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Checkout berhasil")));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.totalAmount + shippingFee;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alamat Pengiriman:"),
            const SizedBox(height: 4),
            Text(
              address ?? "-",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (cartItems.isNotEmpty) ...[
              const Text("Daftar Produk:"),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child:
                                  item['image'] != null &&
                                      (item['image'] as String).isNotEmpty
                                  ? Image.memory(
                                      base64Decode(item['image']),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : const Icon(Icons.image, size: 50),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                item['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Text(
                              "Rp ${item['price']} x ${item['quantity']}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text("Ringkasan Pembayaran:"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal:"),
                Text("Rp ${widget.totalAmount}"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text("Ongkir:"), Text("Rp $shippingFee")],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp $totalPrice",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: paymentMethod,
              items: const [
                DropdownMenuItem(value: "Cash", child: Text("Cash")),
                DropdownMenuItem(value: "Transfer", child: Text("Transfer")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    paymentMethod = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _checkout,
                child: const Text("Konfirmasi Checkout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
