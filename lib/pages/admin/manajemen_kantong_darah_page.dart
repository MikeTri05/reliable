import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                        .collection('acara')
                        .snapshots(),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.hasError) {
                        return _buildError(eventSnapshot.error);
                      }

                      if (eventSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !eventSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final eventsById = <String, _EventMeta>{
                        for (final doc in eventSnapshot.data?.docs ?? [])
                          doc.id: _EventMeta.fromDoc(doc),
                      };

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collectionGroup('peserta')
                            .snapshots(),
                        builder: (context, pesertaSnapshot) {
                          if (pesertaSnapshot.hasError) {
                            return _buildError(pesertaSnapshot.error);
                          }

                          if (pesertaSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !pesertaSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final summary = _BagSummary.fromDocs(
                            pesertaSnapshot.data?.docs ?? [],
                            eventsById,
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
                                ...summary.bagsByEvent.map(
                                  (eventTotal) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildEventBagRow(
                                      eventName: eventTotal.eventName,
                                      eventDate: eventTotal.eventDate,
                                      bagCount: eventTotal.bagCount,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
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

  Widget _buildError(Object? error) {
    return Center(
      child: Text(
        'Gagal memuat data: $error',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textGrey,
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
    required DateTime? eventDate,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (eventDate != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    formatEventDate(eventDate),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
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
}

class _BagSummary {
  final int totalBags;
  final Map<String, int> bagsByBloodType;
  final List<_EventBagTotal> bagsByEvent;

  const _BagSummary({
    required this.totalBags,
    required this.bagsByBloodType,
    required this.bagsByEvent,
  });

  factory _BagSummary.fromDocs(
    List<QueryDocumentSnapshot> docs,
    Map<String, _EventMeta> eventsById,
  ) {
    final bloodTypeTotals = <String, int>{
      for (final type in bloodTypeOptions) type: 0,
    };
    final eventTotals = <String, _EventBagTotal>{};
    var total = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      if (status != 'selesai') continue;

      final bagCount = parseBagCount(data['jumlahKantong']);
      if (bagCount <= 0) continue;

      final rawBloodType =
          (data['golonganDarah'] ?? '').toString().trim().toUpperCase();
      final bloodType = bloodTypeOptions.contains(rawBloodType)
          ? rawBloodType
          : ['A', 'B', 'AB', 'O'].contains(rawBloodType)
              ? '$rawBloodType+'
              : null;
      final eventRef = doc.reference.parent.parent;
      if (eventRef == null || eventRef.parent.id != 'acara') continue;

      final eventId = eventRef.id;
      final eventMeta = eventsById[eventId];
      final eventName = eventMeta?.name ??
          (data['namaAcara'] ?? data['judulAcara'] ?? data['judul'])
              ?.toString()
              .trim();
      final safeEventName = eventName == null || eventName.isEmpty
          ? 'Tanpa Nama Acara'
          : eventName;
      final eventDate = eventMeta?.date ??
          parseEventDate(data['tanggalPelaksanaan']?.toString());
      final key = eventId.isNotEmpty ? eventId : safeEventName;

      total += bagCount;
      if (bloodType != null) {
        bloodTypeTotals[bloodType] =
            (bloodTypeTotals[bloodType] ?? 0) + bagCount;
      }

      final current = eventTotals[key];
      eventTotals[key] = _EventBagTotal(
        eventName: current?.eventName ?? safeEventName,
        eventDate: current?.eventDate ?? eventDate,
        bagCount: (current?.bagCount ?? 0) + bagCount,
      );
    }

    final sortedEventTotals = eventTotals.values.toList()
      ..sort((a, b) {
        final aDate = a.eventDate;
        final bDate = b.eventDate;
        if (aDate != null && bDate != null) {
          final dateCompare = bDate.compareTo(aDate);
          if (dateCompare != 0) return dateCompare;
        } else if (aDate != null) {
          return -1;
        } else if (bDate != null) {
          return 1;
        }
        return a.eventName.toLowerCase().compareTo(b.eventName.toLowerCase());
      });

    return _BagSummary(
      totalBags: total,
      bagsByBloodType: bloodTypeTotals,
      bagsByEvent: sortedEventTotals,
    );
  }
}

class _EventMeta {
  final String name;
  final DateTime? date;

  const _EventMeta({required this.name, required this.date});

  factory _EventMeta.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawName =
        (data['judul'] ?? data['namaAcara'] ?? data['nama'])?.toString().trim();
    return _EventMeta(
      name: rawName == null || rawName.isEmpty ? 'Tanpa Nama Acara' : rawName,
      date: parseEventDate(data['tanggalPelaksanaan']?.toString()),
    );
  }
}

class _EventBagTotal {
  final String eventName;
  final DateTime? eventDate;
  final int bagCount;

  const _EventBagTotal({
    required this.eventName,
    required this.eventDate,
    required this.bagCount,
  });
}
