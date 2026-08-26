import 'package:fastway/core/theme/colors.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/announcements_cubit.dart';
import '../cubit/announcements_state.dart';
import '../../domain/entities/announcement_entity.dart';

// ── Helper: parse "#RRGGBB" / "#AARRGGBB" → Color ───────────────────────────
Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final clean = hex.replaceAll('#', '');
  if (clean.length == 6) {
    final value = int.tryParse('FF$clean', radix: 16);
    return value != null ? Color(value) : null;
  }
  if (clean.length == 8) {
    final value = int.tryParse(clean, radix: 16);
    return value != null ? Color(value) : null;
  }
  return null;
}

// ═════════════════════════════════════════════════════════════════════════════
// DESKTOP — fading banner (one announcement at a time, per-announcement colors)
// ═════════════════════════════════════════════════════════════════════════════

class AnnouncementsBanner extends StatelessWidget {
  const AnnouncementsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
      builder: (context, state) {
        if (state is AnnouncementsLoaded && state.announcements.isNotEmpty) {
          return _FadingAnnouncements(announcements: state.announcements);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _FadingAnnouncements extends StatefulWidget {
  final List<AnnouncementEntity> announcements;
  const _FadingAnnouncements({required this.announcements});

  @override
  State<_FadingAnnouncements> createState() => _FadingAnnouncementsState();
}

class _FadingAnnouncementsState extends State<_FadingAnnouncements> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (widget.announcements.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.announcements.length;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _FadingAnnouncements oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.announcements.length != oldWidget.announcements.length) {
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) return const SizedBox.shrink();

    if (_currentIndex >= widget.announcements.length) _currentIndex = 0;

    final ann    = widget.announcements[_currentIndex];
    final isAr   = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title    = isAr ? ann.titleAr : ann.title;
    final body     = isAr ? ann.bodyAr  : ann.body;
    final fullText = '$title - $body';

    // Admin-set colors take priority; fall back to theme defaults
    final bgColor   = _parseHex(ann.bgColor)   ?? Theme.of(context).scaffoldBackgroundColor;
    final textColor = _parseHex(ann.textColor)  ?? (isDark ? Colors.white : Colors.black87);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      height: 36,
      color: bgColor,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Padding(
          key: ValueKey<int>(ann.id),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            fullText,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MOBILE — scrolling ticker, one announcement at a time with its own colors
// Each announcement's full text scrolls horizontally so long text is readable.
// When done scrolling, switches to the next announcement (with its colors).
// ═════════════════════════════════════════════════════════════════════════════

class AnnouncementsTicker extends StatelessWidget {
  const AnnouncementsTicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
      builder: (context, state) {
        if (state is AnnouncementsLoaded && state.announcements.isNotEmpty) {
          return _CyclingScrollTicker(announcements: state.announcements);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CyclingScrollTicker extends StatefulWidget {
  final List<AnnouncementEntity> announcements;
  const _CyclingScrollTicker({required this.announcements});

  @override
  State<_CyclingScrollTicker> createState() => _CyclingScrollTickerState();
}

class _CyclingScrollTickerState extends State<_CyclingScrollTicker>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _scrollController;
  static const double _speed = 50.0; // pixels per second
  double _textWidth = 400.0;
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _scrollController.addStatusListener(_onScrollDone);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _onScrollDone(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      // Advance to next announcement then restart scroll
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.announcements.length;
      });
      // Small pause before next scroll starts
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _scrollController.reset();
          WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
        }
      });
    }
  }

  void _startScroll() {
    if (!mounted) return;
    final box = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) _textWidth = box.size.width; 
    
    // We add screen width to the distance so it scrolls completely from edge to edge
    final screenWidth = MediaQuery.sizeOf(context).width;
    final totalDistance = screenWidth + _textWidth;
    
    final ms = (totalDistance / _speed * 1000).round();
    _scrollController.duration = Duration(milliseconds: ms);
    _scrollController.forward();
  }

  @override
  void didUpdateWidget(covariant _CyclingScrollTicker old) {
    super.didUpdateWidget(old);
    if (old.announcements != widget.announcements) {
      _scrollController.reset();
      _currentIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) return const SizedBox.shrink();
    if (_currentIndex >= widget.announcements.length) _currentIndex = 0;

    final ann    = widget.announcements[_currentIndex];
    final isAr   = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = isAr ? ann.titleAr : ann.title;
    final body  = isAr ? ann.bodyAr  : ann.body;
    final text  = '$title — $body';

    // Per-announcement colors
    final bgColor  = _parseHex(ann.bgColor)
        ?? (isDark ? ColorsManager.surfaceDarkElevated : const Color(0xFFF0FDF4));
    final txtColor = _parseHex(ann.textColor)
        ?? (isDark ? Colors.grey.shade300 : const Color(0xFF1A1A1A));

    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: txtColor,
      height: 1,
    );

    final screenWidth = MediaQuery.sizeOf(context).width;

    // Measure single text width
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    final singleTextWidth = textPainter.width;
    int repeatCount = 1;
    if (singleTextWidth > 0 && singleTextWidth < screenWidth) {
      repeatCount = (screenWidth / (singleTextWidth + 40)).ceil() + 1; // +40 for spacing
    }

    final List<Widget> textWidgets = [];
    for (int i = 0; i < repeatCount; i++) {
      textWidgets.add(Text(text, style: textStyle, maxLines: 1));
      if (i < repeatCount - 1) {
        textWidgets.add(const SizedBox(width: 40));
        textWidgets.add(
          Icon(Icons.circle, size: 4, color: txtColor.withValues(alpha: 0.5)),
        );
        textWidgets.add(const SizedBox(width: 40));
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 34,
      color: bgColor,
      child: Row(
        children: [
          // Scrolling text for this announcement only
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final totalDistance = screenWidth + _textWidth;
                  
                  // In RTL: Start completely off-screen left (-screenWidth), end completely off-screen right (+_textWidth)
                  // In LTR: Start completely off-screen right (+screenWidth), end completely off-screen left (-_textWidth)
                  final dx = isAr
                      ? -screenWidth + (_scrollController.value * totalDistance)
                      : screenWidth - (_scrollController.value * totalDistance);

                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: OverflowBox(
                  maxWidth: double.infinity,
                  alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    key: _textKey,
                    mainAxisSize: MainAxisSize.min,
                    children: textWidgets,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
