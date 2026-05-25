import 'package:flutter/material.dart';
import '../../core/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import 'edit_acara_penyelenggara_page.dart';

class DetailAcaraPenyelenggaraPage extends StatefulWidget {
  final bool canEdit;
  final Map<String, dynamic> eventData;
  final String eventId;

  const DetailAcaraPenyelenggaraPage({
    super.key,
    this.canEdit = true,
    required this.eventData,
    required this.eventId,
  });

  @override
  State<DetailAcaraPenyelenggaraPage> createState() =>
      _DetailAcaraPenyelenggaraPageState();
}

class _DetailAcaraPenyelenggaraPageState
    extends State<DetailAcaraPenyelenggaraPage> {
  bool _isLoading = false;

  // 👇 FUNGSI SAPU JAGAT: MENGUMPULKAN TOKEN & MENGIRIM PENGINGAT 👇
  // 👇 TIMPA SELURUH FUNGSI INI DARI AWAL SAMPAI AKHIR 👇
  Future<void> _kirimPengingat() async {
    setState(() => _isLoading = true);

    try {
      // 1. Buka folder 'pengingat' khusus untuk acara ini
      final pengingatSnapshot = await FirebaseFirestore.instance
          .collection('acara')
          .doc(widget.eventId)
          .collection('pengingat')
          .get();

      // 2. Cek apakah ada orang yang menekan tombol "Ingatkan Saya"
      if (pengingatSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Belum ada pendonor yang meminta pengingat untuk acara ini.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 3. KUMPULKAN TOKEN DI SINI (Ini yang membuat daftarToken tidak merah)
      List<String> daftarToken = [];
      for (var doc in pengingatSnapshot.docs) {
        final data = doc.data();
        final token = data['fcmToken'];
        if (token != null && token.toString().isNotEmpty) {
          daftarToken.add(token.toString());
        }
      }

      if (daftarToken.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Data pengingat ditemukan, tapi tidak ada Token HP yang valid.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 4. DI SINI TEMPAT API FCM BEKERJA (Mesin Roket)
      // Kita "tembak" notifikasinya satu per satu ke semua Token yang terkumpul
      for (String token in daftarToken) {
        await FCMService.sendPushNotification(
          token,
          'Pengingat Donor Darah PMI 🩸',
          'Halo pahlawan! Mengingatkan jadwal donor darahmu di ${widget.eventData['tempat']} besok. Jangan sampai lupa ya!',
        );
      }

      // 5. Catat di database bahwa pengingat sudah pernah dikirim
      await FirebaseFirestore.instance
          .collection('acara')
          .doc(widget.eventId)
          .update({
        'pengingatTerakhirDikirim': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Berhasil mengirim notifikasi ke ${daftarToken.length} HP pendonor! 🔔🚀'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Terjadi kesalahan saat mengirim pengingat: $e')),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 14),
                _buildBannerPlaceholder(),
                const SizedBox(height: 14),
                _buildTitle(),
                const SizedBox(height: 10),
                _buildDescription(),
                const SizedBox(height: 16),
                _buildRequirementsSection(),
                const SizedBox(height: 18),
                _buildInfoRow(
                  label: 'Tanggal Dan Waktu',
                  value:
                      '${widget.eventData['tanggalPelaksanaan'] ?? '-'}, ${widget.eventData['jamPelaksanaan'] ?? '-'} WIB',
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  label: 'Tempat Pelaksana',
                  value: widget.eventData['tempat'] ?? '-',
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  label: 'Kontak\nPenyelenggara',
                  value: '+62 823-2326-0023',
                ),
                const SizedBox(height: 28),

                // 👇 TOMBOL PEMICU NOTIFIKASI 👇
                _buildTriggerButton(),
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
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.textDark,
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Detail Acara',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        if (widget.canEdit)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditAcaraPenyelenggaraPage(
                    eventData: widget.eventData,
                    eventId: widget.eventId,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          )
        else
          const SizedBox(width: 26),
      ],
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      width: double.infinity,
      height: 156,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.fieldFillSoft,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          size: 42,
          color: AppColors.lightPink,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.eventData['judul'] ?? 'Tanpa Judul',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.2,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.eventData['deskripsi'] ?? 'Tidak ada deskripsi',
      style: const TextStyle(
        fontSize: 12,
        height: 1.35,
        color: AppColors.textGrey,
      ),
    );
  }

  Widget _buildRequirementsSection() {
    const items = [
      'Usia 17–60 tahun',
      'Berat badan minimal 45 kg',
      'Tekanan darah normal',
      'Tidak sedang demam, flu, atau mengonsumsi obat tertentu',
      'Sudah donor terakhir minimal 3 bulan lalu',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Syarat & Ketentuan Donor',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDark,
              height: 1.35,
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDark,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _kirimPengingat,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.white, strokeWidth: 2))
            : const Icon(Icons.send_to_mobile_rounded, color: AppColors.white),
        label: Text(
          _isLoading ? 'Mengumpulkan Token...' : 'Kirim Panggilan Pengingat',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
