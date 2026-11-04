import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_text_styles.dart';

/// Nút phát lại âm thanh. [source] có thể là:
///  - đường dẫn file trong máy (bản ghi của người dùng, .m4a/.wav)
///  - URL http(s) hoặc blob (âm thanh mẫu hoặc bản ghi trên web)
///  - asset: đường dẫn asset
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
        if (src.startsWith('http') || src.startsWith('blob:')) {
          await _player.setUrl(src);
        } else if (src.startsWith('asset:')) {
          await _player.setAsset(src.replaceFirst('asset:', ''));
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

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _enabled ? _toggle : null,
            icon: buffering
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(widget.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (widget.allowSlow && _enabled) ...[
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('0.75x', style: AppTextStyles.labelMedium),
            selected: _slow,
            onSelected: (val) async {
              setState(() => _slow = val);
              if (_player.playing) {
                await _player.setSpeed(_slow ? 0.75 : 1.0);
              }
            },
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
          ),
        ],
      ],
    );
  }
}
