import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Video Player widget for Tizen TV
/// TODO: Implement native Tizen video playback using video_player_tizen package
class HlsVideoPlayer extends StatefulWidget {
  final String streamUrl;
  final VoidCallback? onClose;

  const HlsVideoPlayer({
    super.key,
    required this.streamUrl,
    this.onClose,
  });

  @override
  State<HlsVideoPlayer> createState() => _HlsVideoPlayerState();
}

class _HlsVideoPlayerState extends State<HlsVideoPlayer> {
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    _showControlsTemporarily();

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        setState(() => _isPlaying = !_isPlaying);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.browserBack:
        _closePlayer();
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  void _closePlayer() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            _showControlsTemporarily();
            setState(() => _isPlaying = !_isPlaying);
          },
          child: Stack(
            children: [
              // Video placeholder
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlaying ? Icons.play_circle : Icons.pause_circle,
                      color: Colors.white54,
                      size: 120,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tizen Video Player',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stream: ${widget.streamUrl.split('/').last}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'TODO: Implement video_player_tizen package',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Top bar with close button
              if (_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 32),
                          onPressed: _closePlayer,
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom controls
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                          onPressed: () {
                            setState(() => _isPlaying = !_isPlaying);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
