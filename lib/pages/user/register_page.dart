import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/session/account_deletion_guard.dart';
import '../../core/session/admin_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/profile_utils.dart';
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
  bool _obscurePassword = true;

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findUserByEmail(
    String email,
  ) async {
    final emailLower = normalizeEmail(email);
    final usersRef = FirebaseFirestore.instance.collection('users');

    final emailLowerResult = await usersRef
        .where('emailLower', isEqualTo: emailLower)
        .limit(1)
        .get();
    if (emailLowerResult.docs.isNotEmpty) return emailLowerResult.docs.first;

    final deletedEmailLowerResult = await usersRef
        .where('deletedEmailLower', isEqualTo: emailLower)
        .limit(1)
        .get();
    if (deletedEmailLowerResult.docs.isNotEmpty) {
      return deletedEmailLowerResult.docs.first;
    }

    final emailResult =
        await usersRef.where('email', isEqualTo: email).limit(1).get();
    if (emailResult.docs.isNotEmpty) return emailResult.docs.first;

    return null;
  }

  Future<bool> _emailDipakaiUserAktif(String email) async {
    final userDoc = await _findUserByEmail(email);
    if (userDoc == null) return false;

    return !isSoftDeletedUser(userDoc.data());
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findDeletedUserByEmail(
    String email,
  ) async {
    final userDoc = await _findUserByEmail(email);
    if (userDoc == null || !isSoftDeletedUser(userDoc.data())) return null;

    return userDoc;
  }

  Future<UserCredential> _createOrRestoreAuthAccount({
    required String email,
    required String password,
  }) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;

      final deletedUser = await _findDeletedUserByEmail(email);
      if (deletedUser == null) rethrow;

      AccountDeletionGuard.suspendDeletedAccountSignOut = true;
      try {
        return await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException {
        throw FirebaseAuthException(
          code: 'deleted-auth-email-needs-admin-cleanup',
        );
      }
    }
  }

  Future<void> _saveRegisteredUser({
    required String userId,
    required String email,
    required String emailLower,
    required String nama,
    required String phone,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await userRef.set({
      'email': email,
      'emailLower': emailLower,
      'namaLengkap': nama,
      'noHp': phone,
      'nomorHandphone': phone,
      'role': 'pendonor',
      'status': 'Pending',
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userRef.update({
      'deletedAt': FieldValue.delete(),
      'deletedBy': FieldValue.delete(),
      'deletedEmail': FieldValue.delete(),
      'deletedEmailLower': FieldValue.delete(),
    });
  }

  Future<void> _goToLoginAfterRegister() async {
    await AdminSession.clear();
    await FirebaseAuth.instance.signOut();
    AccountDeletionGuard.suspendDeletedAccountSignOut = false;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pendaftaran berhasil! Silakan masuk.')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _prosesDaftar() async {
    String email = _emailController.text.trim();
    String emailLower = normalizeEmail(email);
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
      final emailSudahAda = await _emailDipakaiUserAktif(email);
      if (emailSudahAda) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email ini sudah terdaftar sebelumnya.'),
            ),
          );
        }
        return;
      }

      final userCredential = await _createOrRestoreAuthAccount(
        email: email,
        password: password,
      );
      final userId = userCredential.user?.uid;
      if (userId == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      await _saveRegisteredUser(
        userId: userId,
        email: email,
        emailLower: emailLower,
        nama: nama,
        phone: phone,
      );

      await _goToLoginAfterRegister();
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan saat mendaftar';
      if (e.code == 'weak-password') {
        pesanError = 'Kata sandi terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        pesanError = 'Email ini sudah terdaftar sebelumnya.';
      } else if (e.code == 'deleted-auth-email-needs-admin-cleanup') {
        pesanError =
            'Email ini pernah dihapus, tetapi akun Auth lama masih tersimpan. Hapus akun Auth lewat Firebase Console/Admin SDK atau gunakan kata sandi akun lama untuk daftar ulang.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email tidak valid.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanError)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan sistem: $e')),
      );
    } finally {
      AccountDeletionGuard.suspendDeletedAccountSignOut = false;
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
                      obscureText: _obscurePassword,
                      isPassword: true),
                  const SizedBox(height: 16),
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
          height: 56,
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
                fontSize: 13,
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
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textGrey,
          ),
          filled: true,
          fillColor: AppColors.white,
          suffixIcon: isPassword
              ? IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textGrey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
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
      height: 52,
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
        onTap: _isLoading ? null : () => Navigator.pop(context),
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
