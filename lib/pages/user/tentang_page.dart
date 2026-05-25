import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Halaman tentang aplikasi.
class TentangPage extends StatelessWidget {
  const TentangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildContent(),
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
              'Tentang',
              style: TextStyle(
                fontSize: 12.5,
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

  Widget _buildContent() {
    return const Text(
      'Reliable Emergency Donor adalah aplikasi donor darah di Nias yang dirancang untuk memudahkan masyarakat dalam berpartisipasi pada kegiatan kemanusiaan. Melalui aplikasi ini, pendonor dapat memantau jadwal event donor darah, mendaftar dengan mudah, dan ikut membantu menyelamatkan nyawa di sekitar Nias.',
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 12.5,
        height: 1.55,
        color: AppColors.textGrey,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}