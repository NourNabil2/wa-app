// lib/core/widgets/animated_search_hint.dart

import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedSearchHint extends StatefulWidget {
  final List<String> hints;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration pauseDuration;

  const AnimatedSearchHint({
    super.key,
    required this.hints,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 60),
    this.pauseDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<AnimatedSearchHint> {
  int _hintIndex = 0;
  String _displayed = '';
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.typingSpeed, (_) {
      if (!mounted) return;
      final target = widget.hints[_hintIndex];
      setState(() {
        if (!_isDeleting) {
          // typing
          if (_displayed.length < target.length) {
            _displayed = target.substring(0, _displayed.length + 1);
          } else {
            // pause then delete
            _timer?.cancel();
            Future.delayed(widget.pauseDuration, () {
              if (!mounted) return;
              _isDeleting = true;
              _startTyping();
            });
          }
        } else {
          // deleting
          if (_displayed.isNotEmpty) {
            _displayed = _displayed.substring(0, _displayed.length - 1);
          } else {
            _isDeleting = false;
            _hintIndex = (_hintIndex + 1) % widget.hints.length;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_displayed, style: widget.style),
        // cursor blink
        Text('|', style: widget.style),
      ],
    );
  }
}

// _BlinkingCursor removed — AnimationController.repeat() runs at 60fps
// continuously while the search bar is visible, burning GPU budget.
// Static cursor gives same visual hint at zero cost.