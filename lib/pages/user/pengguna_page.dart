import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Wajib untuk autentikasi dan logout
import 'package:cloud_firestore/cloud_firestore.dart'; // Wajib untuk tarik data nama user
import 'package:reliable_emergency_donor/pages/user/login_page.dart';
import '../../core/constants/app_assets.dart';
import '../../core/session/admin_session.dart';
import '../../core/theme/app_colors.dart';
import 'acara_page.dart';
import 'beranda_page.dart';
import 'detail_pengguna_page.dart';
import 'keamanan_page.dart';
import 'kartu_page.dart';
import 'riwayat_donor_page.dart';
import 'tentang_page.dart';

/// Halaman pengguna sesuai mockup.
class PenggunaPage extends StatelessWidget {
  const PenggunaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 14),
                    _buildProfileCard(
                        context), // Ini yang akan otomatis memanggil data
                    const SizedBox(height: 14),
                    _buildSettingsTitle(),
                    const SizedBox(height: 10),
                    _buildSettingItem(
                      context,
                      icon: Icons.person_2_outlined,
                      title: 'Detail Pengguna',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DetailPenggunaPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSettingItem(
                      context,
                      icon: Icons.shield_outlined,
                      title: 'Kata Sandi',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KeamananPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSettingItem(
                      context,
                      icon: Icons.assignment_outlined,
                      title: 'Riwayat Donor',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RiwayatDonorPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSettingItem(
                      context,
                      icon: Icons.info_outline,
                      title: 'Tentang',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TentangPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.logo,
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reliable Emergency',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightPink,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Donor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: const Text(
                    'Keluar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: const Text(
                    'Apakah kamu ingin keluar?',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text(
                        'Tidak',
                        style: TextStyle(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      // 👇 SEKARANG BENAR-BENAR LOGOUT DARI FIREBASE 👇
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance
                              .signOut(); // Putus sesi dari Firebase
                          await AdminSession.clear();

                          if (context.mounted) {
                            Navigator.pop(dialogContext); // Tutup dialog dulu
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal keluar: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.12),
          highlightColor: AppColors.primary.withOpacity(0.06),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.logout_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // 👇 INI BAGIAN YANG DIUBAH AGAR MEMUNCULKAN DATA ASLI 👇
  Widget _buildProfileCard(BuildContext context) {
    // Ambil akun user yang sedang login saat ini
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Jika entah kenapa tidak ada user yang login (biasanya karena belum login/sesi habis)
    if (currentUser == null) {
      return const Center(
          child: Text("Sesi telah habis, silakan login kembali."));
    }

    return StreamBuilder<DocumentSnapshot>(
      // Membaca data spesifik milik user tersebut berdasarkan UID-nya
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Tampilan sementara saat aplikasi sedang menarik data dari database
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Variabel default jika data masih kosong
        String nama = 'Tanpa Nama';
        String email = currentUser.email ?? '-';

        // Jika data berhasil ditarik, masukkan ke variabel
        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          nama = data['namaLengkap'] ?? 'Tanpa Nama';
          email = data['email'] ?? currentUser.email ?? '-';
        }

        return Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DetailPenggunaPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.primary.withOpacity(0.08),
            highlightColor: AppColors.primary.withOpacity(0.04),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.secondary,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama, // Data dinamis dari Firebase
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email, // Data dinamis dari Auth
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 13,
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

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.primary.withOpacity(0.10),
        highlightColor: AppColors.primary.withOpacity(0.05),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.background,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 3) return;

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BerandaPage(),
        ),
      );
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AcaraPage(),
        ),
      );
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const KartuPage(),
        ),
      );
    }
  }
}
