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

  bool isLoading = true; // loading data user + cart
  bool isProcessing = false; // loading saat tekan checkout

  // item keranjang:
  // { productId, name, image, price, quantity }
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      final userDoc = await firestore.collection('users').doc(userId).get();

      final cartSnapshot = await firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      if (!mounted) return;

      // 🔴 FIX DI SINI: baca address dengan aman
      final userData = userDoc.data();
      String? addr;
      if (userData != null && userData.containsKey('address')) {
        addr = userData['address'] as String?;
      }

      setState(() {
        address = addr ?? '';
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data checkout: $e")));
    }
  }

  Future<void> _checkout() async {
    if (isProcessing) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Keranjang kosong")));
      return;
    }

    setState(() => isProcessing = true);

    try {
      final userId = user.uid;
      final userEmail = user.email ?? '';
      final totalPrice = widget.totalAmount + shippingFee;

      final firestore = FirebaseFirestore.instance;
      final orderRef = firestore.collection('orders').doc();

      // status SELALU Paid
      const status = "Paid";

      await orderRef.set({
        'id': orderRef.id,
        'userId': userId,
        'userEmail': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'items': cartItems,
        'paymentMethod': paymentMethod,
        'status': status,
        'shippingAddress': address ?? '',
        'shippingFee': shippingFee,
        'totalPrice': totalPrice,
      });

      // hapus item di keranjang
      for (var item in cartItems) {
        final String? productId = item['productId'];
        if (productId == null || productId.isEmpty) continue;

        await firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .doc(productId)
            .delete();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Checkout berhasil")));

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Checkout gagal: $e")));
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
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
            const Text("Alamat Pengiriman:"),
            const SizedBox(height: 4),
            Text(
              (address ?? '').isEmpty ? "-" : address!,
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

            const Text("Ringkasan Pembayaran:"),
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
                onPressed: isProcessing ? null : _checkout,
                child: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Konfirmasi Checkout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
