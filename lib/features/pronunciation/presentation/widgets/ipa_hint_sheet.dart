import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_text_styles.dart';
import 'package:articulation/core/utils/constants.dart';
import 'package:articulation/features/pronunciation/presentation/models/word_feedback.dart';

/// Mở popup (bottom sheet) so sánh IPA chuẩn với IPA người dùng đã đọc.
Future<void> showIpaHintSheet(BuildContext context, WordFeedback word) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _IpaHintContent(word: word),
  );
}

String _slash(String ipa) {
  if (ipa.isEmpty) return '';
  final wrapped = ipa.startsWith('/') || ipa.startsWith('[');
  return wrapped ? ipa : '/$ipa/';
}

class _IpaHintContent extends StatelessWidget {
  final WordFeedback word;
  const _IpaHintContent({required this.word});

  @override
  Widget build(BuildContext context) {
    final s = word.status;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề: từ + trạng thái + điểm
            Row(
              children: [
                Expanded(child: Text(word.word, style: AppTextStyles.h2)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: s.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, size: 16, color: s.color),
                      const SizedBox(width: 4),
                      Text(
                        '${s.label} • ${AppHelpers.formatScore(word.score)}',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: s.textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _IpaRow(
              label: 'IPA chuẩn',
              child: Text(
                _slash(word.correctIpa),
                style: AppTextStyles.ipaText.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _IpaRow(
              label: 'Bạn đã đọc',
              child: word.userIpa.isEmpty
                  ? Text(
                      'Không nghe thấy bạn phát âm từ này',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    )
                  : _UserIpaDiff(
                      correct: word.correctIpa,
                      user: _slash(word.userIpa),
                    ),
            ),

            if (word.suggestion != null && word.suggestion!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(word.suggestion!,
                          style: AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IpaRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _IpaRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

/// IPA người dùng, ký tự lệch so với IPA chuẩn được tô đỏ và in đậm.
class _UserIpaDiff extends StatelessWidget {
  final String correct;
  final String user; // đã có dấu / /

  const _UserIpaDiff({required this.correct, required this.user});

  @override
  Widget build(BuildContext context) {
    final userRunes = user.runes.toList();
    final bad = mismatchedIndexes(correct, user);

    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < userRunes.length; i++)
            TextSpan(
              text: String.fromCharCode(userRunes[i]),
              style: bad.contains(i)
                  ? const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w800)
                  : const TextStyle(color: AppColors.textPrimary),
            ),
        ],
      ),
      style: AppTextStyles.ipaText,
    );
  }
}

/// Trả về vị trí các ký tự trong [user] KHÔNG khớp với [correct]
/// (dựa trên chuỗi con chung dài nhất - LCS). Các ký tự '/', '[', ']'
/// bao quanh IPA luôn được coi là khớp.
@visibleForTesting
Set<int> mismatchedIndexes(String correct, String user) {
  final a = correct.runes.toList();
  final b = user.runes.toList();
  final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));

  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] == b[j - 1]
          ? dp[i - 1][j - 1] + 1
          : (dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]);
    }
  }

  final matched = <int>{};
  var i = a.length, j = b.length;
  while (i > 0 && j > 0) {
    if (a[i - 1] == b[j - 1]) {
      matched.add(j - 1);
      i--;
      j--;
    } else if (dp[i - 1][j] >= dp[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }

  const brackets = {0x2F, 0x5B, 0x5D}; // / [ ]
  return {
    for (var k = 0; k < b.length; k++)
      if (!matched.contains(k) && !brackets.contains(b[k])) k,
  };
}
