import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'provider.dart';
import '../../core/widgets/permission_dialog.dart';

class AquaLensScreen extends ConsumerStatefulWidget {
  const AquaLensScreen({super.key});

  @override
  ConsumerState<AquaLensScreen> createState() => _AquaLensScreenState();
}

class _AquaLensScreenState extends ConsumerState<AquaLensScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aquaLensProvider.notifier).initialize();
    });
  }

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        await ref.read(aquaLensProvider.notifier).analyzeExisting(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        await ref.read(aquaLensProvider.notifier).analyzeExisting(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aquaLensProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Quality'),
        actions: [
          if (state.colorResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                ref.read(aquaLensProvider.notifier).clearResults();
              },
              tooltip: 'Clear results',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(theme),
              const SizedBox(height: 24),
              _buildActionButtons(theme, state),
              const SizedBox(height: 24),
              if (state.isAnalyzing) _buildAnalyzingCard(theme),
              if (state.colorResults.isNotEmpty) _buildResultsCard(theme, state),
              if (state.error != null) _buildErrorCard(theme, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop,
                size: 48,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Water Quality Analysis',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Capture or upload a photo of water test strips for instant analysis',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, AquaLensState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: state.isAnalyzing ? null : _captureImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.isAnalyzing ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 6),
            const SizedBox(height: 24),
            Text(
              'Analyzing Water Quality...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing image data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(ThemeData theme, AquaLensState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Analysis Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...state.colorResults.entries.map((entry) {
              final parameter = entry.key;
              final rgb = entry.value;
              final quality = _getQualityAssessment(parameter, rgb);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: quality.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: quality.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parameter.toUpperCase(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              quality.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: quality.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'RGB: ${rgb[0]}, ${rgb[1]}, ${rgb[2]}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        quality.icon,
                        color: quality.color,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Results are based on color analysis. For accurate readings, use calibrated test strips.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, AquaLensState state) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red[900],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref.read(aquaLensProvider.notifier).clearError();
              },
              color: Colors.red[700],
            ),
          ],
        ),
      ),
    );
  }

  _QualityAssessment _getQualityAssessment(String parameter, List<int> rgb) {
    // Simple quality assessment based on RGB values
    final brightness = (rgb[0] + rgb[1] + rgb[2]) / 3;
    
    switch (parameter.toLowerCase()) {
      case 'ph':
        if (brightness > 150) {
          return _QualityAssessment('Neutral (Good)', Colors.green, Icons.check_circle);
        } else if (brightness > 100) {
          return _QualityAssessment('Slightly Acidic', Colors.orange, Icons.warning);
        } else {
          return _QualityAssessment('Acidic', Colors.red, Icons.error);
        }
      case 'chlorine':
        if (brightness < 100) {
          return _QualityAssessment('Low', Colors.green, Icons.check_circle);
        } else if (brightness < 150) {
          return _QualityAssessment('Moderate', Colors.orange, Icons.warning);
        } else {
          return _QualityAssessment('High', Colors.red, Icons.error);
        }
      default:
        return _QualityAssessment('Detected', Colors.blue, Icons.info);
    }
  }
}

class _QualityAssessment {
  final String label;
  final Color color;
  final IconData icon;

  _QualityAssessment(this.label, this.color, this.icon);
}
