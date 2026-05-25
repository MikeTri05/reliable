import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import 'detail_peserta_donor_page.dart';

class MasukanDataDonorPage extends StatefulWidget {
  const MasukanDataDonorPage({super.key});

  @override
  State<MasukanDataDonorPage> createState() => _MasukanDataDonorPageState();
}

class _MasukanDataDonorPageState extends State<MasukanDataDonorPage> {
  String selectedName = '';
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
                const SizedBox(height: 20),
                _buildSearchField(),
                const SizedBox(height: 14),
                Expanded(
                  child: _buildUserList(context),
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

  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
        cursorColor: AppColors.primary,
        style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'Cari pengguna (Ketik nama)',
          hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _buildUserList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'pendonor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error Firebase: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Belum ada akun pendonor yang terdaftar.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          );
        }

        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String nama = (data['namaLengkap'] ?? '').toLowerCase();
          return nama.contains(searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text('Pengguna tidak ditemukan di pencarian.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String name = data['namaLengkap'] ?? 'Tanpa Nama';
            String rawUid =
                doc.id.replaceAll(RegExp(r'[^0-9]'), '').padRight(16, '0');
            String generatedCardNumber =
                '${rawUid.substring(0, 4)} ${rawUid.substring(4, 8)} ${rawUid.substring(8, 12)} ${rawUid.substring(12, 16)}';
            String nomorKartuFinal =
                data['nomorKartu'] ?? data['kartu'] ?? generatedCardNumber;

            // 👇 PERBAIKAN: MEMBAWA UID DAN EMAIL 👇
            Map<String, String> userMap = {
              'userId': doc.id, // SANGAT PENTING!
              'email': (data['email'] ?? '').toString(),
              'nama': name.toString(),
              'kartu': nomorKartuFinal,
              'goldar': (data['golonganDarah'] ?? '-').toString(),
            };

            final isSelected = selectedName == name;

            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == docs.length - 1 ? 0 : 8),
              child: InkWell(
                onTap: () async {
                  setState(() => selectedName = name);
                  final result = await Navigator.push(
                    this.context,
                    MaterialPageRoute(
                        builder: (_) =>
                            DetailPesertaDonorPage(userData: userMap)),
                  );
                  if (!mounted) return;
                  if (result != null) Navigator.pop(this.context, result);
                },
                borderRadius: BorderRadius.circular(6),
                splashColor: AppColors.primary.withOpacity(0.06),
                highlightColor: AppColors.primary.withOpacity(0.03),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary : AppColors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.offWhite,
                        width: 1),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
