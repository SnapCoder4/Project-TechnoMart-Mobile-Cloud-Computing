import 'login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../providers/theme_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  bool showPass = false;

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final fieldFill = isDark ? Colors.grey[850] : Colors.grey[200];
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final buttonColor = isDark ? Colors.grey[800] : Colors.black;
    final buttonTextColor = Colors.white;

    final auth = Provider.of<AuthService>(context, listen: false);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                child: Image.asset(
                  'assets/images/Technomart.png',
                  height: size.height * 0.18,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Buat Akun ✨",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Isi data untuk mendaftar",
                style: TextStyle(fontSize: 15, color: subTextColor),
              ),
              const SizedBox(height: 30),
              _CustomField(
                controller: nameC,
                label: "Nama Lengkap",
                icon: Icons.person_outline,
                fillColor: fieldFill,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: 18),
              _CustomField(
                controller: emailC,
                label: "Email",
                icon: Icons.email_outlined,
                fillColor: fieldFill,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: 18),
              _CustomField(
                controller: passC,
                label: "Password",
                obscure: !showPass,
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    showPass ? Icons.visibility_off : Icons.visibility,
                    color: iconColor,
                  ),
                  onPressed: () => setState(() => showPass = !showPass),
                ),
                fillColor: fieldFill,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: 28),
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "Daftar",
                          style: TextStyle(
                            fontSize: 16,
                            color: buttonTextColor,
                          ),
                        ),
                        onPressed: () async {
                          if (nameC.text.isEmpty ||
                              emailC.text.isEmpty ||
                              passC.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Semua field wajib diisi."),
                              ),
                            );
                            return;
                          }

                          setState(() => loading = true);

                          final error = await auth.registerUser(
                            nameC.text.trim(),
                            emailC.text.trim(),
                            passC.text.trim(),
                          );

                          setState(() => loading = false);

                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Pendaftaran berhasil! Silakan masuk.",
                                ),
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sudah punya akun?",
                    style: TextStyle(color: subTextColor),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      "Masuk",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final Color? fillColor;
  final Color? iconColor;
  final Color? textColor;

  const _CustomField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.fillColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: TextStyle(color: iconColor),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
