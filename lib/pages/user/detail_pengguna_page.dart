import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';

class DetailPenggunaPage extends StatefulWidget {
  const DetailPenggunaPage({super.key});

  @override
  State<DetailPenggunaPage> createState() => _DetailPenggunaPageState();
}

class _DetailPenggunaPageState extends State<DetailPenggunaPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // 👇 Tambah controller khusus untuk golongan darah yang dikunci
  final TextEditingController _bloodTypeController = TextEditingController();

  bool _isLoadingData = true;
  bool _isSavingData = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _namaController.text = data['namaLengkap'] ?? '';
            _phoneController.text = data['noHp'] ?? '';
            _emailController.text = data['email'] ?? currentUser.email ?? '';

            // 👇 Logika Golongan Darah: Isi kalau ada, tampilkan pesan kalau kosong
            String? savedBloodType = data['golonganDarah'];
            if (savedBloodType != null && savedBloodType.isNotEmpty) {
              _bloodTypeController.text = savedBloodType;
            } else {
              _bloodTypeController.text =
                  'Belum Terverifikasi (Diisi oleh PMI)';
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat data: $e')),
          );
        }
      }
    }
    setState(() {
      _isLoadingData = false;
    });
  }

  Future<void> _saveUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String nama = _namaController.text.trim();
    String phone = _phoneController.text.trim();

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isSavingData = true;
    });

    try {
      // 👇 Update HANYA nama dan no HP. Golongan darah tidak dikirim agar tidak berubah.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'namaLengkap': nama,
        'noHp': phone,
        // Status otomatis jadi Pending jika profil diupdate agar admin ngecek lagi
        'status': 'Pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Data Pribadi'),
                      const SizedBox(height: 14),

                      const _FieldLabel('Nama Lengkap'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _namaController,
                        hintText: 'Masukkan Nama Lengkap',
                        isActive: true,
                      ),
                      const SizedBox(height: 12),

                      const _FieldLabel('Nomor Hp'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: 'Masukkan Nomor Hp',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      const _FieldLabel('Email (Tidak dapat diubah)'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Masukkan Email',
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle(
                          'Data Medis'), // 👇 Ubah judul biar lebih profesional
                      const SizedBox(height: 14),

                      const _FieldLabel(
                          'Golongan Darah (Diisi oleh petugas PMI)'),
                      const SizedBox(height: 6),
                      // 👇 Menggunakan text field yang dikunci
                      _buildTextField(
                        controller: _bloodTypeController,
                        hintText: 'Belum Terverifikasi',
                        readOnly: true,
                      ),
                      const SizedBox(height: 18),

                      _buildSaveButton(context),
                      const SizedBox(height: 180),
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
          borderRadius: BorderRadius.circular(18),
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
              'Detail Pengguna',
              style: TextStyle(
                fontSize: 12.5,
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

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isActive = false,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        cursorColor: AppColors.primary,
        style: TextStyle(
          fontSize: 12,
          color: readOnly ? AppColors.textGrey : AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
          ),
          filled: true,
          fillColor: readOnly ? AppColors.offWhite : AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
              color: isActive ? AppColors.lightPink : AppColors.fieldBorder,
              width: isActive ? 1 : 0.9,
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
        onPressed: _isSavingData ? null : _saveUserData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSavingData
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text(
                'Simpan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    );
  }
}
