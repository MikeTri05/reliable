import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Wajib ditambahkan untuk memanggil Firebase
import '../../core/theme/app_colors.dart';
import '../../core/utils/profile_utils.dart';

/// Halaman tambah pengguna.
class TambahPenggunaPage extends StatefulWidget {
  const TambahPenggunaPage({super.key});

  @override
  State<TambahPenggunaPage> createState() => _TambahPenggunaPageState();
}

class _TambahPenggunaPageState extends State<TambahPenggunaPage> {
  late final TextEditingController _namaController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _genderController;
  late final TextEditingController _alamatController;

  String bloodType = bloodTypeOptions.first;

  @override
  void initState() {
    super.initState();
    // Dikosongkan agar admin bisa mengetik data baru
    _namaController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _genderController = TextEditingController();
    _alamatController = TextEditingController();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<bool> _emailSudahTerdaftar(String email) async {
    final emailLower = normalizeEmail(email);
    final usersRef = FirebaseFirestore.instance.collection('users');

    final checks = await Future.wait([
      usersRef.where('emailLower', isEqualTo: emailLower).limit(1).get(),
      usersRef.where('email', isEqualTo: email).limit(1).get(),
    ]);

    return checks.any((snapshot) => snapshot.docs.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 22),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Nama lengkap'),
                        const SizedBox(height: 6),
                        _buildTextField(controller: _namaController),
                        const SizedBox(height: 12),
                        _buildLabel('Email'),
                        const SizedBox(height: 6),
                        _buildTextField(controller: _emailController),
                        const SizedBox(height: 12),
                        _buildLabel('No. HP'),
                        const SizedBox(height: 6),
                        _buildTextField(controller: _phoneController),
                        const SizedBox(height: 12),
                        _buildLabel('Jenis Kelamin'),
                        const SizedBox(height: 6),
                        _buildTextField(controller: _genderController),
                        const SizedBox(height: 12),
                        _buildLabel('Alamat'),
                        const SizedBox(height: 6),
                        _buildAddressField(),
                        const SizedBox(height: 12),
                        _buildLabel('Golongan Darah'),
                        const SizedBox(height: 6),
                        _buildBloodTypeField(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildAddButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.textDark,
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Tambah pengguna',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 26),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textGrey,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return SizedBox(
      height: 70,
      child: TextField(
        controller: _alamatController,
        cursorColor: AppColors.primary,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBloodTypeField() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: bloodType,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AppColors.textDark,
          ),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textDark,
          ),
          items: bloodTypeOptions
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              bloodType = value!;
            });
          },
        ),
      ),
    );
  }

  // 👇 INI BAGIAN YANG PALING PENTING 👇
  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: () async {
          // 1. Ambil semua teks dari inputan
          final nama = _namaController.text.trim();
          final email = _emailController.text.trim();
          final phone = _phoneController.text.trim();
          final gender = _genderController.text.trim();
          final alamat = _alamatController.text.trim();

          // 2. Validasi: Jangan biarkan admin menyimpan data kosong
          if (nama.isEmpty || email.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nama dan Email wajib diisi!')),
            );
            return;
          }

          if (!email.contains('@')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Format email tidak valid.')),
            );
            return;
          }

          // 3. Simpan ke Firebase Database
          try {
            final emailSudahAda = await _emailSudahTerdaftar(email);
            if (emailSudahAda) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email ini sudah terdaftar sebelumnya.'),
                ),
              );
              return;
            }

            await FirebaseFirestore.instance.collection('users').add({
              'namaLengkap': nama,
              'email': email,
              'emailLower': normalizeEmail(email),
              'noHp': phone,
              'jenisKelamin': gender,
              'alamat': alamat,
              'golonganDarah': bloodType,
              'status': 'Terverifikasi', // Status bawaan
              'role': 'pendonor', // Penting! Agar terbaca di fitur lain
              'tanggalDaftar': FieldValue.serverTimestamp(),
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengguna berhasil ditambahkan!')),
              );
              // Tutup halaman setelah berhasil
              Navigator.pop(context);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menambahkan pengguna: $e')),
              );
            }
          }
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
          'Tambah',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
