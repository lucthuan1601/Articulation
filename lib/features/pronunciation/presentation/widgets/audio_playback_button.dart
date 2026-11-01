import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_text_styles.dart';

/// Nút phát lại âm thanh. [source] có thể là:
///  - đường dẫn file trong máy (bản ghi của người dùng, .m4a/.wav)
///  - URL http(s) (âm thanh mẫu của bài học)
/// Nếu [source] null/rỗng thì nút bị vô hiệu hoá.
class AudioPlaybackButton extends StatefulWidget {
  final String? source;
  final String label;
  final Color color;

  /// Hiện công tắc phát chậm 0.75x (hữu ích cho âm thanh mẫu).
  final bool allowSlow;

  const AudioPlaybackButton({
    super.key,
    required this.source,
    required this.label,
    this.color = AppColors.primary,
    this.allowSlow = false,
  });

  @override
  State<AudioPlaybackButton> createState() => _AudioPlaybackButtonState();
}

class _AudioPlaybackButtonState extends State<AudioPlaybackButton> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _sub;
  String? _loadedSource;
  bool _loadingSource = false;
  bool _slow = false;

  bool get _enabled => widget.source != null && widget.source!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _sub = _player.playerStateStream.listen((state) async {
      // Phát xong thì tua về đầu để lần sau bấm là phát lại.
      if (state.processingState == ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggle() async {
    final src = widget.source;
    if (src == null || src.isEmpty) return;

    try {
      if (_player.playing) {
        await _player.pause();
        return;
      }

      if (_loadedSource != src) {
        setState(() => _loadingSource = true);
        if (src.startsWith('http')) {
          await _player.setUrl(src);
        } else {
          await _player.setFilePath(src);
        }
        _loadedSource = src;
        if (mounted) setState(() => _loadingSource = false);
      }

      await _player.setSpeed(_slow ? 0.75 : 1.0);
      // play() chỉ hoàn thành khi phát xong, nên không await.
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSource = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát âm thanh này')),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _player.playerState;
    final buffering = _loadingSource ||
        state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering;
    final playing = state.playing &&
        state.processingState != ProcessingState.completed;
    final color = _enabled ? widget.color : AppColors.textHint;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: OutlinedButton.icon(
            onPressed: _enabled ? _toggle : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: buffering
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  )
                : Icon(playing
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded),
            label: Text(
              _enabled ? widget.label : '${widget.label} (chưa có)',
              style: AppTextStyles.labelLarge.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (widget.allowSlow && _enabled) ...[
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('0.75x'),
            selected: _slow,
            onSelected: (v) async {
              setState(() => _slow = v);
              await _player.setSpeed(v ? 0.75 : 1.0);
            },
          ),
        ],
      ],
    );
  }
}
