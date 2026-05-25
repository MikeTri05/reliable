import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_assets.dart';
import '../../core/session/admin_session.dart';
import '../../core/theme/app_colors.dart';
import 'beranda_page.dart';
import 'detail_acara_page.dart';
import 'kartu_page.dart';
import 'login_page.dart';
import 'pengguna_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcaraPage extends StatelessWidget {
  const AcaraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
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
                    _buildTopHeader(context),
                    const SizedBox(height: 14),
                    const Text(
                      'Daftar Acara Donor',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 34,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('acara')
                          .orderBy('tanggalDibuat', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                'Belum ada acara donor yang tersedia.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textGrey),
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final String eventId = doc.id;

                            // Ekstrak data (Sesuaikan key-nya dengan yang ada di Firestore Admin-mu)
                            final String title = data['namaAcara'] ??
                                data['judul'] ??
                                'Acara Tanpa Judul';
                            final String date = data['tanggalPelaksanaan'] ??
                                data['tanggal'] ??
                                '-';
                            final String imageUrl =
                                data['gambarUrl'] ?? data['image_url'] ?? '';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AcaraCard(
                                title: title,
                                date: date,
                                imageUrl: imageUrl, // Kirim link gambar
                                isHighlighted: true,
                                onTap: () => _openDetail(context, eventId,
                                    data), // Kirim data lengkap ke detail
                              ),
                            );
                          }).toList(),
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

  Widget _buildTopHeader(BuildContext context) {
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
                    height: 1.1,
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
          onTap: () => _showExitDialog(context),
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

  void _openDetail(
      BuildContext context, String eventId, Map<String, dynamic> eventData) {
    // Navigasi ke detail acara sambil membawa data lengkap
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailAcaraPage(
          eventId: eventId,
          eventData: eventData,
        ),
      ),
    );
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const BerandaPage()));
      return;
    }
    if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const KartuPage()));
      return;
    }
    if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PenggunaPage()));
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Keluar',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
          content: const Text('Apakah ingin keluar?',
              style: TextStyle(color: AppColors.textDark)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tidak',
                  style: TextStyle(color: AppColors.textDark)),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                await AdminSession.clear();
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }
}

class _AcaraCard extends StatelessWidget {
  final String title;
  final String date;
  final String imageUrl; // Tambahan untuk gambar
  final bool isHighlighted;
  final VoidCallback onTap;

  const _AcaraCard({
    required this.title,
    required this.date,
    required this.onTap,
    this.imageUrl = '',
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHighlighted ? AppColors.secondary : AppColors.background,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 LOGIKA GAMBAR 👇
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 82,
                  height: 56,
                  color: AppColors.secondary,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.photo_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.2,
                            fontWeight: FontWeight.w500,
                            height: 1.28,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontSize: 8.6,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
