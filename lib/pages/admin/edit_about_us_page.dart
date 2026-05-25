import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/about_us_defaults.dart';
import '../../core/theme/app_colors.dart';

class EditAboutUsPage extends StatefulWidget {
  const EditAboutUsPage({super.key});

  @override
  State<EditAboutUsPage> createState() => _EditAboutUsPageState();
}

class _EditAboutUsPageState extends State<EditAboutUsPage> {
  final _descriptionController =
      TextEditingController(text: AboutUsDefaults.description);
  final _contactController =
      TextEditingController(text: AboutUsDefaults.contact);
  final _addressController =
      TextEditingController(text: AboutUsDefaults.address);
  final _emailController = TextEditingController(text: AboutUsDefaults.email);

  bool _isLoading = true;
  bool _isSaving = false;

  DocumentReference<Map<String, dynamic>> get _aboutRef =>
      FirebaseFirestore.instance.collection('app_settings').doc('about_us');

  @override
  void initState() {
    super.initState();
    _loadAboutUs();
  }

  Future<void> _loadAboutUs() async {
    try {
      final doc = await _aboutRef.get();
      final data = doc.data();
      if (data != null) {
        _descriptionController.text =
            data['description'] ?? AboutUsDefaults.description;
        _contactController.text = data['contact'] ?? AboutUsDefaults.contact;
        _addressController.text = data['address'] ?? AboutUsDefaults.address;
        _emailController.text = data['email'] ?? AboutUsDefaults.email;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat About Us: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAboutUs() async {
    final description = _descriptionController.text.trim();
    final contact = _contactController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();

    if (description.isEmpty || contact.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Deskripsi, kontak, dan alamat wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _aboutRef.set({
        'description': description,
        'contact': contact,
        'address': address,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Info About Us berhasil diperbarui.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan About Us: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _emailController.dispose();
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 18),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Deskripsi Tentang Aplikasi'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _descriptionController,
                                minLines: 5,
                                maxLines: 8,
                              ),
                              const SizedBox(height: 12),
                              _buildLabel('Kontak PMI'),
                              const SizedBox(height: 6),
                              _buildTextField(controller: _contactController),
                              const SizedBox(height: 12),
                              _buildLabel('Alamat PMI'),
                              const SizedBox(height: 6),
                              _buildTextField(controller: _addressController),
                              const SizedBox(height: 12),
                              _buildLabel('Email PMI'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSaveButton(),
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
              'Edit About Us',
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
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      cursorColor: AppColors.primary,
      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAboutUs,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
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
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
