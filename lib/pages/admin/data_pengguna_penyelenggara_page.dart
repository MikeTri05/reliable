import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/feature_flags.dart';
import '../../core/session/admin_session.dart';
import '../../core/theme/app_colors.dart';
import 'beranda_penyelenggara_page.dart';
import 'data_acara_penyelenggara_page.dart';
import 'data_donor_penyelenggara_page.dart';
import 'login_penyelenggara_page.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _deletingUserId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Cari pengguna...',
                      hintStyle: const TextStyle(
                          fontSize: 11.5, color: AppColors.textGrey),
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AppColors.textGrey),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                            color: AppColors.fieldBorder, width: 0.9),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

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

                      final rawDocs =
                          snapshot.hasData ? snapshot.data!.docs : [];
                      final docs = rawDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        return !_isSoftDeletedUser(data);
                      }).toList();

                      // 1. MENGHITUNG STATISTIK SECARA OTOMATIS
                      int totalPengguna = docs.length;
                      int aktif = 0;
                      int pending = 0;

                      for (var doc in docs) {
                        var data = doc.data() as Map<String, dynamic>;
                        var status = data['status'] ?? '';
                        if (status == 'Terverifikasi') {
                          aktif++;
                        } else {
                          pending++;
                        }
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

                      // 3. SARING SESUAI PENCARIAN (nama atau email)
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nama = (data['namaLengkap'] ?? '')
                            .toString()
                            .toLowerCase();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        return nama.contains(_searchQuery) ||
                            email.contains(_searchQuery);
                      }).toList();

                      return Column(
                        children: [
                          // Kirim hasil hitungan ke Panel Atas
                          _buildTopPanel(
                              context, totalPengguna, aktif, pending),
                          const SizedBox(height: 18),

                          // Tampilkan daftar pengguna
                          Expanded(
                            child: filteredDocs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Pengguna tidak ditemukan.',
                                      style: TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 12),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filteredDocs.length,
                                    itemBuilder: (context, index) {
                                      var data = filteredDocs[index].data()
                                          as Map<String, dynamic>;
                                      String docId = filteredDocs[index].id;

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              index == filteredDocs.length - 1
                                                  ? 0
                                                  : 10,
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
                    height: 1.0,
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
      BuildContext context, int total, int aktif, int pending) {
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
            ],
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

  bool _isSoftDeletedUser(Map<String, dynamic> data) {
    return data['isDeleted'] == true || data['status'] == 'Dihapus';
  }

  Widget _buildUserCard(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final status =
        data['status'] == 'Terverifikasi' ? 'Terverifikasi' : 'Pending';
    final isDeleting = _deletingUserId == docId;

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
                _buildActionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  color: AppColors.lightPink,
                  onTap: _deletingUserId == null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPenggunaPage(
                                userId: docId,
                                userData: data,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
                if (enableUserDelete) ...[
                  const SizedBox(height: 8),
                  _buildActionButton(
                    label: isDeleting ? 'Hapus...' : 'Hapus',
                    icon: Icons.delete_outline,
                    color: AppColors.primary,
                    onTap: _deletingUserId == null
                        ? () => _showDeleteUserDialog(context, data, docId)
                        : null,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteUserDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String userId,
  ) async {
    final nama = (data['namaLengkap'] ?? 'Tanpa Nama').toString();
    final email = (data['email'] ?? '-').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus User untuk Testing?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fitur ini hanya untuk testing/deployment sementara, bukan final release production.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeleteInfoRow('Nama', nama),
              _buildDeleteInfoRow('Email', email),
              _buildDeleteInfoRow('ID', userId),
              const SizedBox(height: 10),
              const Text(
                'User akan disembunyikan dari daftar dan pencarian pendonor. Data donor/acara/riwayat lama tidak ikut dihapus.',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Hapus User'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _softDeleteUser(userId);
    }
  }

  Widget _buildDeleteInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<void> _softDeleteUser(String userId) async {
    if (_deletingUserId != null) return;

    setState(() => _deletingUserId = userId);
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data();
      final email = (userData?['email'] ?? '').toString().trim();
      final emailLower =
          (userData?['emailLower'] ?? email.toLowerCase()).toString().trim();

      await userRef.update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': 'admin',
        'deletedEmail': email.isEmpty ? FieldValue.delete() : email,
        'deletedEmailLower':
            emailLower.isEmpty ? FieldValue.delete() : emailLower,
        'email': FieldValue.delete(),
        'emailLower': FieldValue.delete(),
        'status': 'Dihapus',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User berhasil dihapus untuk testing.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus user. Silakan coba lagi.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingUserId = null);
      }
    }
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

  void _onBottomTap(BuildContext context, int index) {
    if (index == 3) return;

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BerandaPenyelenggaraPage(),
        ),
      );
      return;
    }

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
    }
  }
}
