import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'beranda_page.dart';
import '../admin/login_penyelenggara_page.dart';
import 'lupa_kata_sandi_page.dart';
import 'register_page.dart';

/// Halaman login peserta
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Siapkan controller untuk Email dan Kata Sandi
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _prosesLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Email dan kata sandi tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil masuk!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BerandaPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan saat masuk.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        pesanError = 'Email atau kata sandi salah. Silakan periksa kembali.';
      } else if (e.code == 'wrong-password') {
        pesanError = 'Kata sandi yang Anda masukkan salah.';
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Container(
              width: 348,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogoHeader(),
                  const SizedBox(height: 34),
                  _buildTitle(),
                  const SizedBox(height: 14),
                  _buildDescription(),
                  const SizedBox(height: 26),
                  _buildTextField(
                    hintText: 'Email',
                    obscureText: false,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    hintText: 'Kata Sandi',
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 20),
                  _buildLoginButton(context),
                  const SizedBox(height: 10),
                  _buildRegisterText(context),
                  const SizedBox(height: 4),
                  _buildForgotPasswordText(context),
                  const SizedBox(height: 16),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.logo,
            width: 118,
            height: 118,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reliable Emergency',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightPink,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Donor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Selamat Datang!',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.1,
      ),
    );
  }

  Widget _buildDescription() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 2.6,
          height: 48,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 10.8,
                height: 1.35,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text:
                      'Pantau jadwal donor darah terbaru, kelola profil Anda, dan jadilah pendonor aktif bersama ',
                ),
                TextSpan(
                  text: 'Reliable Emergency Donor.',
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
    required String hintText,
    required bool obscureText,
    required TextEditingController controller,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        obscureText: obscureText,
        controller: controller,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 10,
            color: AppColors.textGrey,
          ),
          filled: true,
          fillColor: AppColors.white,
          isDense: true,
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

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _prosesLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
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
                'Masuk',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterText(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegisterPage(),
            ),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Daftar',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordText(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LupaKataSandiPage(),
            ),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Lupa Kata Sandi',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 10.8,
            color: AppColors.textDark,
          ),
          children: [
            const TextSpan(text: 'Masuk Sebagai '),
            TextSpan(
              text: 'Penyelenggara',
              style: const TextStyle(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPenyelenggaraPage(),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}
