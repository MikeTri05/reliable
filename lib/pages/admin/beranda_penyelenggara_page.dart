import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_assets.dart';
import '../../core/session/admin_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_utils.dart';
import 'data_acara_penyelenggara_page.dart';
import 'data_donor_penyelenggara_page.dart';
import 'data_pengguna_penyelenggara_page.dart';
import 'edit_about_us_page.dart';
import 'login_penyelenggara_page.dart';
import 'manajemen_kantong_darah_page.dart';
import 'tambah_acara_page.dart';
import 'detail_acara_penyelenggara_page.dart';

class BerandaPenyelenggaraPage extends StatelessWidget {
  const BerandaPenyelenggaraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PenyelenggaraBottomNavBar(
        currentIndex: 0,
        onTap: (index) => _onBottomTap(context, index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TambahAcaraPage(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add, color: AppColors.white),
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
                const SizedBox(height: 18), // Sedikit diperlebar
                _buildGreeting(), // 👇 Tambahan Sapaan Admin
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('acara')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int totalAcara =
                              snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildSummaryEventCard(context, totalAcara);
                        },
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'pendonor')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int totalPeserta =
                              snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildSummaryParticipantCard(
                              context, totalPeserta);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        icon: Icons.bloodtype_rounded,
                        title: 'Manajemen Kantong Darah',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManajemenKantongDarahPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        icon: Icons.contact_mail_outlined,
                        title: 'Edit About Us',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditAboutUsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Daftar Acara Terbaru',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('acara')
                            .orderBy('tanggalDibuat', descending: true)
                            .limit(3)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'Belum ada acara donor darah yang dibuat.',
                                  style: TextStyle(
                                      color: AppColors.textGrey, fontSize: 12),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: snapshot.data!.docs.map((doc) {
                              Map<String, dynamic> data =
                                  doc.data() as Map<String, dynamic>? ?? {};
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildEventCard(
                                  context,
                                  title: data['judul'] ?? 'Tanpa Judul',
                                  published:
                                      'Pelaksanaan : ${data['tanggalPelaksanaan'] ?? '-'}',
                                  eventData: data,
                                  eventId: doc.id,
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
                    fontWeight: FontWeight.w500,
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

  // Tampilan Sapaan Admin
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Selamat Datang,',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Admin PMI Desa Hiliweto Gido',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryEventCard(BuildContext context, int totalAcara) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DataAcaraPenyelenggaraPage(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 30,
              color: AppColors.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '$totalAcara Total Event',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryParticipantCard(BuildContext context, int totalPeserta) {
    return InkWell(
      onTap: () {
        // 👇 Diperbaiki agar mengarah lurus ke Halaman Data Pengguna
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DataPenggunaPenyelenggaraPage(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.softSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.groups_2_rounded,
              size: 28,
              color: AppColors.primary,
            ),
            const SizedBox(height: 6),
            Text(
              // Sedikit penyesuaian label agar lebih merepresentasikan data
              '$totalPeserta Total Pendonor Terdaftar',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required String title,
    required String published,
    required Map<String, dynamic> eventData,
    required String eventId,
  }) {
    final completed = isEventCompleted(eventData);

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
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              if (completed) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.successGreenSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 10),
              ],
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
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppColors.textDark,
              ),
            ],
          ),
        ));
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 0) return;

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DataAcaraPenyelenggaraPage(),
        ),
      );
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DataDonorPenyelenggaraPage(),
        ),
      );
      return;
    }

    if (index == 3) {
      Navigator.push(
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
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textDark)),
            ),
            ElevatedButton(
              onPressed: () async {
                final dialogNavigator = Navigator.of(dialogContext);
                final rootNavigator = Navigator.of(context);
                await AdminSession.clear();
                if (!context.mounted || !dialogContext.mounted) return;

                dialogNavigator.pop();
                rootNavigator.pushAndRemoveUntil(
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

class PenyelenggaraBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PenyelenggaraBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
          bottom: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: Icons.grid_view_rounded,
            label: 'Beranda',
            onTap: onTap,
          ),
          _buildNavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: Icons.event_note_outlined,
            label: 'Data Acara',
            onTap: onTap,
          ),
          _buildNavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: Icons.list_alt_rounded,
            label: 'Data Donor',
            onTap: onTap,
          ),
          _buildNavItem(
            index: 3,
            currentIndex: currentIndex,
            icon: Icons.person,
            label: 'Data Pengguna',
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    required ValueChanged<int> onTap,
  }) {
    final isActive = index == currentIndex;
    final color = isActive ? AppColors.primary : AppColors.lightPink;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.2,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
