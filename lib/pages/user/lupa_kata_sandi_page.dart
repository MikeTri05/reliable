import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo_header.dart';

class LupaKataSandiPage extends StatefulWidget {
  const LupaKataSandiPage({super.key});

  @override
  State<LupaKataSandiPage> createState() => _LupaKataSandiPageState();
}

class _LupaKataSandiPageState extends State<LupaKataSandiPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _prosesResetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Link untuk mengatur ulang sandi telah dikirim ke email Anda.'),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan sistem.';
      if (e.code == 'user-not-found') {
        pesanError = 'Email ini tidak terdaftar di sistem kami.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email tidak valid.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanError)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
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
                  _buildEmailField(),
                  const SizedBox(height: 140),
                  _buildVerifyButton(context),
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
      'Lupa Kata Sandi',
     style: TextStyle(
        fontSize: 22,
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
          height: 60,
         margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Masukkan email yang terdaftar. Kami akan mengirimkan tautan (link) untuk mengatur ulang kata sandi Anda.',
           style: TextStyle(
              fontSize: 13,
             height: 1.35,
             color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
   return SizedBox(
      height: 52,
     child: TextField(
       controller: _emailController,
       keyboardType: TextInputType.emailAddress,
       style: const TextStyle(
          fontSize: 14,
         color: AppColors.textDark,
       ),
       decoration: InputDecoration(
         hintText: 'Masukkan Email',
         hintStyle: const TextStyle(
            fontSize: 13,
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

  Widget _buildVerifyButton(BuildContext context) {
   return SizedBox(
     width: double.infinity,
      height: 52,
     child: ElevatedButton(
       onPressed: _isLoading ? null : _prosesResetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Kirim Tautan Reset',
         style: TextStyle(
            fontSize: 15,
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
              fontSize: 14,
             fontWeight: FontWeight.w500,
             color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
