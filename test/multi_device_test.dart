import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:articulation/features/quality_assurance/domain/models/qa_diagnostics.dart';
import 'package:articulation/features/pronunciation/domain/entities/lesson.dart';
import 'package:articulation/features/pronunciation/domain/entities/pronunciation_result.dart'
    hide PhonemeDetail;
import 'package:articulation/features/pronunciation/presentation/models/word_feedback.dart';
import 'package:articulation/features/pronunciation/presentation/screens/pronunciation_feedback_screen.dart';

void main() {
  group('DeviceScreenType Breakpoints', () {
    test('phân loại đúng điện thoại (< 600px)', () {
      expect(DeviceScreenType.fromWidth(360), DeviceScreenType.mobile);
      expect(DeviceScreenType.fromWidth(412), DeviceScreenType.mobile);
      expect(DeviceScreenType.fromWidth(599), DeviceScreenType.mobile);
    });

    test('phân loại đúng tablet (600px - 900px)', () {
      expect(DeviceScreenType.fromWidth(600), DeviceScreenType.tablet);
      expect(DeviceScreenType.fromWidth(768), DeviceScreenType.tablet);
      expect(DeviceScreenType.fromWidth(900), DeviceScreenType.tablet);
    });

    test('phân loại đúng Desktop Web (> 900px)', () {
      expect(DeviceScreenType.fromWidth(901), DeviceScreenType.desktopWeb);
      expect(DeviceScreenType.fromWidth(1280), DeviceScreenType.desktopWeb);
      expect(DeviceScreenType.fromWidth(1920), DeviceScreenType.desktopWeb);
    });
  });

  group('Kiểm thử giao diện đa thiết bị (Multi-Device UI Rendering)', () {
    const testLesson = Lesson(
      id: 'test_l1',
      content: 'think so',
      ipaTranscript: '/θɪŋk soʊ/',
      vietnameseMeaning: 'Nghĩ vậy',
      type: LessonType.sentence,
      difficulty: DifficultyLevel.beginner,
      category: 'Daily',
    );

    final testResult = PronunciationResult(
      id: 'r1',
      sessionId: 's1',
      lessonId: 'test_l1',
      userId: 'u1',
      audioFilePath: '',
      accuracyScore: 85,
      fluencyScore: 90,
      completenessScore: 100,
      overallScore: 88,
      feedback: 'Phát âm tốt!',
      createdAt: DateTime.now(),
    );

    const testWords = [
      WordFeedback(
        word: 'think',
        status: WordStatus.correct,
        correctIpa: 'θɪŋk',
        userIpa: 'θɪŋk',
        score: 90,
      ),
      WordFeedback(
        word: 'so',
        status: WordStatus.correct,
        correctIpa: 'soʊ',
        userIpa: 'soʊ',
        score: 86,
      ),
    ];

    testWidgets('Giao diện hiển thị chuẩn xác trên Mobile Phone (360 x 640)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PronunciationFeedbackScreen(
            lesson: testLesson,
            result: testResult,
            words: testWords,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kết quả phát âm'), findsOneWidget);
      expect(find.text('think so'), findsOneWidget);
      expect(find.text('Bạn đã đọc'), findsOneWidget);
    });

    testWidgets('Giao diện hiển thị chuẩn xác trên Tablet (768 x 1024)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PronunciationFeedbackScreen(
            lesson: testLesson,
            result: testResult,
            words: testWords,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kết quả phát âm'), findsOneWidget);
      expect(find.text('think so'), findsOneWidget);
    });

    testWidgets('Giao diện hiển thị chuẩn xác trên Desktop Web (1280 x 800)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PronunciationFeedbackScreen(
            lesson: testLesson,
            result: testResult,
            words: testWords,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kết quả phát âm'), findsOneWidget);
      expect(find.text('think so'), findsOneWidget);
    });
  });
}
