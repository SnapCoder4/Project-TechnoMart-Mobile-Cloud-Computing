import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCheckoutPage extends StatefulWidget {
  final int totalAmount;
  final List<Map<String, dynamic>>? selectedProducts;

  const UserCheckoutPage({
    super.key,
    required this.totalAmount,
    this.selectedProducts,
  });

  @override
  State<UserCheckoutPage> createState() => _UserCheckoutPageState();
}

class _UserCheckoutPageState extends State<UserCheckoutPage> {
  String? address;
  String paymentMethod = "Cash";
  final int shippingFee = 8000;

  bool isLoading = true;
  bool isProcessing = false;

  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(userId).get();

      final userData = userDoc.data();

      if (widget.selectedProducts != null) {
        cartItems = widget.selectedProducts!;
      } else {
        final cartSnapshot = await firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .get();
        cartItems = cartSnapshot.docs.map((doc) => doc.data()).toList();
      }

      setState(() {
        address = userData?['address'] ?? "";
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
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
      final totalPrice = widget.totalAmount + shippingFee;

      final orderRef = FirebaseFirestore.instance.collection("orders").doc();

      await orderRef.set({
        "id": orderRef.id,
        "userId": userId,
        "userEmail": user.email,
        "items": cartItems,
        "status": "Paid",
        "shippingAddress": address ?? "",
        "shippingFee": shippingFee,
        "paymentMethod": paymentMethod,
        "totalPrice": totalPrice,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (widget.selectedProducts == null) {
        for (var item in cartItems) {
          FirebaseFirestore.instance
              .collection("carts")
              .doc(userId)
              .collection("items")
              .doc(item["productId"])
              .delete();
        }
      } else {
        for (var item in widget.selectedProducts!) {
          FirebaseFirestore.instance
              .collection("carts")
              .doc(userId)
              .collection("items")
              .doc(item["productId"])
              .delete();
        }
      }

      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pesanan berhasil!")));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _showConfirmDialog(bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Konfirmasi Pesanan",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Apakah kamu yakin ingin melanjutkan dan membuat pesanan sekarang?",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Tidak",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ya", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _checkout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? Colors.black : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final buttonColor = isDark ? Colors.grey[800] : Colors.black;

    final totalPrice = widget.totalAmount + shippingFee;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: buttonColor)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Checkout"),
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: textColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            Text(
              "Alamat Pengiriman",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
                ),
              ),
              child: Text(
                address?.isEmpty ?? true ? "-" : address!,
                style: TextStyle(fontSize: 15, color: textColor),
              ),
            ),
            const SizedBox(height: 20),

            if (cartItems.isNotEmpty) ...[
              Text(
                "Ringkasan Produk",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            color: isDark
                                ? Colors.black.withOpacity(0.5)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child:
                                  item['image'] != null &&
                                      (item['image'] as String).isNotEmpty
                                  ? Image.memory(
                                      base64Decode(item['image']),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.image,
                                      size: 50,
                                      color: subTextColor,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              item['name'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          Text(
                            "Rp ${item['price']} x ${item['quantity']}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subTextColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              "Pembayaran",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 6,
                    color: isDark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _row(
                    "Subtotal",
                    "Rp ${widget.totalAmount}",
                    textColor,
                    subTextColor,
                  ),
                  _row("Ongkir", "Rp $shippingFee", textColor, subTextColor),
                  Divider(color: isDark ? Colors.white38 : Colors.black26),
                  _row(
                    "Total",
                    "Rp $totalPrice",
                    textColor,
                    Colors.green,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Metode Pembayaran",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: paymentMethod,
                  dropdownColor: cardColor,
                  items: const [
                    DropdownMenuItem(value: "Cash", child: Text("Cash")),
                    DropdownMenuItem(
                      value: "Transfer",
                      child: Text("Transfer Bank"),
                    ),
                  ],
                  onChanged: (value) => setState(() => paymentMethod = value!),
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () => _showConfirmDialog(isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isProcessing
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Konfirmasi Pesanan",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String title,
    String value,
    Color titleColor,
    Color valueColor, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: titleColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color ?? valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
