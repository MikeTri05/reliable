import 'package:flutter/material.dart';
import '../../core/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/local_notification_service.dart';
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

  Future<void> _kirimPengingat() async {
    setState(() => _isLoading = true);

    try {
      final pengingatSnapshot = await FirebaseFirestore.instance
          .collection('acara')
          .doc(widget.eventId)
          .collection('pengingat')
          .get();

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

      final title = 'Pengingat Donor Darah';
      final message =
          'Halo pahlawan! Mengingatkan jadwal donor darahmu di ${widget.eventData['tempat'] ?? 'lokasi PMI'} besok. Jangan sampai lupa ya!';

      List<String> daftarToken = [];
      var inboxCount = 0;
      for (var doc in pengingatSnapshot.docs) {
        final data = doc.data();
        final userId = (data['userId'] ?? doc.id).toString();
        final token = data['fcmToken'];
        if (token != null && token.toString().isNotEmpty) {
          final tokenText = token.toString();
          daftarToken.add(tokenText);
          await FCMService.sendPushNotification(tokenText, title, message);
        }

        if (userId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifikasi')
              .doc('reminder_sent_${widget.eventId}')
              .set({
            'judul': title,
            'pesan': message,
            'waktu': Timestamp.now(),
            'createdAt': FieldValue.serverTimestamp(),
            'eventId': widget.eventId,
            'tipe': 'pengingat_acara_admin',
            'dibaca': false,
          }, SetOptions(merge: true));
          inboxCount++;
        }
      }

      final eventDate =
          (widget.eventData['tanggalPelaksanaan'] ?? '').toString();
      final eventTime = (widget.eventData['jamPelaksanaan'] ?? '').toString();
      await LocalNotificationService.scheduleEventReminder(
        id: widget.eventId.hashCode & 0x7fffffff,
        title: 'Pengingat Donor Darah',
        body:
            'Besok ada acara donor darah di ${widget.eventData['tempat'] ?? 'lokasi PMI'}. Jangan lupa ya!',
        eventDate: eventDate,
        eventTime: eventTime,
      );

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
                'Berhasil mengirim push ke ${daftarToken.length} HP dan menyimpan $inboxCount pesan inbox.'),
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
                _buildBanner(),
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

  Widget _buildBanner() {
    final imageUrl = (widget.eventData['imageUrl'] ??
            widget.eventData['gambarUrl'] ??
            widget.eventData['image_url'] ??
            '')
        .toString();

    return Container(
      width: double.infinity,
      height: 156,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
        gradient: imageUrl.isEmpty
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondary,
                  AppColors.fieldFillSoft,
                ],
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildBannerPlaceholderIcon(),
              )
            : _buildBannerPlaceholderIcon(),
      ),
    );
  }

  Widget _buildBannerPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.photo_outlined,
        size: 42,
        color: AppColors.lightPink,
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
