import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_assets.dart';
import '../../core/session/admin_session.dart';
import '../../core/theme/app_colors.dart';
import 'acara_page.dart';
import 'beranda_page.dart';
import 'login_page.dart';
import 'pengguna_page.dart';

class KartuPage extends StatelessWidget {
  const KartuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil UID user yang sedang login
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        // 👇 STREAMBUILDER UNTUK SKENARIO BACK-END REAL-TIME 👇
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Variabel default jika data masih kosong
            String nama = 'Nama Pengguna';
            String golDarah = '-';
            String status = 'Pending';
            String nomorKartu = '0000 0000 0000 0000';

            // Ekstrak data dari Firestore jika ada
            if (snapshot.hasData && snapshot.data!.exists) {
              Map<String, dynamic> data =
                  snapshot.data!.data() as Map<String, dynamic>;
              print('===== DATA DARI FIREBASE: $data =====');
              nama = data['namaLengkap'] ?? 'Nama Pengguna';

              // Mengambil golongan darah, jika belum ada tampilkan strip
              String fetchedGolDarah = data['golonganDarah'] ?? '';
              golDarah = fetchedGolDarah.isNotEmpty &&
                      fetchedGolDarah != 'Belum Terverifikasi (Diisi oleh PMI)'
                  ? fetchedGolDarah
                  : '-';

              status = data['status'] ?? 'Pending';

              // Opsional: Membuat nomor kartu pseudo-random berdasarkan UID agar terlihat unik
              if (currentUser != null) {
                String uidSub = currentUser.uid
                    .replaceAll(RegExp(r'[^0-9]'), '')
                    .padRight(16, '0');
                nomorKartu =
                    '${uidSub.substring(0, 4)} ${uidSub.substring(4, 8)} ${uidSub.substring(8, 12)} ${uidSub.substring(12, 16)}';
              }
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 26),
                  _buildDonorCard(
                      nama: nama, golDarah: golDarah, nomorKartu: nomorKartu),
                  const SizedBox(height: 18),
                  _buildVerificationStatus(status: status),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
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
            onTap: () => _showExitDialog(context),
            borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }

  // 👇 Menerima parameter dinamis 👇
  Widget _buildDonorCard(
      {required String nama,
      required String golDarah,
      required String nomorKartu}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      height: 170,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBase,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            Positioned(top: 14, left: 140, child: _buildSoftDot(20)),
            Positioned(top: 18, left: 250, child: _buildSoftDot(12)),
            Positioned(top: 36, left: 214, child: _buildSoftDot(10)),
            Positioned(top: 58, left: 286, child: _buildSoftDot(16)),
            Positioned(
              top: 0,
              right: 0,
              child: ClipPath(
                clipper: _TopDiagonalClipper(),
                child: Container(
                    width: 210, height: 96, color: AppColors.cardAccentSoft),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: ClipPath(
                clipper: _BottomDiagonalClipper(),
                child: Container(
                    width: 170, height: 86, color: AppColors.cardAccentStrong),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: ClipPath(
                clipper: _BottomInnerDiagonalClipper(),
                child:
                    Container(width: 190, height: 78, color: AppColors.primary),
              ),
            ),
            const Positioned(
              top: 16,
              left: 16,
              child: Text(
                'KARTU DONOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Positioned(
              top: 48,
              left: 16,
              child: Text(
                nama, // Menampilkan nama dinamis
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
            Positioned(
              top: 72,
              left: 16,
              child: Text(
                nomorKartu, // Menampilkan nomor kartu pseudo-dinamis
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Positioned(
              right: 56,
              top: 68,
              child: Container(
                width: 42,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  // 👇 Ikon dihapus, diganti dengan Teks Golongan Darah 👇
                  child: Text(
                    golDarah,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 16,
              child: Row(
                children: [
                  Image.asset(
                    AppAssets.logo,
                    width: 28,
                    height: 28,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lightPink.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
    );
  }

  // 👇 Status dinamis berdasarkan database 👇
  Widget _buildVerificationStatus({required String status}) {
    bool isVerified = status.toLowerCase() == 'terverifikasi' ||
        status.toLowerCase() == 'verified' ||
        status.toLowerCase() == 'aktif';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.successGreen.withOpacity(0.15)
            : AppColors.softCream,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.access_time_rounded,
            size: 16,
            color: isVerified ? AppColors.successGreen : AppColors.softWarning,
          ),
          const SizedBox(width: 10),
          Text(
            isVerified ? 'Kartu Terverifikasi' : 'Kartu sedang di verifikasi',
            style: TextStyle(
              fontSize: 12,
              color: isVerified ? AppColors.successGreen : AppColors.mutedBrown,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 2) return;

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BerandaPage()),
      );
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AcaraPage()),
      );
      return;
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PenggunaPage()),
      );
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

class _TopDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width * 0.28, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.12)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.34, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomInnerDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.45)
      ..lineTo(size.width * 0.76, 0)
      ..lineTo(size.width * 0.22, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
