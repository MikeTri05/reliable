import 'package:flutter/material.dart';
import 'package:reliable_emergency_donor/pages/user/login_page.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo_header.dart';

/// Halaman atur ulang kata sandi.
class AturUlangKataSandiPage extends StatelessWidget {
  const AturUlangKataSandiPage({super.key});

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
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 34),
                  _buildTitle(),
                  const SizedBox(height: 12),
                  _buildDescription(),
                  const SizedBox(height: 28),
                  _buildPasswordField('Kata Sandi Baru'),
                  const SizedBox(height: 10),
                  _buildPasswordField('Konfirmasi Kata Sandi Baru'),
                  const SizedBox(height: 140),
                  _buildSaveButton(context),
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
      'Atur Ulang Kata Sandi',
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
          child: Text(
            'Silakan buat kata sandi baru untuk akun kamu.',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String hint) {
    return SizedBox(
      height: 42,
      child: TextField(
        obscureText: true,
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

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: () {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Kata sandi berhasil diperbarui'),
      duration: Duration(milliseconds: 800),
    ),
  );

  Future.delayed(const Duration(milliseconds: 900), () {
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    }
  });
},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Simpan Kata Sandi',
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
        onTap: () => Navigator.pop(context),
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