import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'beranda_penyelenggara_page.dart';
import 'data_acara_penyelenggara_page.dart';
import 'data_pengguna_penyelenggara_page.dart';
import 'login_penyelenggara_page.dart';
import 'detail_data_donor_page.dart';

class DataDonorPenyelenggaraPage extends StatefulWidget {
  const DataDonorPenyelenggaraPage({super.key});

  @override
  State<DataDonorPenyelenggaraPage> createState() =>
      _DataDonorPenyelenggaraPageState();
}

class _DataDonorPenyelenggaraPageState
    extends State<DataDonorPenyelenggaraPage> {
  String selectedKategori = 'Baru';

  // 👇 INI YANG TADI HILANG (Wajib ada di sini!) 👇
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
        currentIndex: 2,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildFilterRow(),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    selectedKategori == 'Baru'
                        ? 'Acara Baru'
                        : 'Acara Terdahulu',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('acara')
                        .orderBy('tanggalDibuat',
                            descending: selectedKategori == 'Baru')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Belum ada acara.',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 12),
                          ),
                        );
                      }

                      // MENYARING DATA BERDASARKAN PENCARIAN
                      var docs = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>? ?? {};
                        String title = (data['judul'] ?? '').toLowerCase();
                        return title.contains(searchQuery);
                      }).toList();
                      // 👆 (Kurung nyasar sudah saya hapus di sini) 👆

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Acara tidak ditemukan.',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 12),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data =
                              docs[index].data() as Map<String, dynamic>? ?? {};
                          String eventId = docs[index].id;
                          String title = data['judul'] ?? 'Tanpa Judul';
                          String published =
                              'Pelaksanaan : ${data['tanggalPelaksanaan'] ?? '-'}';

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == docs.length - 1 ? 0 : 10,
                            ),
                            child: _buildCard(
                              context,
                              title,
                              published,
                              eventId,
                            ),
                          );
                        },
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
            Image.asset(AppAssets.logo, width: 32, height: 32),
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
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.logout_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController, // <-- Menangkap ketikan
        onChanged: (value) {
          setState(() {
            searchQuery = value
                .toLowerCase(); // <-- Menyimpan ketikan dan me-refresh layar
          });
        },
        decoration: const InputDecoration(
          hintText: 'Cari Acara',
          hintStyle: TextStyle(color: AppColors.textGrey),
          prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              selectedKategori = value;
            });
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'Baru', child: Text('Baru')),
            PopupMenuItem(value: 'Terdahulu', child: Text('Terdahulu')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selectedKategori),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
      BuildContext context, String title, String published, String eventId) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailDataDonorPage(
              eventId: eventId,
              eventTitle: title,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(12),
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
                    ),
                  ),
                  const SizedBox(height: 6),
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
              Icons.chevron_right,
              color: AppColors.textDark,
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 2) return;
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Keluar'),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun penyelenggara?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
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
                  foregroundColor: AppColors.white),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }
}
