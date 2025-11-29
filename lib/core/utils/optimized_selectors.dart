import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/biodiversity_ear/provider.dart';
import '../../features/aqua_lens/provider.dart';

/// Optimized selectors for Biodiversity Ear state

final biodiversityEarIsInitializedProvider = Provider<bool>((ref) {
  return ref.watch(biodiversityEarProvider.select((state) => state.isInitialized));
});

final biodiversityEarIsRecordingProvider = Provider<bool>((ref) {
  return ref.watch(biodiversityEarProvider.select((state) => state.isRecording));
});

final biodiversityEarIsAnalyzingProvider = Provider<bool>((ref) {
  return ref.watch(biodiversityEarProvider.select((state) => state.isAnalyzing));
});

final biodiversityEarResultsProvider = Provider((ref) {
  return ref.watch(biodiversityEarProvider.select((state) => state.results));
});

final biodiversityEarRecordingDurationProvider = Provider<int>((ref) {
  return ref.watch(biodiversityEarProvider.select((state) => state.recordingDuration));
});

/// Optimized selectors for Aqua Lens state

final aquaLensIsInitializedProvider = Provider<bool>((ref) {
  return ref.watch(aquaLensProvider.select((state) => state.isInitialized));
});

final aquaLensIsCapturingProvider = Provider<bool>((ref) {
  return ref.watch(aquaLensProvider.select((state) => state.isCapturing));
});

final aquaLensIsAnalyzingProvider = Provider<bool>((ref) {
  return ref.watch(aquaLensProvider.select((state) => state.isAnalyzing));
});

final aquaLensColorResultsProvider = Provider((ref) {
  return ref.watch(aquaLensProvider.select((state) => state.colorResults));
});
