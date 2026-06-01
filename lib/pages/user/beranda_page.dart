import 'dart:async'; // 👇 IMPORT BARU UNTUK TIMER OTOMATIS
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/constants/app_assets.dart';
import '../../core/session/admin_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_utils.dart';
import 'acara_page.dart';
import 'detail_acara_page.dart';
import 'kartu_page.dart';
import 'login_page.dart';
import 'pengguna_page.dart';
import 'pusat_notifikasi.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  int _bannerCount = 0;
  late final Stream<QuerySnapshot> _acaraStream;

  @override
  void initState() {
    super.initState();
    _acaraStream = FirebaseFirestore.instance
        .collection('acara')
        .orderBy('tanggalDibuat', descending: true)
        .snapshots();
    _setupPushNotifications();
    _startAutoSlide(); // Jalankan mesin penggeser otomatis
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // Matikan timer kalau halaman ditutup biar gak bocor memori
    _pageController.dispose();
    super.dispose();
  }

  // 👇 FUNGSI PENGGESER BANNER OTOMATIS (4 DETIK) 👇
  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _bannerCount > 1) {
        _currentPage++;
        if (_currentPage >= _bannerCount) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  // FUNGSI INTI UNTUK MENGAKTIFKAN PUSH NOTIFICATION
  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'fcmToken': fcmToken});

          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'fcmToken': newToken});
          });
        }
      }
    } catch (e) {
      print('Gagal mengatur Push Notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _acaraStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text('Belum ada acara.',
                    style: TextStyle(color: AppColors.textGrey)),
              );
            }

            // 👇 KITA AMBIL 3 ACARA TERBARU UNTUK JADI BANNER 👇
            final bannerDocs = docs.take(3).toList();
            _bannerCount =
                bannerDocs.length; // Update jumlah banner untuk fungsi Timer

            // Sisanya dimasukkan ke list "Acara Lainnya"
            final historyDocs = docs.length > 3 ? docs.sublist(3) : [];

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // 👇 WADAH UTAMA HEADER & BANNER SLIDER 👇
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        // --- HEADER (LOGO & IKON NOTIF) ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(AppAssets.logo,
                                      width: 34,
                                      height: 34,
                                      fit: BoxFit.contain),
                                  const SizedBox(width: 6),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Reliable Emergency',
                                          style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.lightPink,
                                              height: 1.1)),
                                      SizedBox(height: 1),
                                      Text('Donor',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                              height: 1.0)),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const PusatNotifikasiPage())),
                                    borderRadius: BorderRadius.circular(20),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                          Icons.notifications_active_outlined,
                                          size: 20,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _showExitDialog(context),
                                    borderRadius: BorderRadius.circular(20),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.logout_rounded,
                                          size: 18, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // --- BANNER SLIDER OTOMATIS ---
                        SizedBox(
                         height: 165,
                         child: PageView.builder(
                           controller: _pageController,
                           onPageChanged: (index) {
                             setState(() => _currentPage = index);
                           },
                            itemCount: bannerDocs.length,
                            itemBuilder: (context, index) {
                              final data = bannerDocs[index].data()
                                  as Map<String, dynamic>;
                              final id = bannerDocs[index].id;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: _BannerSlide(
                                  eventData: data,
                                  onTap: () => _openDetail(context, id, data),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- INDIKATOR TITIK (DOTS) ---
                        if (_bannerCount > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_bannerCount, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                height: 6,
                                width: _currentPage == index ? 16 : 6,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? AppColors.primary
                                      : AppColors.textGrey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 👇 DAFTAR ACARA LAINNYA 👇
                  if (historyDocs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Acara Lainnya',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                          ),
                          InkWell(
                            onTap: () => _onBottomTap(context, 1),
                            child: const Text('Lihat Semua',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...historyDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;
                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 8, right: 8, bottom: 14),
                        child: _HistoryCard(
                          eventData: data,
                          onTap: () => _openDetail(context, docId, data),
                        ),
                      );
                    }),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDetail(
      BuildContext context, String eventId, Map<String, dynamic> eventData) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                DetailAcaraPage(eventId: eventId, eventData: eventData)));
  }

  void _onBottomTap(BuildContext context, int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AcaraPage()));
      return;
    }
    if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const KartuPage()));
      return;
    }
    if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PenggunaPage()));
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Keluar',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
          content: const Text('Apakah ingin keluar?',
              style: TextStyle(color: AppColors.textDark)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tidak',
                    style: TextStyle(color: AppColors.textDark))),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                await AdminSession.clear();
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }
}

// 👇 WIDGET KARTU UNTUK BANNER 👇
class _BannerSlide extends StatelessWidget {
  final Map<String, dynamic> eventData;
  final VoidCallback onTap;

  const _BannerSlide({required this.eventData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title =
        eventData['namaAcara'] ?? eventData['judul'] ?? 'Acara Donor Darah';
    final date = eventData['tanggalPelaksanaan'] ?? eventData['tanggal'] ?? '-';
    final imageUrl = eventData['imageUrl'] ??
        eventData['gambarUrl'] ??
        eventData['image_url'] ??
        '';
    final completed = isEventCompleted(eventData);

    return GestureDetector(
      onTap: onTap,
      child: Container(
       width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4), BlendMode.darken),
                )
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.water_drop_rounded,
                      color: AppColors.white, size: 26),
                ),
                const Spacer(),
                if (completed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(30)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: AppColors.successGreen),
                        SizedBox(width: 4),
                        Text('Selesai',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.successGreen)),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: AppColors.white)),
                      const SizedBox(height: 8),
                      const Text('Pelaksanaan',
                          style:
                              TextStyle(fontSize: 9, color: AppColors.white)),
                      const SizedBox(height: 2),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Lihat Acara',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                      const SizedBox(width: 6),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                            color: AppColors.lightPink,
                            borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 9, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> eventData;
  final VoidCallback onTap;

  const _HistoryCard({required this.eventData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = eventData['namaAcara'] ?? eventData['judul'] ?? 'Acara Donor';
    final date = eventData['tanggalPelaksanaan'] ?? eventData['tanggal'] ?? '-';
    final imageUrl = eventData['imageUrl'] ??
        eventData['gambarUrl'] ??
        eventData['image_url'] ??
        '';
    final completed = isEventCompleted(eventData);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 76,
                  height: 62,
                  color: AppColors.secondary,
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.primary))
                      : const Icon(Icons.photo_outlined,
                          color: AppColors.primary, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                      color: AppColors.textDark)),
                            ),
                            if (completed)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.successGreenSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: AppColors.successGreen,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Align(
                          alignment: Alignment.bottomRight,
                          child: Text(date,
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textGrey))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
              label: 'Beranda',
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              index: 0,
              currentIndex: currentIndex,
              onTap: onTap),
          _NavItem(
              label: 'Acara',
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              index: 1,
              currentIndex: currentIndex,
              onTap: onTap),
          _NavItem(
              label: 'Kartu',
              icon: Icons.badge_outlined,
              activeIcon: Icons.badge,
              index: 2,
              currentIndex: currentIndex,
              onTap: onTap),
          _NavItem(
              label: 'Pengguna',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person,
              index: 3,
              currentIndex: currentIndex,
              onTap: onTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem(
      {required this.label,
      required this.icon,
      required this.activeIcon,
      required this.index,
      required this.currentIndex,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isActive = currentIndex == index;
    final Color color = isActive ? AppColors.primary : AppColors.lightPink;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(10, isActive ? 2 : 6, 10, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
                scale: isActive ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 180),
                child:
                    Icon(isActive ? activeIcon : icon, size: 20, color: color)),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
