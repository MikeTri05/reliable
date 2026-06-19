import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class KeamananPage extends StatefulWidget {
  const KeamananPage({super.key});

  @override
  State<KeamananPage> createState() => _KeamananPageState();
}

class _KeamananPageState extends State<KeamananPage> {
  bool isEditing = false;
  bool isSaving = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  // 👇 Controller baru untuk konfirmasi
  late final TextEditingController confirmPasswordController;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    emailController = TextEditingController(text: user?.email ?? '');
    passwordController = TextEditingController(text: '');
    confirmPasswordController = TextEditingController(text: '');
    _loadProfileEmail();
  }

  Future<void> _loadProfileEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;

      final data = doc.data();
      emailController.text = data?['email'] ?? user.email ?? '';
    } catch (_) {
      if (!mounted) return;
      emailController.text = user.email ?? '';
    }
  }

  Future<void> _updateSecurityData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String newPassword = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    // 1. Validasi: Tidak boleh kosong
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Semua kolom password harus diisi!');
      return;
    }

    // 2. Validasi: Panjang karakter
    if (newPassword.length < 6) {
      _showSnackBar('Password minimal 6 karakter!');
      return;
    }

    // 3. Validasi: Harus sama (Konfirmasi Password)
    if (newPassword != confirmPassword) {
      _showSnackBar('Konfirmasi password tidak cocok!');
      return;
    }

    setState(() => isSaving = true);

    try {
      await user.updatePassword(newPassword);

      if (mounted) {
        setState(() {
          isEditing = false;
          _obscureNewPassword = true;
          _obscureConfirmPassword = true;
          passwordController.clear();
          confirmPasswordController.clear();
        });
        _showSnackBar('Password berhasil diperbarui!');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnackBar('Password gagal diperbarui. Silakan masuk ulang.');
      } else {
        _showSnackBar('Gagal: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              const Text('Email',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              _buildSecurityField(
                  controller: emailController, isReadOnly: true),

              const SizedBox(height: 16),

              const Text('Password Baru',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              _buildSecurityField(
                controller: passwordController,
                obscureText: _obscureNewPassword,
                isReadOnly: !isEditing,
                hintText: isEditing ? 'Ketik password baru...' : '********',
                showVisibilityToggle: isEditing,
                onToggleVisibility: () => setState(
                  () => _obscureNewPassword = !_obscureNewPassword,
                ),
              ),

              // 👇 KOLOM KONFIRMASI BARU 👇
              if (isEditing) ...[
                const SizedBox(height: 16),
                const Text('Ulangi Password Baru',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                _buildSecurityField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  isReadOnly: false,
                  hintText: 'Ketik ulang password...',
                  showVisibilityToggle: true,
                  onToggleVisibility: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              if (isEditing) _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.textDark),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text('Ganti Kata Sandi',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark)),
          ),
        ),
        InkWell(
          onTap: () {
            setState(() {
              isEditing = !isEditing;
              if (!isEditing) {
                _obscureNewPassword = true;
                _obscureConfirmPassword = true;
                passwordController.clear();
                confirmPasswordController.clear();
              }
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(isEditing ? Icons.close : Icons.edit_outlined,
                size: 18, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityField({
    required TextEditingController controller,
    bool obscureText = false,
    bool isReadOnly = true,
    String? hintText,
    bool showVisibilityToggle = false,
    VoidCallback? onToggleVisibility,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        obscureText: obscureText,
        cursorColor: AppColors.primary,
        style: TextStyle(
          fontSize: 12,
          color: isReadOnly ? AppColors.textGrey : AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          filled: true,
          fillColor: isReadOnly ? AppColors.offWhite : AppColors.white,
          suffixIcon: showVisibilityToggle
              ? IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textGrey,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
              color: isReadOnly ? AppColors.fieldBorder : AppColors.lightPink,
              width: 0.9,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: isSaving
            ? null
            : () {
                if (isEditing) {
                  _updateSecurityData();
                } else {
                  _showSnackBar('Tekan ikon edit untuk mengubah password');
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Simpan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
