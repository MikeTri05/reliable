import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_utils.dart';
import '../../core/utils/profile_utils.dart';

class ManajemenKantongDarahPage extends StatelessWidget {
  const ManajemenKantongDarahPage({super.key});

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
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('peserta')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Gagal memuat data: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        );
                      }

                      final summary = _BagSummary.fromDocs(
                        snapshot.data?.docs ?? [],
                      );

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildTotalCard(summary.totalBags),
                          const SizedBox(height: 18),
                          _buildSectionTitle('Stok Per Golongan Darah'),
                          const SizedBox(height: 10),
                          _buildBloodTypeGrid(summary.bagsByBloodType),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Kantong Per Acara'),
                          const SizedBox(height: 10),
                          if (summary.bagsByEvent.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Belum ada kantong darah yang tercatat.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...summary.bagsByEvent.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildEventBagRow(
                                  eventName: entry.key,
                                  bagCount: entry.value,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Ubah Kantong Donor'),
                          const SizedBox(height: 10),
                          if (summary.records.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Belum ada data donor yang bisa diubah.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...summary.records.map(
                              (record) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildEditableBagRow(
                                  context,
                                  record: record,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
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
              'Manajemen Kantong Darah',
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

  Widget _buildTotalCard(int totalBags) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bloodtype_rounded,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Kantong Darah',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatBagCount(totalBags),
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeGrid(Map<String, int> bagsByBloodType) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bloodTypeOptions.map((type) {
        return Container(
          width: 76,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatBagCount(bagsByBloodType[type] ?? 0),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEventBagRow({
    required String eventName,
    required int bagCount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              eventName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatBagCount(bagCount),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableBagRow(
    BuildContext context, {
    required _DonationBagRecord record,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.donorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.eventName} • ${record.bloodType}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatBagCount(record.bagCount),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            tooltip: 'Ubah kantong',
            onPressed: () => _showEditBagDialog(context, record),
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditBagDialog(
    BuildContext context,
    _DonationBagRecord record,
  ) async {
    final controller = TextEditingController(text: record.bagCount.toString());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Ubah Kantong Darah'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.donorName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.eventName,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Jumlah Kantong',
                  hintText: 'Contoh: 1',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = int.tryParse(controller.text.trim()) ?? 0;
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(context);

                if (value < 1) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Jumlah kantong minimal 1.'),
                    ),
                  );
                  return;
                }

                try {
                  await record.reference.update({
                    'jumlahKantong': value.toString(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Jumlah kantong berhasil diperbarui.'),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal mengubah kantong: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }
}

class _BagSummary {
  final int totalBags;
  final Map<String, int> bagsByBloodType;
  final Map<String, int> bagsByEvent;
  final List<_DonationBagRecord> records;

  const _BagSummary({
    required this.totalBags,
    required this.bagsByBloodType,
    required this.bagsByEvent,
    required this.records,
  });

  factory _BagSummary.fromDocs(List<QueryDocumentSnapshot> docs) {
    final bloodTypeTotals = <String, int>{
      for (final type in bloodTypeOptions) type: 0,
    };
    final eventTotals = <String, int>{};
    final records = <_DonationBagRecord>[];
    var total = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if ((data['status'] ?? '').toString() != 'Selesai') continue;

      final bagCount = parseBagCount(data['jumlahKantong']);
      final rawBloodType =
          (data['golonganDarah'] ?? '').toString().toUpperCase();
      final bloodType =
          bloodTypeOptions.contains(rawBloodType) ? rawBloodType : null;
      final eventName = (data['namaAcara'] ?? 'Tanpa Nama Acara').toString();
      final donorName = (data['nama'] ?? 'Tanpa Nama').toString();

      total += bagCount;
      if (bloodType != null) {
        bloodTypeTotals[bloodType] =
            (bloodTypeTotals[bloodType] ?? 0) + bagCount;
      }
      eventTotals[eventName] = (eventTotals[eventName] ?? 0) + bagCount;
      records.add(
        _DonationBagRecord(
          reference: doc.reference,
          donorName: donorName,
          eventName: eventName,
          bloodType: bloodType ?? '-',
          bagCount: bagCount,
        ),
      );
    }

    records.sort((a, b) => a.eventName.compareTo(b.eventName));

    return _BagSummary(
      totalBags: total,
      bagsByBloodType: bloodTypeTotals,
      bagsByEvent: eventTotals,
      records: records,
    );
  }
}

class _DonationBagRecord {
  final DocumentReference reference;
  final String donorName;
  final String eventName;
  final String bloodType;
  final int bagCount;

  const _DonationBagRecord({
    required this.reference,
    required this.donorName,
    required this.eventName,
    required this.bloodType,
    required this.bagCount,
  });
}
