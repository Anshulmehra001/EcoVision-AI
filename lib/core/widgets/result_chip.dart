import 'package:flutter/material.dart';
import '../../core/models/classification_result.dart';

class ResultChip extends StatelessWidget {
  final ClassificationResult result;
  const ResultChip({super.key, required this.result});

  Color _confidenceColor(double c) {
    if (c >= 0.8) return Colors.green.shade600;
    if (c >= 0.6) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  IconData _confidenceIcon(double c) {
    if (c >= 0.8) return Icons.check_circle;
    if (c >= 0.6) return Icons.warning;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0,3)),
        ],
        border: Border.all(color: _confidenceColor(result.confidence).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _confidenceColor(result.confidence),
            child: Text('${(result.confidence * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height:4),
                LinearProgressIndicator(
                  value: result.confidence.clamp(0.0,1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_confidenceColor(result.confidence)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(_confidenceIcon(result.confidence), color: _confidenceColor(result.confidence)),
        ],
      ),
    );
  }
}
