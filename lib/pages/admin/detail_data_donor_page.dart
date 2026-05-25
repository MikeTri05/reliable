import 'package:flutter/material.dart';
import '../../core/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
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
                const SizedBox(height: 28),
                _buildTitle(),
                const SizedBox(height: 18),
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

        List<QueryDocumentSnapshot> docs =
            snapshot.hasData ? snapshot.data!.docs : [];

        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(26),
              1: FixedColumnWidth(96),
              2: FlexColumnWidth(),
              3: FixedColumnWidth(28),
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
                  _buildHeaderCell('Nomor Kartu'),
                  _buildHeaderCell('Nama Peserta'),
                  _buildHeaderCell('Aksi'),
                ],
              ),
              ...docs.asMap().entries.map((entry) {
                int index = entry.key;
                String pesertaId = entry.value.id;
                var data = entry.value.data() as Map<String, dynamic>? ?? {};

                return TableRow(
                  decoration: const BoxDecoration(color: AppColors.white),
                  children: [
                    _buildBodyCell('${index + 1}', centered: true),
                    _buildBodyCell(data['kartu'] ?? '-',
                        centered: true), // Menampilkan Golongan Darah/Kartu
                    _buildBodyCell(data['nama'] ?? '-'),
                    _buildActionCell(pesertaId),
                  ],
                );
              }).toList(),
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
