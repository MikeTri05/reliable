import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/profile_utils.dart';

/// Halaman edit pengguna.
class EditPenggunaPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditPenggunaPage({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<EditPenggunaPage> createState() => _EditPenggunaPageState();
}

class _EditPenggunaPageState extends State<EditPenggunaPage> {
  late final TextEditingController _namaController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _genderController;
  late final TextEditingController _alamatController;

  String bloodType = bloodTypeOptions.first;
  String statusAkun = 'Pending';

  @override
  void initState() {
    super.initState();
    // Mengisi kolom otomatis dengan data dari database
    _namaController =
        TextEditingController(text: widget.userData['namaLengkap'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.userData['noHp'] ?? '');
    _genderController =
        TextEditingController(text: widget.userData['jenisKelamin'] ?? '');
    _alamatController =
        TextEditingController(text: widget.userData['alamat'] ?? '');

    bloodType = normalizeBloodType(widget.userData['golonganDarah']);
    statusAkun = widget.userData['status'] ?? 'Pending';

    // Validasi jaga-jaga untuk status
    if (!['Terverifikasi', 'Pending'].contains(statusAkun)) {
      statusAkun = 'Pending';
    }
  }

  Future<bool> _emailDipakaiPenggunaLain(String email) async {
    final emailLower = normalizeEmail(email);
    final usersRef = FirebaseFirestore.instance.collection('users');

    final checks = await Future.wait([
      usersRef.where('emailLower', isEqualTo: emailLower).limit(2).get(),
      usersRef.where('email', isEqualTo: email).limit(2).get(),
    ]);

    return checks
        .expand((snapshot) => snapshot.docs)
        .any((doc) => doc.id != widget.userId);
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
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileSection(),
                          const SizedBox(height: 14),
                          _buildContactInfo(),
                          const SizedBox(height: 16),
                          _buildStatusCard(context),
                          const SizedBox(height: 18),
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
                ),
                const SizedBox(height: 14),
                _buildSaveButton(context),
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
              'Edit pengguna',
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

  Widget _buildProfileSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.fieldBorder,
          child: const Icon(
            Icons.person,
            size: 30,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _namaController.text.isNotEmpty
                      ? _namaController.text
                      : 'Tanpa Nama',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusAkun == 'Terverifikasi'
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.pendingOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusAkun,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: statusAkun == 'Terverifikasi'
                          ? AppColors.successGreen
                          : AppColors.pendingOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.mail_outline,
          text: _emailController.text.isNotEmpty ? _emailController.text : '-',
        ),
        const SizedBox(height: 6),
        _InfoRow(
          icon: Icons.phone_outlined,
          text: _phoneController.text.isNotEmpty ? _phoneController.text : '-',
        ),
        const SizedBox(height: 6),
        _InfoRow(
          icon: Icons.bloodtype_outlined,
          text: 'Golongan Darah : $bloodType',
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Ubah Status Akun:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.softGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: statusAkun,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.textDark),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                items: ['Terverifikasi', 'Pending']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      statusAkun = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
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
                (type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              bloodType = value;
            });
          },
        ),
      ),
    );
  }

  // 👇 INI BAGIAN UPDATE KE FIREBASE 👇
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: () async {
          try {
            final email = _emailController.text.trim();
            if (email.isEmpty || !email.contains('@')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Format email tidak valid.')),
              );
              return;
            }

            final emailDipakai = await _emailDipakaiPenggunaLain(email);
            if (emailDipakai) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email ini sudah dipakai pengguna lain.'),
                ),
              );
              return;
            }

            // MENGGUNAKAN .update() UNTUK MEMPERBARUI DATA
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId) // Menunjuk ke ID dokumen spesifik
                .update({
              'namaLengkap': _namaController.text.trim(),
              'email': email,
              'emailLower': normalizeEmail(email),
              'noHp': _phoneController.text.trim(),
              'jenisKelamin': _genderController.text.trim(),
              'alamat': _alamatController.text.trim(),
              'golonganDarah': bloodType,
              'status': statusAkun,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Data pengguna berhasil diperbarui!')),
              );
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal memperbarui data: $e')),
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
          'Simpan',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textGrey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}
