import 'package:flutter/material.dart';
import '../../core/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_utils.dart';
import '../../core/utils/profile_utils.dart';
import 'masukan_data_donor_page.dart';

class DetailDataDonorPage extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const DetailDataDonorPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<DetailDataDonorPage> createState() => _DetailDataDonorPageState();
}

class _DetailDataDonorPageState extends State<DetailDataDonorPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                _buildTitle(),
                const SizedBox(height: 8),
                _buildBloodSummary(),
                const SizedBox(height: 14),
                _buildSearchField(),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildTable(),
                  ),
                ),
                const SizedBox(height: 18),
                _buildAddButton(context),
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
            child: Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.textDark),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Data Donor',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark),
            ),
          ),
        ),
        const SizedBox(width: 26),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.eventTitle,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          height: 1.25),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'Cari no kartu atau nama...',
          hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
          prefixIcon:
              const Icon(Icons.search, size: 18, color: AppColors.textGrey),
          isDense: true,
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide:
                const BorderSide(color: AppColors.fieldBorder, width: 0.9),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
      ),
    );
  }

  String _displayBloodType(dynamic value) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    if (raw.isEmpty || raw == '-') return '-';
    if (bloodTypeOptions.contains(raw)) return raw;
    if (['A', 'B', 'AB', 'O'].contains(raw)) return raw;
    return raw;
  }

  String? _bloodGroup(dynamic value) {
    final goldar = _displayBloodType(value);
    if (goldar == '-') return null;
    if (goldar.startsWith('AB')) return 'AB';
    if (goldar.startsWith('A')) return 'A';
    if (goldar.startsWith('B')) return 'B';
    if (goldar.startsWith('O')) return 'O';
    return null;
  }

  Widget _buildBloodSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('acara')
          .doc(widget.eventId)
          .collection('peserta')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        var total = 0;
        final perGolongan = <String, int>{
          'A': 0,
          'B': 0,
          'AB': 0,
          'O': 0,
        };

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final bags = parseBagCount(data['jumlahKantong']);
          final group = _bloodGroup(data['golonganDarah']);
          total += bags;
          if (group != null) {
            perGolongan[group] = (perGolongan[group] ?? 0) + bags;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Kantong Darah: $total',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Detail Golongan Darah',
              style: TextStyle(
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: perGolongan.entries
                  .map((entry) => _buildBloodSummaryChip(
                        entry.key,
                        entry.value,
                      ))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBloodSummaryChip(String label, int count) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('acara')
          .doc(widget.eventId)
          .collection('peserta')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()));
        }

        List<QueryDocumentSnapshot> allDocs =
            snapshot.hasData ? snapshot.data!.docs : [];

        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final nama = (data['nama'] ?? '').toString().toLowerCase();
          final kartu = (data['kartu'] ?? '').toString().toLowerCase();
          return nama.contains(_searchQuery) || kartu.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Belum ada peserta yang cocok.',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(24),
              1: FlexColumnWidth(),
              2: FixedColumnWidth(42),
              3: FixedColumnWidth(38),
              4: FixedColumnWidth(28),
            },
            border: const TableBorder(
              top: BorderSide(color: AppColors.lightPink, width: 0.8),
              bottom: BorderSide(color: AppColors.lightPink, width: 0.8),
              left: BorderSide(color: AppColors.lightPink, width: 0.8),
              right: BorderSide(color: AppColors.lightPink, width: 0.8),
              horizontalInside:
                  BorderSide(color: AppColors.lightPink, width: 0.8),
              verticalInside:
                  BorderSide(color: AppColors.lightPink, width: 0.8),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.primary),
                children: [
                  _buildHeaderCell('No'),
                  _buildHeaderCell('Peserta'),
                  _buildHeaderCell('Goldar'),
                  _buildHeaderCell('Kantong'),
                  _buildHeaderCell('Aksi'),
                ],
              ),
              ...docs.asMap().entries.map((entry) {
                int index = entry.key;
                String pesertaId = entry.value.id;
                var data = entry.value.data() as Map<String, dynamic>? ?? {};
                final bags = parseBagCount(data['jumlahKantong']);
                final goldar = (data['golonganDarah'] ?? '-').toString();

                return TableRow(
                  decoration: const BoxDecoration(color: AppColors.white),
                  children: [
                    _buildBodyCell('${index + 1}', centered: true),
                    _buildPesertaCell(
                      nama: data['nama'] ?? '-',
                      kartu: data['kartu'] ?? '-',
                    ),
                    _buildGoldarCell(goldar),
                    _buildBodyCell('$bags', centered: true),
                    _buildActionCell(pesertaId),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 9.2,
              fontWeight: FontWeight.w700,
              color: AppColors.white)),
    );
  }

  Widget _buildBodyCell(String text, {bool centered = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(text,
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
              fontSize: 9.4, color: AppColors.textDark, height: 1.15)),
    );
  }

  Widget _buildPesertaCell({
    required String nama,
    required String kartu,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            kartu,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 8.4, color: AppColors.textGrey, height: 1.15),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldarCell(String goldar) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Text(
        _displayBloodType(goldar),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9.4,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _buildActionCell(String pesertaId) {
    return SizedBox(
      height: 30,
      child: Center(
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Konfirmasi Hapus',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  content: const Text(
                      'Apakah Anda yakin ingin menghapus peserta ini?',
                      style: TextStyle(fontSize: 13)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Batal',
                            style: TextStyle(color: AppColors.textGrey))),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        try {
                          await FirebaseFirestore.instance
                              .collection('acara')
                              .doc(widget.eventId)
                              .collection('peserta')
                              .doc(pesertaId)
                              .delete();
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Peserta berhasil dihapus')));
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal menghapus: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white),
                      child: const Text('Hapus'),
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.delete, size: 16, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasukanDataDonorPage()),
          );

          if (!mounted || result == null) return;

          try {
            final Map dataMap = result as Map;
            final targetUserId = dataMap['userId']?.toString() ?? '';
            final targetEmail = dataMap['email']?.toString() ?? '';
            final newNama = dataMap['nama']?.toString() ?? '';
            final newKartu = dataMap['kartu']?.toString() ?? '-';
            final targetGoldar = dataMap['goldar']?.toString() ?? '-';
            final String jumlahKantong =
                dataMap['jumlahKantong']?.toString() ?? '1';

            if (targetUserId.isEmpty)
              throw Exception("ID Pengguna tidak ditemukan");

            final pesertaRef = FirebaseFirestore.instance
                .collection('acara')
                .doc(widget.eventId)
                .collection('peserta')
                .doc(targetUserId);

            final cekDuplikat = await pesertaRef.get();

            if (cekDuplikat.exists) {
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Peserta ini sudah terdaftar!')));
              return;
            }

            final eventSnapshot = await FirebaseFirestore.instance
                .collection('acara')
                .doc(widget.eventId)
                .get();
            final eventData = eventSnapshot.data() ?? {};

            await pesertaRef.set({
              'nama': newNama,
              'kartu': newKartu,
              'waktuDaftar': FieldValue.serverTimestamp(),
              'userId': targetUserId,
              'email': targetEmail,
              'golonganDarah': targetGoldar,
              'status': 'Selesai',
              'namaAcara': eventData['judul'] ?? widget.eventTitle,
              'tanggalPelaksanaan': eventData['tanggalPelaksanaan'] ?? '-',
              'tempat': eventData['tempat'] ?? '-',
              'jumlahKantong': jumlahKantong,
            });
            DateTime tanggalBolehDonorLagi =
                DateTime.now().add(const Duration(days: 90));

            await FirebaseFirestore.instance
                .collection('users')
                .doc(targetUserId)
                .update({
              'tanggalBolehDonorLagi':
                  Timestamp.fromDate(tanggalBolehDonorLagi),
            });

            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(targetUserId)
                .get();
            final fcmToken = userDoc.data()?['fcmToken'];

            if (fcmToken != null) {
              await FCMService.sendPushNotification(
                fcmToken,
                'Terima Kasih, Pahlawan! 🦸‍♂️🩸',
                'Darahmu telah didonorkan. Kamu bisa berdonor kembali setelah melewati masa pemulihan 90 hari.',
              );
            }

            await FirebaseFirestore.instance
                .collection('users')
                .doc(targetUserId)
                .collection('notifikasi')
                .add({
              'judul': 'Terima Kasih, Pahlawan! 🦸‍♂️🩸',
              'pesan':
                  'Darahmu telah didonorkan. Kamu bisa berdonor kembali setelah melewati masa pemulihan 90 hari.',
              'waktu': FieldValue.serverTimestamp(),
              'dibaca': false,
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Selesai! Notifikasi Jeda 90 Hari telah dikirim ke HP Pendonor. 🔔'),
                duration: Duration(seconds: 4),
              ));
            }
          } catch (e) {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terjadi kesalahan: $e')));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Tambah Peserta',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
