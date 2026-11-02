import 'dart:io';

import 'package:articulation/core/error/failures.dart';
import 'package:articulation/core/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/speech_recorder.dart';

/// Thu âm WAV PCM 16-bit mono 16 kHz, đúng định dạng dịch vụ AI cần.
class WavSpeechRecorder implements SpeechRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw const PermissionFailure(
        message: 'Hãy cấp quyền micro để luyện phát âm.',
      );
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(directory.path, 'recordings'));
      await folder.create(recursive: true);
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: AppConstants.recordingSampleRate,
          numChannels: 1,
        ),
        path: p.join(folder.path, '${const Uuid().v4()}.wav'),
      );
    } on Exception catch (error) {
      throw AudioFailure(message: 'Không bắt đầu ghi âm được: $error');
    }
  }

  @override
  Future<String> stop() async {
    final path = await _recorder.stop();
    if (path == null) {
      throw const AudioFailure(message: 'Không lưu được đoạn ghi âm.');
    }
    return path;
  }

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> discard(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
