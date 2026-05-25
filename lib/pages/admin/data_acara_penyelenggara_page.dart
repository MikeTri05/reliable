import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'beranda_penyelenggara_page.dart';
import 'data_donor_penyelenggara_page.dart';
import 'data_pengguna_penyelenggara_page.dart';
import 'detail_acara_penyelenggara_page.dart';
import 'login_penyelenggara_page.dart';
import 'tambah_acara_page.dart';

class DataAcaraPenyelenggaraPage extends StatelessWidget {
  const DataAcaraPenyelenggaraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PenyelenggaraBottomNavBar(
        currentIndex: 1,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 14),
                _buildAddEventButton(context),
                const SizedBox(height: 18),
                Expanded(
                  // Menggunakan StreamBuilder untuk menarik data langsung
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('acara')
                        .orderBy('tanggalDibuat',
                            descending: true) // Diurutkan dari yang paling baru
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Belum ada acara. Silakan tambah acara baru.',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                          ),
                        );
                      }

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildSectionTitle('Semua Acara', showAccent: true),
                          const SizedBox(height: 10),
                          // Looping data dari Firestore menjadi widget EventCard
                          ...snapshot.data!.docs.map((doc) {
                            Map<String, dynamic> data =
                                doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildEventCard(
                                context,
                                title: data['judul'] ?? 'Tanpa Judul',
                                published:
                                    'Pelaksanaan : ${data['tanggalPelaksanaan'] ?? ''}',
                                eventData: data,
                                eventId: doc.id, // ID dokumen untuk detail/edit
                              ),
                            );
                          }).toList(),
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
          children: [
            Image.asset(
              AppAssets.logo,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reliable Emergency',
                  style: TextStyle(
                    fontSize: 7.5,
                    color: AppColors.lightPink,
                  ),
                ),
                Text(
                  'Donor',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddEventButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TambahAcaraPage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Text(
          'Tambah Acara Baru',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showAccent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        if (showAccent) ...[
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
      ],
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required String title,
    required String published,
    required Map<String, dynamic> eventData,
    required String eventId,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAcaraPenyelenggaraPage(
              canEdit: true,
              eventData: eventData,
              eventId: eventId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    published,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: AppColors.textDark,
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 1) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BerandaPenyelenggaraPage(),
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
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DataPenggunaPenyelenggaraPage(),
        ),
      );
    }
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
                style: TextStyle(color: AppColors.textDark),
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
}
