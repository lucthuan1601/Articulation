import 'dart:convert';
import 'dart:io';

import 'package:articulation/core/error/error.dart';
import 'package:articulation/features/habit_tracking/domain/entities/practice_session.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/practice_session_repository.dart';
import 'package:articulation/features/pronunciation/data/datasources/speech_api_client.dart';
import 'package:articulation/features/pronunciation/data/mappers/pronunciation_result_mapper.dart';
import 'package:articulation/features/pronunciation/data/models/pronunciation_result_entity.dart';
import 'package:articulation/features/pronunciation/data/models/speech_analysis_model.dart';
import 'package:articulation/features/pronunciation/data/repositories/speech_analysis_repository_impl.dart';
import 'package:articulation/features/pronunciation/domain/entities/lesson.dart';
import 'package:articulation/features/pronunciation/domain/entities/pronunciation_result.dart';
import 'package:articulation/features/pronunciation/domain/entities/speech_analysis.dart';
import 'package:articulation/features/pronunciation/domain/repositories/pronunciation_result_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/speech_analysis_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/speech_recorder.dart';
import 'package:articulation/features/pronunciation/domain/usecases/analyze_pronunciation.dart';
import 'package:articulation/features/pronunciation/presentation/controllers/practice_controller.dart';
import 'package:articulation/features/pronunciation/presentation/models/word_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dạng JSON do `ai_server` trả về.
Map<String, dynamic> serverJson({
  bool offTarget = false,
  bool noisy = false,
}) =>
    {
      'text': 'think so',
      'overall': 72,
      'accuracy': 60,
      'completeness': 50,
      'fluency': 88,
      'offTarget': offTarget,
      'noisy': noisy,
      'verdict': {'level': 'fair', 'message': 'Khá ổn.'},
      'heardIpa': 't ɪ ŋ k',
      'audioMs': 1500,
      'engine': 'test',
      'words': [
        {
          'word': 'think',
          'score': 75,
          'status': 'fair',
          'spoken': true,
          'expectedIpa': 'θɪŋk',
          'heardIpa': 'tɪŋk',
          'suggestion': 'Đặt lưỡi giữa hai hàm răng.',
          'extras': 0,
          'phonemes': [
            {'expectedIpa': 'θ', 'score': 0.25, 'status': 'wrong'},
            {'expectedIpa': 'ɪ', 'score': 0.75, 'status': 'close'},
            {'expectedIpa': 'ŋ', 'score': 1, 'status': 'correct'},
          ],
        },
        {
          'word': 'so',
          'score': 0,
          'status': 'poor',
          'spoken': false,
          'expectedIpa': 'soʊ',
          'heardIpa': '',
          'suggestion': 'Bạn chưa đọc từ này.',
          'extras': 0,
          'phonemes': [
            {'expectedIpa': 's', 'score': 0, 'status': 'missing'},
          ],
        },
        {
          'word': 'well',
          'score': 95,
          'status': 'good',
          'spoken': true,
          'expectedIpa': 'wɛl',
          'heardIpa': 'wɛl',
          'suggestion': null,
          'extras': 0,
          'phonemes': <Map<String, dynamic>>[],
        },
      ],
      'issues': [
        {'title': 'Âm /θ/'},
        {'title': 'Phụ âm cuối từ'},
        {'title': 'Nguyên âm'},
      ],
    };

const lesson = Lesson(
  id: 'l1',
  content: 'think so',
  ipaTranscript: '/θɪŋk soʊ/',
  vietnameseMeaning: 'Nghĩ vậy',
  type: LessonType.sentence,
  difficulty: DifficultyLevel.beginner,
  category: 'test',
);

class FakeAnalysisRepository implements SpeechAnalysisRepository {
  SpeechAnalysis Function() respond;
  FakeAnalysisRepository(this.respond);

  @override
  Future<SpeechAnalysis> analyze({
    required String audioPath,
    required String text,
  }) async =>
      respond();
}

class FakeResultRepository implements PronunciationResultRepository {
  final saved = <PronunciationResult>[];

  @override
  Future<void> saveResult(PronunciationResult result) async => saved.add(result);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSessionRepository implements PracticeSessionRepository {
  PracticeSession? today;

  @override
  Future<PracticeSession?> getTodaySession(String userId) async => today;

  @override
  Future<void> saveSession(PracticeSession session) async => today = session;

  @override
  Future<void> updateSession(PracticeSession session) async => today = session;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRecorder implements SpeechRecorder {
  final discarded = <String>[];
  Failure? startFailure;
  bool cancelled = false;
  bool disposed = false;

  @override
  Future<void> start() async {
    if (startFailure != null) throw startFailure!;
  }

  @override
  Future<String> stop() async => 'a.wav';

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> discard(String path) async => discarded.add(path);

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  group('SpeechAnalysisModel', () {
    test('ánh xạ điểm và trạng thái từ', () {
      final analysis = SpeechAnalysisModel.fromJson(serverJson());
      expect(analysis.overallScore, 72);
      expect(analysis.fluencyScore, 88);
      expect(analysis.audioDuration, const Duration(milliseconds: 1500));
      expect(analysis.words.map((w) => w.status), ['wrong', 'missed', 'correct']);
      expect(analysis.words[1].userIpa, '');
    });

    test('ánh xạ đánh giá âm vị, close tính là đúng', () {
      final words = SpeechAnalysisModel.fromJson(serverJson()).words;
      expect(words[0].phonemes.map((p) => p.assessment),
          ['mispronounced', 'correct', 'correct']);
      expect(words[0].phonemes[0].accuracyScore, 25);
      expect(words[1].phonemes[0].assessment, 'omitted');
    });

    test('nhận xét gồm tối đa 2 lỗi và cảnh báo ồn', () {
      final analysis = SpeechAnalysisModel.fromJson(serverJson(noisy: true));
      expect(analysis.feedback, contains('Âm /θ/; Phụ âm cuối từ.'));
      expect(analysis.feedback, isNot(contains('Nguyên âm')));
      expect(analysis.feedback, contains('ồn'));
    });
  });

  group('PronunciationResultMapper', () {
    final result = PronunciationResult(
      id: 'r',
      sessionId: 's',
      lessonId: 'l',
      userId: 'u',
      audioFilePath: 'a.wav',
      words: SpeechAnalysisModel.fromJson(serverJson()).words,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    );

    test('màn hình phản hồi đọc được dữ liệu đã lưu', () {
      final entity = PronunciationResultMapper.toEntity(result);
      final words = WordFeedback.listFromJson(entity.phonemeDetails);
      expect(words.map((w) => w.word), ['think', 'so', 'well']);
      expect(words[1].status, WordStatus.missed);
      expect(words[0].suggestion, isNotNull);
    });

    test('lưu rồi đọc lại giữ nguyên từ và âm vị', () {
      final restored = PronunciationResultMapper.fromEntity(
        PronunciationResultMapper.toEntity(result),
      );
      expect(restored.words.length, 3);
      expect(restored.words[0].phonemes[0].assessment, 'mispronounced');
      expect(restored.phonemeDetails.length, 4);
    });

    test('vẫn đọc được bản ghi cũ chỉ có âm vị', () {
      final old = PronunciationResultEntity(
        id: 'r',
        sessionId: 's',
        lessonId: 'l',
        userId: 'u',
        audioFilePath: '',
        accuracyScore: 0,
        fluencyScore: 0,
        completenessScore: 0,
        overallScore: 0,
        phonemeDetails: jsonEncode([
          {'phoneme': 'θ', 'accuracyScore': 50, 'assessment': 'mispronounced'},
        ]),
        feedback: '',
        createdAt: 0,
      );
      final restored = PronunciationResultMapper.fromEntity(old);
      expect(restored.phonemeDetails.single.phoneme, 'θ');
      expect(restored.words, isEmpty);
    });
  });

  group('AnalyzePronunciation', () {
    late FakeResultRepository results;
    late FakeSessionRepository sessions;

    setUp(() {
      results = FakeResultRepository();
      sessions = FakeSessionRepository();
    });

    AnalyzePronunciation useCase(Map<String, dynamic> json) {
      return AnalyzePronunciation(
        analysisRepository:
            FakeAnalysisRepository(() => SpeechAnalysisModel.fromJson(json)),
        resultRepository: results,
        sessionRepository: sessions,
      );
    }

    test('lần đầu trong ngày tạo phiên và lưu kết quả', () async {
      final attempt = await useCase(serverJson())(
          lesson: lesson, userId: 'u', audioPath: 'a.wav');
      expect(attempt.result, isNotNull);
      expect(sessions.today!.lessonsCompleted, 1);
      expect(results.saved.single.sessionId, sessions.today!.id);
      expect(results.saved.single.fluencyScore, 88);
    });

    test('lần sau cộng dồn vào phiên trong ngày', () async {
      final analyze = useCase(serverJson());
      await analyze(lesson: lesson, userId: 'u', audioPath: 'a.wav');
      final firstId = sessions.today!.id;
      await analyze(lesson: lesson, userId: 'u', audioPath: 'b.wav');
      expect(sessions.today!.id, firstId);
      expect(sessions.today!.lessonsCompleted, 2);
      expect(sessions.today!.totalScore, 72);
      expect(sessions.today!.duration, const Duration(seconds: 3));
    });

    test('đọc sai câu thì không lưu', () async {
      final attempt = await useCase(serverJson(offTarget: true))(
          lesson: lesson, userId: 'u', audioPath: 'a.wav');
      expect(attempt.result, isNull);
      expect(results.saved, isEmpty);
      expect(sessions.today, isNull);
    });
  });

  group('PracticeController', () {
    late FakeRecorder recorder;

    setUp(() => recorder = FakeRecorder());

    PracticeController controller(SpeechAnalysis Function() respond) {
      return PracticeController(
        lesson: lesson,
        userId: 'u',
        recorder: recorder,
        analyze: AnalyzePronunciation(
          analysisRepository: FakeAnalysisRepository(respond),
          resultRepository: FakeResultRepository(),
          sessionRepository: FakeSessionRepository(),
        ),
      );
    }

    test('thu âm xong trả về kết quả và giữ file', () async {
      final c = controller(() => SpeechAnalysisModel.fromJson(serverJson()));
      await c.startRecording();
      expect(c.state, PracticeState.recording);
      final attempt = await c.stopAndAnalyze();
      expect(attempt?.result, isNotNull);
      expect(c.state, PracticeState.idle);
      expect(recorder.discarded, isEmpty);
      c.dispose();
    });

    test('thiếu quyền micro thì báo lỗi', () async {
      recorder.startFailure = const PermissionFailure(message: 'Cần micro');
      final c = controller(() => throw StateError('không được gọi'));
      await c.startRecording();
      expect(c.state, PracticeState.idle);
      expect(c.message, 'Cần micro');
      c.dispose();
    });

    test('phân tích lỗi thì báo lỗi và xóa file', () async {
      final c = controller(
          () => throw const NetworkFailure(message: 'Mất kết nối'));
      await c.startRecording();
      expect(await c.stopAndAnalyze(), isNull);
      expect(c.message, 'Mất kết nối');
      expect(recorder.discarded, ['a.wav']);
      c.dispose();
    });

    test('đọc sai câu thì nhắc và xóa file', () async {
      final c = controller(
          () => SpeechAnalysisModel.fromJson(serverJson(offTarget: true)));
      await c.startRecording();
      expect(await c.stopAndAnalyze(), isNull);
      expect(c.message, contains('câu khác'));
      expect(recorder.discarded, ['a.wav']);
      c.dispose();
    });

    test('hết giờ thì gọi tự dừng', () async {
      var stopped = false;
      final c = PracticeController(
        lesson: lesson,
        userId: 'u',
        recorder: recorder,
        analyze: AnalyzePronunciation(
          analysisRepository: FakeAnalysisRepository(
              () => SpeechAnalysisModel.fromJson(serverJson())),
          resultRepository: FakeResultRepository(),
          sessionRepository: FakeSessionRepository(),
        ),
        maxDuration: const Duration(milliseconds: 1),
      )..onAutoStop = () => stopped = true;
      await c.startRecording();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(stopped, isTrue);
      c.dispose();
      expect(recorder.cancelled, isTrue);
      expect(recorder.disposed, isTrue);
    });
  });

  group('SpeechApiClient', () {
    late HttpServer server;
    late String audioPath;
    late Future<void> Function(HttpRequest) handler;

    setUp(() async {
      server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((request) => handler(request));
      final dir = await Directory.systemTemp.createTemp('speech_api');
      audioPath = '${dir.path}/a.wav';
      await File(audioPath).writeAsBytes([1, 2, 3, 255]);
    });

    tearDown(() => server.close(force: true));

    SpeechAnalysisRepositoryImpl repository() => SpeechAnalysisRepositoryImpl(
          client: SpeechApiClient(baseUrl: 'http://127.0.0.1:${server.port}'),
        );

    Future<void> replyWith(HttpRequest request, int status, Object body) async {
      await request.drain<void>();
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await request.response.close();
    }

    test('gửi nguyên byte WAV và câu mục tiêu', () async {
      late List<int> received;
      late Uri uri;
      late String? contentType;
      handler = (request) async {
        uri = request.uri;
        contentType = request.headers.contentType?.mimeType;
        received = await request.expand((chunk) => chunk).toList();
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(serverJson()));
        await request.response.close();
      };

      final analysis = await repository()
          .analyze(audioPath: audioPath, text: "It's fine");
      expect(received, [1, 2, 3, 255]);
      expect(uri.path, '/api/pronunciation/analyze');
      expect(uri.queryParameters['text'], "It's fine");
      expect(contentType, 'audio/wav');
      expect(analysis.overallScore, 72);
    });

    test('lỗi âm thanh trở thành AudioFailure với thông báo của máy chủ', () {
      handler = (request) => replyWith(request, 422, {
            'error': {'code': 'NO_SPEECH', 'message': 'Không nghe thấy'},
          });
      expect(
        repository().analyze(audioPath: audioPath, text: 'x'),
        throwsA(isA<AudioFailure>()
            .having((f) => f.message, 'message', 'Không nghe thấy')),
      );
    });

    test('mô hình bận trở thành PronunciationAnalysisFailure', () {
      handler = (request) => replyWith(request, 503, {
            'error': {'code': 'MODEL_BUSY', 'message': 'Đang bận'},
          });
      expect(
        repository().analyze(audioPath: audioPath, text: 'x'),
        throwsA(isA<PronunciationAnalysisFailure>()),
      );
    });

    test('JSON sai định dạng trở thành PronunciationAnalysisFailure', () {
      handler = (request) => replyWith(request, 200, {'overall': 'abc'});
      expect(
        repository().analyze(audioPath: audioPath, text: 'x'),
        throwsA(isA<PronunciationAnalysisFailure>()),
      );
    });

    test('không kết nối được trở thành NetworkFailure', () async {
      final closed = await HttpServer.bind('127.0.0.1', 0);
      final port = closed.port;
      await closed.close();
      final repo = SpeechAnalysisRepositoryImpl(
        client: SpeechApiClient(baseUrl: 'http://127.0.0.1:$port'),
      );
      expect(
        repo.analyze(audioPath: audioPath, text: 'x'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
