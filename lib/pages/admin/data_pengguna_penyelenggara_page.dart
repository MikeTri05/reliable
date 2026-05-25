import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'beranda_penyelenggara_page.dart';
import 'data_acara_penyelenggara_page.dart';
import 'data_donor_penyelenggara_page.dart';
import 'login_penyelenggara_page.dart';
import 'tambah_pengguna_page.dart';
import 'edit_pengguna_page.dart';

/// Halaman data pengguna penyelenggara.
class DataPenggunaPenyelenggaraPage extends StatefulWidget {
  const DataPenggunaPenyelenggaraPage({super.key});

  @override
  State<DataPenggunaPenyelenggaraPage> createState() =>
      _DataPenggunaPenyelenggaraPageState();
}

class _DataPenggunaPenyelenggaraPageState
    extends State<DataPenggunaPenyelenggaraPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PenyelenggaraBottomNavBar(
        currentIndex: 3,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),

                // MENGGUNAKAN STREAMBUILDER DI LEVEL ATAS UNTUK MENGHITUNG STATISTIK
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role',
                            isEqualTo: 'pendonor') // Hanya ambil akun pendonor
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      List<QueryDocumentSnapshot> docs =
                          snapshot.hasData ? snapshot.data!.docs : [];

                      // 1. MENGHITUNG STATISTIK SECARA OTOMATIS
                      int totalPengguna = docs.length;
                      int aktif = 0;
                      int pending = 0;
                      int nonaktif = 0;

                      for (var doc in docs) {
                        var data = doc.data() as Map<String, dynamic>;
                        var status = data['status'] ?? '';
                        if (status == 'Terverifikasi')
                          aktif++;
                        else if (status == 'Pending')
                          pending++;
                        else if (status == 'Nonaktif') nonaktif++;
                      }

                      // 2. MENGURUTKAN NAMA SESUAI ABJAD
                      docs.sort((a, b) {
                        var dataA = a.data() as Map<String, dynamic>;
                        var dataB = b.data() as Map<String, dynamic>;
                        String namaA =
                            (dataA['namaLengkap'] ?? '').toLowerCase();
                        String namaB =
                            (dataB['namaLengkap'] ?? '').toLowerCase();
                        return namaA.compareTo(namaB);
                      });

                      return Column(
                        children: [
                          // Kirim hasil hitungan ke Panel Atas
                          _buildTopPanel(
                              context, totalPengguna, aktif, pending, nonaktif),
                          const SizedBox(height: 18),

                          // Tampilkan daftar pengguna
                          Expanded(
                            child: docs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Belum ada pengguna.',
                                      style: TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 12),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      var data = docs[index].data()
                                          as Map<String, dynamic>;
                                      String docId = docs[index].id;

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              index == docs.length - 1 ? 0 : 10,
                                        ),
                                        child: _buildUserCard(
                                            context, data, docId),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.logo,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reliable Emergency',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightPink,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Donor',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.logout_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Parameter baru ditambahkan agar panel bisa menerima data statistik yang dinamis
  Widget _buildTopPanel(
      BuildContext context, int total, int aktif, int pending, int nonaktif) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatBadge(
                icon: Icons.calendar_month_rounded,
                text: '$total Pengguna', // Dinamis
                background: AppColors.secondary,
                foreground: AppColors.primary,
              ),
              _buildStatBadge(
                icon: Icons.check_circle,
                text: '$aktif Aktif', // Dinamis
                background: AppColors.successGreenSoft,
                foreground: AppColors.successGreen,
              ),
              _buildStatBadge(
                icon: Icons.person_outline,
                text: '$pending Pending', // Dinamis
                background: AppColors.pendingOrangeSoft,
                foreground: AppColors.pendingOrange,
              ),
              _buildStatBadge(
                icon: Icons.remove_circle,
                text: '$nonaktif Nonaktif', // Dinamis
                background: AppColors.inactivePinkSoft,
                foreground: AppColors.inactivePink,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TambahPenggunaPage(),
                  ),
                );
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
                'Tambah Pengguna',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  // Mengubah parameter menjadi data dari Firebase
  Widget _buildUserCard(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'Pending'; // Default pending jika kosong

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Detail pengguna belum tersedia'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.fieldBorder,
              child: const Icon(
                Icons.person,
                size: 20,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['namaLengkap'] ?? 'Tanpa Nama', // Ambil dari Firebase
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data['email'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['noHp'] ?? '-',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(status),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    // DI SINI KITA NANTI AKAN MENGIRIMKAN DATA KE HALAMAN EDIT
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPenggunaPage(
                          userId: docId,
                          userData: data,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.edit_outlined,
                          size: 11,
                          color: AppColors.lightPink,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.lightPink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color background;
    Color foreground;
    IconData icon;

    switch (status) {
      case 'Terverifikasi':
        background = AppColors.successGreen;
        foreground = AppColors.white;
        icon = Icons.check_rounded;
        break;
      case 'Pending':
        background = AppColors.pendingOrangeSoft;
        foreground = AppColors.pendingOrange;
        icon = Icons.person_outline;
        break;
      case 'Nonaktif':
        background = AppColors.inactivePinkSoft;
        foreground = AppColors.inactivePink;
        icon = Icons.remove_circle;
        break;
      default:
        background = AppColors.secondary;
        foreground = AppColors.primary;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun penyelenggara?',
            style: TextStyle(
              color: AppColors.textDark,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: AppColors.textDark,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPenyelenggaraPage(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 3) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BerandaPenyelenggaraPage(),
        ),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DataAcaraPenyelenggaraPage(),
        ),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DataDonorPenyelenggaraPage(),
        ),
      );
    }
  }
}
