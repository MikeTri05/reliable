import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_utils.dart';
import '../../core/utils/local_notification_service.dart';

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
  bool _isSharing = false;
  bool _isReminderSet = false;
  bool _isCheckingReminder = true;
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadReminderStatus();
  }

  Future<void> _loadReminderStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() => _isCheckingReminder = false);
      }
      return;
    }

    try {
      final reminderDoc = await FirebaseFirestore.instance
          .collection('acara')
          .doc(widget.eventId)
          .collection('pengingat')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;
      setState(() {
        _isReminderSet = reminderDoc.exists;
        _isCheckingReminder = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCheckingReminder = false);
    }
  }

  Future<void> _setPengingat() async {
    if (_isReminderSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengingat sudah dipasang.')),
      );
      return;
    }

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
      final alreadySet = cekAlarm.exists;
      if (alreadySet) {
        if (mounted) {
          setState(() => _isReminderSet = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengingat sudah dipasang.')),
          );
        }
        return;
      }

      final eventTitle = (widget.eventData['namaAcara'] ??
              widget.eventData['judul'] ??
              'Acara Donor Darah')
          .toString();
      final eventDate = (widget.eventData['tanggalPelaksanaan'] ??
              widget.eventData['tanggal'] ??
              '')
          .toString();
      final eventTime = (widget.eventData['jamPelaksanaan'] ??
              widget.eventData['jam'] ??
              widget.eventData['waktuPelaksanaan'] ??
              '')
          .toString();
      final reminderAt = reminderDateTimeFromEventDate(
        eventDate,
        eventTime: eventTime,
      );
      if (reminderAt == null) {
        throw Exception('Tanggal acara tidak valid.');
      }
      final reminderTimestamp = Timestamp.fromDate(reminderAt);

      final notificationDocId = 'reminder_${widget.eventId}';
      final notificationKey =
          LocalNotificationService.inboxNotificationKey(notificationDocId);
      final notificationTitle = 'Pengingat Donor Darah';
      final notificationMessage =
          'Besok ada acara "$eventTitle". Jangan lupa ikut donor darah ya!';
      final notificationId =
          LocalNotificationService.stableNotificationId(notificationKey);

      await LocalNotificationService.cancelNotification(
        LocalNotificationService.stableNotificationId(notificationDocId),
      );
      await LocalNotificationService.cancelNotification(
        widget.eventId.hashCode & 0x7fffffff,
      );

      final scheduled = await LocalNotificationService.scheduleEventReminder(
        id: notificationId,
        title: notificationTitle,
        body: notificationMessage,
        eventDate: eventDate,
        eventTime: eventTime,
      );
      if (!scheduled) {
        throw Exception(
          'Pengingat gagal dijadwalkan. Pastikan izin notifikasi dan alarm tepat aktif.',
        );
      }

      await subKoleksiPengingat.doc(currentUser.uid).set({
        'userId': currentUser.uid,
        'nama': currentUser.displayName ?? 'Pendonor',
        'fcmToken': fcmToken,
        'waktuSet': FieldValue.serverTimestamp(),
        'eventId': widget.eventId,
        'eventTitle': eventTitle,
        'eventDate': eventDate,
        'eventTime': eventTime,
        'reminderAtWib': reminderTimestamp,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifikasi')
          .doc(notificationDocId)
          .set({
        'judul': notificationTitle,
        'pesan': notificationMessage,
        'waktu': reminderTimestamp,
        'waktuTerjadwal': reminderTimestamp,
        'createdAt': FieldValue.serverTimestamp(),
        'eventId': widget.eventId,
        'tipe': 'pengingat_acara',
        'dibaca': false,
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() => _isReminderSet = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pengingat berhasil dipasang! Kami akan memberi tahu Anda saat acara mendekat.',
            ),
          ),
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

  Future<void> _shareEventImage() async {
    setState(() => _isSharing = true);
    try {
      // Beri jeda agar overlay loading tidak ikut tercapture.
      await Future.delayed(const Duration(milliseconds: 50));
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Konten belum siap dibagikan.');
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal memproses gambar.');
      }
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/acara_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      final title = (widget.eventData['namaAcara'] ??
              widget.eventData['judul'] ??
              'Acara Donor Darah')
          .toString();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Yuk ikut donor darah: $title',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
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
    final String imageUrl =
        (data['imageUrl'] ?? data['gambarUrl'] ?? data['image_url'] ?? '')
            .toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: RepaintBoundary(
            key: _shareKey,
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
                  const _BulletItem(
                      text:
                          'Usia 17ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ60 tahun'),
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
    final canTapReminder = canRequestEventReminder(
      isLoading: _isLoading,
      isCheckingReminder: _isCheckingReminder,
      isReminderSet: _isReminderSet,
    );
    final reminderText = reminderButtonText(
      isLoading: _isLoading,
      isCheckingReminder: _isCheckingReminder,
      isReminderSet: _isReminderSet,
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: canTapReminder ? _setPengingat : null,
              icon: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.white, size: 17),
              label: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2),
                    )
                  : Text(
                      reminderText,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
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
            onPressed: _isSharing ? null : _shareEventImage,
            icon: _isSharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.share_outlined,
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
