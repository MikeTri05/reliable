import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo_header.dart';

/// Halaman daftar akun
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 1. Siapkan controller untuk menangkap semua input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _prosesDaftar() async {
    String email = _emailController.text.trim();
    String nama = _namaController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || nama.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom harus diisi!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Buat akun dengan Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 3. Simpan data tambahan ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'namaLengkap': nama,
        'nomorHandphone': phone,
        'role': 'pendonor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil! Silakan masuk.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan saat mendaftar';
      if (e.code == 'weak-password') {
        pesanError = 'Kata sandi terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        pesanError = 'Email ini sudah terdaftar sebelumnya.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email tidak valid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanError)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan sistem: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _namaController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Container(
              width: 360,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 28),
                  _buildTitle(),
                  const SizedBox(height: 12),
                  _buildDescription(),
                  const SizedBox(height: 26),
                  _buildTextField(hint: 'Email', controller: _emailController),
                  const SizedBox(height: 10),
                  _buildTextField(
                      hint: 'Nama Lengkap', controller: _namaController),
                  const SizedBox(height: 10),
                  _buildTextField(
                    hint: 'Nomor Handphone',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                      hint: 'Kata Sandi',
                      controller: _passwordController,
                      obscureText: true),
                  _buildRegisterButton(context),
                  const SizedBox(height: 14),
                  _buildBackText(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const AppLogoHeader();
  }

  Widget _buildTitle() {
    return const Text(
      'Daftar Akun',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildDescription() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 2.5,
          height: 50,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: AppColors.textGrey,
              ),
              children: [
                TextSpan(
                  text:
                      'Setiap tetes darahmu berarti harapan bagi yang membutuhkan. Yuk, jadi bagian dari ',
                ),
                TextSpan(
                  text: 'Reliable Emergency Donor!',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 11,
            color: AppColors.textGrey,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: AppColors.fieldBorder,
              width: 0.9,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _prosesDaftar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Text(
                'Daftar',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBackText(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: _isLoading ? null : () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Kembali',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
