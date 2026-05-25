import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';

class DetailAcaraPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const DetailAcaraPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<DetailAcaraPage> createState() => _DetailAcaraPageState();
}

class _DetailAcaraPageState extends State<DetailAcaraPage> {
  bool _isLoading = false;

  Future<void> _setPengingat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final fcmToken = userDoc.data()?['fcmToken'] ?? '';

      final subKoleksiPengingat = FirebaseFirestore.instance
          .collection('acara')
          .doc(widget.eventId)
          .collection('pengingat');

      final cekAlarm = await subKoleksiPengingat.doc(currentUser.uid).get();

      if (cekAlarm.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Anda sudah memasang pengingat untuk acara ini!')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await subKoleksiPengingat.doc(currentUser.uid).set({
        'userId': currentUser.uid,
        'nama': currentUser.displayName ?? 'Pendonor',
        'fcmToken': fcmToken,
        'waktuSet': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Pengingat berhasil dipasang! Kami akan memberi tahu Anda saat acara mendekat 🔔')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memasang pengingat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekstrak data untuk kemudahan pemanggilan di UI
    final data = widget.eventData;
    final String title =
        data['namaAcara'] ?? data['judul'] ?? 'Acara Tanpa Judul';
    final String description =
        data['deskripsi'] ?? 'Deskripsi acara belum tersedia.';
    final String date = data['tanggalPelaksanaan'] ?? data['tanggal'] ?? '-';
    final String location = data['tempat'] ?? '-';
    final String contact = data['kontak'] ?? data['noHp'] ?? 'Penyelenggara';
    final String imageUrl = data['gambarUrl'] ?? data['image_url'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 14),
                _buildBanner(imageUrl),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 9.8,
                    height: 1.32,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Syarat & Ketentuan Donor',
                  style: TextStyle(
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const _BulletItem(text: 'Usia 17–60 tahun'),
                const _BulletItem(text: 'Berat badan minimal 45 kg'),
                const _BulletItem(text: 'Tekanan darah normal'),
                const _BulletItem(
                    text:
                        'Tidak sedang demam, flu, atau mengonsumsi obat tertentu'),
                const _BulletItem(
                    text: 'Sudah donor terakhir minimal 3 bulan lalu'),
                const SizedBox(height: 14),
                _buildInfoSection(
                    date: date, location: location, contact: contact),
                const SizedBox(height: 18),
                _buildBottomActions(context),
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
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.textDark),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Detail Acara',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark),
            ),
          ),
        ),
        const SizedBox(width: 26),
      ],
    );
  }

  // Menampilkan gambar acara secara dinamis
  Widget _buildBanner(String imageUrl) {
    return Container(
      height: 178,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderIcon(),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.broken_image_outlined,
            size: 28, color: AppColors.white),
      ),
    );
  }

  Widget _buildInfoSection(
      {required String date,
      required String location,
      required String contact}) {
    return Column(
      children: [
        _InfoRow(label: 'Tanggal Dan Waktu', value: date),
        const SizedBox(height: 8),
        _InfoRow(label: 'Tempat Pelaksana', value: location),
        const SizedBox(height: 8),
        _InfoRow(label: 'Kontak Penyelenggara', value: contact),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            // 👇 UI TOMBOL BARU: "Ingatkan Saya" 👇
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _setPengingat,
              icon: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.white, size: 17),
              label: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Ingatkan Saya',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Fitur bagikan akan datang nanti.')),
              );
            },
            icon: const Icon(Icons.share_outlined,
                size: 18, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;

  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 6),
            child: Icon(Icons.circle, size: 4, color: AppColors.textGrey),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 9.8,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 102,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 9.6,
                height: 1.28,
                color: AppColors.textDark,
                fontWeight: FontWeight.w400),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(':',
              style: TextStyle(fontSize: 9.6, color: AppColors.textDark)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 9.6,
                height: 1.28,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
