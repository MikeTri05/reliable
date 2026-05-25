import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class RiwayatDonorPage extends StatelessWidget {
  const RiwayatDonorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                _buildSectionIntro(),
                const SizedBox(height: 12),
                
                // 👇 STREAMBUILDER DENGAN JURUS COLLECTION GROUP 👇
                StreamBuilder<QuerySnapshot>(
                  // collectionGroup mencari tabel bernama 'peserta' di seluruh cabang database
                  stream: FirebaseFirestore.instance
                      .collectionGroup('peserta')
                      .where('userId', isEqualTo: user?.uid)
                      .where('status', isEqualTo: 'Selesai') // Hanya tampil jika Admin sudah set 'Selesai'
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('Error Riwayat: ${snapshot.error}');
                      return Center(child: Text('Terjadi kesalahan data.\n(Cek Console)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textGrey)));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    
                    return Column(
                      children: [
                        _buildSummaryCard(docs.length), // Angka ini akan otomatis bertambah!
                        const SizedBox(height: 20),
                        
                        if (docs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Belum ada riwayat donor yang selesai.',
                                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              
                              // Data ditarik dari dokumen peserta
                              return _buildHistoryCard(
                                title: data['namaAcara'] ?? 'Donor Darah PMI',
                                location: data['tempat'] ?? 'Lokasi PMI',
                                date: data['tanggalPelaksanaan'] ?? '-',
                                amount: '${data['jumlahKantong'] ?? 1} Kantong',
                              );
                            },
                          ),
                      ],
                    );
                  },
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
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Riwayat Donor',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textDark),
            ),
          ),
        ),
        const SizedBox(width: 26),
      ],
    );
  }

  Widget _buildSectionIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan donor darah yang pernah kamu\nlakukan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.2),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(19)),
            child: const Icon(Icons.water_drop_rounded, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Donormu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              Text('$count kali', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String location,
    required String date,
    required String amount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.successGreen, borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'Berhasil',
                  style: TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textGrey),
              const SizedBox(width: 5),
              Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.bloodtype_outlined, size: 15, color: AppColors.textGrey),
              const SizedBox(width: 5),
              Text(amount, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}