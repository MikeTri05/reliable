import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_assets.dart';
import '../../core/session/admin_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_utils.dart';
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
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // 👇 INI YANG TADI HILANG (Wajib ada di sini!) 👇
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String get _filterTitle {
    if (selectedDate == null && selectedTime == null) {
      return 'Semua Acara Donor';
    }

    final dateLabel =
        selectedDate == null ? 'Semua tanggal' : formatEventDate(selectedDate!);
    final timeLabel = selectedTime == null
        ? ''
        : ' ${formatEventTime(selectedTime!.hour, selectedTime!.minute)} WIB';
    return 'Filter: $dateLabel$timeLabel';
  }

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
                    _filterTitle,
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
                        .orderBy('tanggalDibuat', descending: true)
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
                        final dateMatches = selectedDate == null ||
                            data['tanggalPelaksanaan'] ==
                                formatEventDate(selectedDate!);
                        final timeMatches = selectedTime == null ||
                            data['jamPelaksanaan'] ==
                                formatEventTime(
                                  selectedTime!.hour,
                                  selectedTime!.minute,
                                );
                        return title.contains(searchQuery) &&
                            dateMatches &&
                            timeMatches;
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
                          String published =
                              'Pelaksanaan : ${data['tanggalPelaksanaan'] ?? '-'}, ${data['jamPelaksanaan'] ?? '-'} WIB';

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == docs.length - 1 ? 0 : 10,
                            ),
                            child: _buildCard(
                              context,
                              data,
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
            Image.asset(AppAssets.logo, width: 42, height: 42, fit: BoxFit.contain),
            const SizedBox(width: 6),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reliable Emergency',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.lightPink,
                  ),
                ),
                Text(
                  'Donor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
        style: const TextStyle(
            fontSize: 11.5, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'Cari acara...',
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
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            icon: Icons.calendar_today_outlined,
            label: selectedDate == null
                ? 'Pilih Tanggal'
                : formatEventDate(selectedDate!),
            onTap: () => _pickFilterDate(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            icon: Icons.access_time_rounded,
            label: selectedTime == null
                ? 'Pilih Jam'
                : '${formatEventTime(selectedTime!.hour, selectedTime!.minute)} WIB',
            onTap: () => _pickFilterTime(context),
          ),
        ),
        if (selectedDate != null || selectedTime != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                selectedDate = null;
                selectedTime = null;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFilterDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => selectedDate = picked);
  }

  Future<void> _pickFilterTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => selectedTime = picked);
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> data,
      String published, String eventId) {
    final title = data['judul'] ?? 'Tanpa Judul';

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
                  _buildTitleWithBagCount(title, eventId),
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

  Widget _buildTitleWithBagCount(String title, String eventId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('acara')
          .doc(eventId)
          .collection('peserta')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final totalKantong = docs.fold<int>(0, (total, doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return total + parseBagCount(data['jumlahKantong']);
        });

        return Text(
          '$title (${formatBagCount(totalKantong)})',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        );
      },
    );
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 2) return;
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
                  foregroundColor: AppColors.white),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }
}
