import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_utils.dart'; // Sesuaikan path-nya

class PusatNotifikasiPage extends StatelessWidget {
  const PusatNotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pusat Notifikasi',
          style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('notifikasi')
                  .orderBy('waktu', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildKosong();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final judul = data['judul'] ?? 'Notifikasi';
                    final pesan = data['pesan'] ?? '';
                    final isRead = data['dibaca'] ?? false;
                    final waktu = data['waktu'] as Timestamp?;

                    String waktuTeks = '';
                    if (waktu != null) {
                      waktuTeks = formatWibDateTime(waktu.toDate());
                    }

                    return _buildCardNotif(
                      judul,
                      pesan,
                      waktuTeks,
                      isRead,
                      onTap: () => _markAsRead(docs[index].reference, isRead),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _markAsRead(DocumentReference reference, bool isRead) async {
    if (isRead) return;
    await reference.update({'dibaca': true});
  }

  Widget _buildKosong() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: AppColors.textGrey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi baru',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCardNotif(
    String judul,
    String pesan,
    String waktu,
    bool isRead, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? AppColors.white
              : AppColors.lightPink.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pesan,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    waktu,
                    style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
