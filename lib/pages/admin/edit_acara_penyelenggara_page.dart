import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';

class EditAcaraPenyelenggaraPage extends StatefulWidget {
  final Map<String, dynamic> eventData; // Menerima data lama
  final String eventId; // Menerima ID dokumen

  const EditAcaraPenyelenggaraPage({
    super.key,
    required this.eventData,
    required this.eventId,
  });

  @override
  State<EditAcaraPenyelenggaraPage> createState() =>
      _EditAcaraPenyelenggaraPageState();
}

class _EditAcaraPenyelenggaraPageState
    extends State<EditAcaraPenyelenggaraPage> {
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _tempatController;

  late DateTime selectedDate;
  late TimeOfDay selectedTime;

  bool _isLoading = false; // Indikator loading saat menyimpan

  @override
  void initState() {
    super.initState();
    // Mengisi kolom dengan data asli dari Firestore, bukan teks statis lagi
    _namaController = TextEditingController(text: widget.eventData['judul']);
    _deskripsiController = TextEditingController(text: widget.eventData['deskripsi']);
    _tempatController = TextEditingController(text: widget.eventData['tempat']);

    // Mengurai tanggal
    String tgl = widget.eventData['tanggalPelaksanaan'] ?? '';
    if (tgl.isNotEmpty && tgl.contains('-')) {
      var parts = tgl.split('-');
      selectedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } else {
      selectedDate = DateTime.now();
    }

    // Mengurai jam
    String jam = widget.eventData['jamPelaksanaan'] ?? '';
    if (jam.isNotEmpty && jam.contains(':')) {
      var parts = jam.split(':');
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      selectedTime = TimeOfDay.now();
    }
  }

  // Fungsi backend untuk update data ke Firebase
  Future<void> _updateAcara() async {
    String nama = _namaController.text.trim();
    String deskripsi = _deskripsiController.text.trim();
    String tempat = _tempatController.text.trim();

    if (nama.isEmpty || deskripsi.isEmpty || tempat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom harus diisi!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('acara').doc(widget.eventId).update({
        'judul': nama,
        'deskripsi': deskripsi,
        'tanggalPelaksanaan': _formatDate(selectedDate),
        'jamPelaksanaan': _formatTime(selectedTime),
        'tempat': tempat,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perubahan acara berhasil disimpan'),
            duration: Duration(milliseconds: 700),
          ),
        );

        // Kembali ke daftar acara (mundur 2 layar)
        Future.delayed(const Duration(milliseconds: 750), () {
          if (!mounted) return;
          Navigator.of(context)
            ..pop()
            ..pop();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _tempatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Container(
              width: 360,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildLabel('Nama Acara'),
                  const SizedBox(height: 6),
                  _buildNamaField(),
                  const SizedBox(height: 12),
                  _buildLabel('Deskripsi'),
                  const SizedBox(height: 6),
                  _buildDeskripsiField(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Tanggal Pelaksanaan'),
                            const SizedBox(height: 6),
                            _buildDateField(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Jam Pelaksanaan'),
                            const SizedBox(height: 6),
                            _buildTimeField(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLabel('Tempat Pelaksanaan'),
                  const SizedBox(height: 6),
                  _buildTempatField(),
                  const SizedBox(height: 18),
                  _buildPhotoPreviewArea(context),
                  const SizedBox(height: 76),
                  _buildSaveButton(context),
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
        const SizedBox(width: 26),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildNamaField() {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _namaController,
        maxLines: 2,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textDark,
          height: 1.2,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.fieldBorder,
              width: 0.9,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeskripsiField() {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: _deskripsiController,
        maxLines: null,
        expands: true,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.textDark,
          height: 1.25,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.fieldBorder,
              width: 0.9,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.fieldBorder,
            width: 0.9,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(selectedDate),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(BuildContext context) {
    return InkWell(
      onTap: () => _pickTime(context),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.fieldBorder,
            width: 0.9,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatTime(selectedTime),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            const Icon(
              Icons.access_time_filled_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempatField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _tempatController,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: AppColors.fieldBorder,
              width: 0.9,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreviewArea(BuildContext context) {
    return InkWell(
      onTap: () => _showPhotoAction(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.fieldBorder,
            width: 1,
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.photo_outlined,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 10,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateAcara, // Arahkan ke fungsi backend
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Text(
                'Simpan',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _showPhotoAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ubah Foto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Pilih dari galeri'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ubah foto belum tersedia'),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Ambil dari kamera'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ubah foto belum tersedia'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}