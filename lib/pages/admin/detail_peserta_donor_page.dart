import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DetailPesertaDonorPage extends StatefulWidget {
  final Map<String, String> userData;

  const DetailPesertaDonorPage({
    super.key,
    required this.userData,
  });

  @override
  State<DetailPesertaDonorPage> createState() => _DetailPesertaDonorPageState();
}

class _DetailPesertaDonorPageState extends State<DetailPesertaDonorPage> {
  // 👇 KONTROLER UNTUK MENGAMBIL ANGKA KANTONG DARAH 👇
  final TextEditingController _kantongController =
      TextEditingController(text: '1');

  @override
  void dispose() {
    _kantongController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.userData['nama'] ?? '';
    final kartu = widget.userData['kartu'] ?? '';
    final goldar = widget.userData['goldar'] ?? '';

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
                const SizedBox(height: 22),
                _buildNameSelector(nama),
                const SizedBox(height: 20),
                _buildProfileCard(nama: nama, kartu: kartu, goldar: goldar),
                const SizedBox(height: 24), // Spasi tambahan

                // 👇 TAMBAHAN UI UNTUK INPUT KANTONG DARAH 👇
                _buildInputKantong(),

                const Spacer(),
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
              'Masukan Data',
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

  Widget _buildNameSelector(String name) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.fieldBorder, width: 0.9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style:
                    const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.textDark),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      {required String nama, required String kartu, required String goldar}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.fieldBorder,
            child: const Icon(Icons.person, size: 42, color: AppColors.white),
          ),
          const SizedBox(height: 12),
          Text(nama,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          _buildInfoStrip(kartu: kartu, goldar: goldar),
        ],
      ),
    );
  }

  Widget _buildInfoStrip({required String kartu, required String goldar}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
              child: Text(kartu,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87))),
          Container(width: 1, height: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          const Text('Golongan Darah : ',
              style: TextStyle(fontSize: 11, color: Colors.black45)),
          Text(goldar,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  // 👇 FUNGSI MEMBANGUN UI INPUT KANTONG DARAH 👇
  Widget _buildInputKantong() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jumlah Kantong Darah',
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: TextField(
            controller: _kantongController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Masukkan angka (contoh: 1)',
              hintStyle:
                  const TextStyle(fontSize: 12, color: AppColors.textGrey),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.fieldBorder, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: () {
          final returnData = Map<String, dynamic>.from(widget.userData);
          String inputKantong = _kantongController.text.trim();
          returnData['jumlahKantong'] =
              inputKantong.isEmpty ? '1' : inputKantong;

          Navigator.pop(context, returnData);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Tambah',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
