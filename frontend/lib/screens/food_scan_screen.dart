import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  File? _selectedImage;
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}.',
              style: AppTextStyles.body,
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _loading = true);

    final result = await ApiService.analyzeFood(_selectedImage!);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ResultScreen(
            nutritionData: result['data'] as Map<String, dynamic>,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] as String? ?? 'Something went wrong.',
            style: AppTextStyles.body,
          ),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x2),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.x4),
                Text('Scan Food', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.x4),
                // Image preview container
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.borderRadius,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Text(
                                  'No food selected',
                                  style: TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontWeight: FontWeight.w400,
                                    fontSize: AppFontSizes.sm,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                // Camera & Gallery buttons
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryButton(
                        label: 'CAMERA',
                        icon: LucideIcons.camera,
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: _SecondaryButton(
                        label: 'GALLERY',
                        icon: LucideIcons.image,
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                // Analyze button — only when image selected
                if (_selectedImage != null) ...[
                  const SizedBox(height: AppSpacing.x2),
                  AnimatedOpacity(
                    opacity: _selectedImage != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _analyzeImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          disabledBackgroundColor:
                              AppColors.accent.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderRadius,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'ANALYZE',
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x2),
              ],
            ),
          ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.surface,
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadius,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.x1),
            Text(label, style: AppTextStyles.buttonText.copyWith(
              color: AppColors.accent,
            )),
          ],
        ),
      ),
    );
  }
}
