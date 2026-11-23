import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'aurora_background.dart';

/// Full-height landing hero for the home page.
class LuminaHero extends StatefulWidget {
  const LuminaHero({super.key, this.onScrollCue});

  /// Called when the "Today's spotlight" cue at the bottom is tapped.
  final VoidCallback? onScrollCue;

  @override
  State<LuminaHero> createState() => _LuminaHeroState();
}

class _LuminaHeroState extends State<LuminaHero> with TickerProviderStateMixin {
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);
  late final AnimationController _intro;
  late final AnimationController _shimmer;
  late final AnimationController _cue;

  static const _orange = Color(0xFFFF6600);
  static const _coral = Color(0xFFFF4B3E);
  static const _amber = Color(0xFFFFA23A);

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // On the web, text is invisible until its font has downloaded, so start
    // the entrance once the first font arrives (or after a short fallback).
    PaintingBinding.instance.systemFonts.addListener(_startIntro);
    Future.delayed(const Duration(milliseconds: 1400), _startIntro);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _cue = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  bool _introScheduled = false;
  bool _visible = true;
  ScrollPosition? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scroll) {
      _scroll?.removeListener(_onScroll);
      _scroll = position?..addListener(_onScroll);
    }
  }

  /// Mutes every hero animation once the hero has scrolled out of view.
  void _onScroll() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final visible = _scroll!.pixels < box.size.height;
    if (visible != _visible) setState(() => _visible = visible);
  }

  void _startIntro() {
    // Note: don't remove this listener from inside the callback. The system
    // fonts notifier iterates a Set, so removing mid-notification throws and
    // stops other text from picking up the newly loaded font.
    if (_introScheduled || !mounted) return;
    _introScheduled = true;
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _intro.forward();
    });
  }

  @override
  void dispose() {
    _scroll?.removeListener(_onScroll);
    PaintingBinding.instance.systemFonts.removeListener(_startIntro);
    _intro.dispose();
    _shimmer.dispose();
    _cue.dispose();
    _pointer.dispose();
    super.dispose();
  }

  Widget _stagger({required double from, required Widget child}) {
    final curve = CurvedAnimation(
      parent: _intro,
      curve: Interval(
        from,
        math.min(from + 0.45, 1),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = math.max(size.height, 640.0);
    final wordSize = (size.width * 0.17).clamp(84.0, 168.0);
    final narrow = size.width < 600;

    const ink = Color(0xFF2A1A16);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: MouseRegion(
        onHover: (e) => _pointer.value = e.localPosition,
        onExit: (_) => _pointer.value = null,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => _pointer.value = e.localPosition,
          onPointerMove: (e) => _pointer.value = e.localPosition,
          child: TickerMode(
            enabled: _visible,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Clip so the light never spills onto the section below.
                RepaintBoundary(
                  child: ClipRect(child: AuroraBackground(pointer: _pointer)),
                ),

                // Headline block.
                Align(
                  alignment: const Alignment(0, -0.16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _stagger(
                          from: 0.08,
                          child: AnimatedBuilder(
                            animation: _shimmer,
                            builder: (context, child) {
                              final p = _shimmer.value * 2 - 0.5; // -0.5..1.5
                              return ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback:
                                    (bounds) => LinearGradient(
                                      colors: const [
                                        _orange,
                                        _amber,
                                        _coral,
                                        _orange,
                                      ],
                                      stops: [
                                        0.0,
                                        (p - 0.25).clamp(0.0, 1.0),
                                        p.clamp(0.0, 1.0),
                                        1.0,
                                      ],
                                    ).createShader(bounds),
                                child: child,
                              );
                            },
                            child: Text(
                              'lumina',
                              style: GoogleFonts.baloo2(
                                fontSize: wordSize,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                letterSpacing: -wordSize * 0.02,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _stagger(
                          from: 0.2,
                          child: Text(
                            'illuminating hidden inequalities',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.baloo2(
                              fontSize: narrow ? 20 : 24,
                              fontWeight: FontWeight.w500,
                              color: ink.withOpacity(0.85),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _stagger(
                          from: 0.32,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            runSpacing: 12,
                            children: [
                              _PrimaryButton(
                                label: 'Share your story',
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/postStory',
                                    ),
                              ),
                              _GhostButton(
                                label: 'Explore stories',
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/explore',
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scroll cue.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 22,
                  child: _stagger(
                    from: 0.5,
                    child: Center(
                      child: GestureDetector(
                        onTap: widget.onScrollCue,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedBuilder(
                            animation: _cue,
                            builder:
                                (context, child) => Transform.translate(
                                  offset: Offset(
                                    0,
                                    Curves.easeInOut.transform(_cue.value) * 6,
                                  ),
                                  child: child,
                                ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Today's Spotlight",
                                  style: GoogleFonts.baloo2(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: const Color(0xFF7A4A3A),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF7A4A3A),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFFF7A24) : const Color(0xFFFF6600),
            border: Border.all(
              color: _focus ? const Color(0xFF2A1A16) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5A2A).withOpacity(_hover ? 0.5 : 0.32),
                blurRadius: _hover ? 26 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.baloo2(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A1A16),
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: Offset(_hover ? 0.2 : 0, 0),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Color(0xFF2A1A16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  const _GhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF2A1A16);
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: fg.withOpacity(_hover ? 0.12 : 0.05),
            border: Border.all(
              color: _focus ? fg : fg.withOpacity(_hover ? 0.4 : 0.22),
              width: _focus ? 2 : 1,
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.baloo2(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
