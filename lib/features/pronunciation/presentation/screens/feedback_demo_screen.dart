import 'package:flutter/material.dart';
import 'package:articulation/features/pronunciation/domain/entities/lesson.dart';
import 'package:articulation/features/pronunciation/domain/entities/pronunciation_result.dart'
    hide PhonemeDetail;
import 'package:articulation/features/pronunciation/presentation/models/word_feedback.dart';
import 'package:articulation/features/pronunciation/presentation/screens/pronunciation_feedback_screen.dart';

/// Màn hình demo với dữ liệu giả, để test UI khi phần Speech/AI chưa xong.
/// Chạy thử: đổi `home:` trong main.dart thành `const FeedbackDemoScreen()`
/// (đừng commit thay đổi main.dart đó).
class FeedbackDemoScreen extends StatelessWidget {
  const FeedbackDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const lesson = Lesson(
      id: 'demo',
      content: 'I would like a cup of coffee',
      ipaTranscript: '/aɪ wʊd laɪk ə kʌp ʌv ˈkɔːfi/',
      vietnameseMeaning: 'Tôi muốn một tách cà phê',
      type: LessonType.sentence,
      difficulty: DifficultyLevel.beginner,
      category: 'Daily',
    );

    final result = PronunciationResult(
      id: 'r1',
      sessionId: 's1',
      lessonId: 'demo',
      userId: 'local_user',
      audioFilePath: '', // chưa có file ghi âm thật -> nút bị vô hiệu hoá
      accuracyScore: 72,
      fluencyScore: 85,
      completenessScore: 83,
      overallScore: 76,
      feedback: 'Bạn đọc khá tốt! Hãy chú ý nguyên âm trong "would" và "coffee".',
      createdAt: DateTime.now(),
    );

    const words = [
      WordFeedback(word: 'I', status: WordStatus.correct, correctIpa: 'aɪ', userIpa: 'aɪ', score: 95),
      WordFeedback(
        word: 'would',
        status: WordStatus.wrong,
        correctIpa: 'wʊd',
        userIpa: 'wʌd',
        score: 48,
        suggestion: 'Đọc /ʊ/ ngắn, môi tròn nhẹ, không đọc thành /ʌ/ như "cup".',
      ),
      WordFeedback(word: 'like', status: WordStatus.correct, correctIpa: 'laɪk', userIpa: 'laɪk', score: 92),
      WordFeedback(
        word: 'a',
        status: WordStatus.missed,
        correctIpa: 'ə',
        score: 0,
        suggestion: 'Từ "a" thường đọc nhẹ /ə/, nhưng vẫn cần đọc để câu đủ ý.',
      ),
      WordFeedback(word: 'cup', status: WordStatus.correct, correctIpa: 'kʌp', userIpa: 'kʌp', score: 88),
      WordFeedback(word: 'of', status: WordStatus.correct, correctIpa: 'əv', userIpa: 'əv', score: 90),
      WordFeedback(
        word: 'coffee',
        status: WordStatus.wrong,
        correctIpa: 'ˈkɔːfi',
        userIpa: 'ˈkɑfi',
        score: 55,
        suggestion: 'Nguyên âm đầu là /ɔː/ (kéo dài, miệng tròn), không phải /ɑ/.',
      ),
    ];

    return PronunciationFeedbackScreen(
      lesson: lesson,
      result: result,
      words: words,
      onRetry: () => Navigator.of(context).maybePop(),
    );
  }
}
