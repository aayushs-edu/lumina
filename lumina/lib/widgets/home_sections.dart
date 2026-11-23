import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/models/story_model.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:lumina/widgets/waving_leaf.dart';

/// Colours for the home page below the hero. They continue the hero's warm
/// light as flat fields: orange, warm white, and a deep ink close.
class HomePalette {
  static const orange = Color(0xFFFF6600);
  static const orangeHover = Color(0xFFFF7A24);
  static const orangeText = Color(0xFFB84A00); // orange that reads on white
  static const ink = Color(0xFF2A1A16);
  static const inkHover = Color(0xFF45302A);
  static const soft = Color(0xFF5B4740);
  static const paper = Color(0xFFFFFCFA);
  static const rule = Color(0xFFEADBD2);
  static const cream = Color(0xFFFFF1E6);
  static const creamSoft = Color(0xFFD9C3B6);
}

/// Horizontal page gutter for a given width.
double homeGutter(double width) =>
    width < 600 ? 20 : (width < 1100 ? 40 : 64);

TextStyle _baloo(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = HomePalette.ink,
  double? height,
  double? spacing,
}) => GoogleFonts.baloo2(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: spacing,
);

/// Titles are wrapped in curly quotes on the page, so drop any quote marks
/// the author already typed around the title.
String _stripQuotes(String title) =>
    title.trim().replaceAll(RegExp('^["“”\']+|["“”\']+\$'), '');

void _openSpotlightStories(BuildContext context) {
  Navigator.pushNamed(
    context,
    '/explore',
    arguments: {'applySpotlightFilter': true},
  );
}

/// Today's spotlight theme beside its top stories: a solid orange field with
/// the theme set large, and the stories set as readable excerpts.
class SpotlightStoriesSection extends StatefulWidget {
  const SpotlightStoriesSection({super.key, required this.theme});

  final String theme;

  @override
  State<SpotlightStoriesSection> createState() =>
      _SpotlightStoriesSectionState();
}

class _SpotlightStoriesSectionState extends State<SpotlightStoriesSection> {
  late final Future<List<Story>> _stories = _load();

  Future<List<Story>> _load() async {
    final rows = await FirebaseService.getTopStoriesByTheme(widget.theme, 3);
    return rows.map(Story.fromMap).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 900;
        final gutter = homeGutter(width);

        final spotlight = _SpotlightField(
          theme: widget.theme,
          wide: wide,
          gutter: gutter,
        );
        final stories = Container(
          color: HomePalette.paper,
          padding: EdgeInsets.fromLTRB(
            wide ? 64 : gutter,
            wide ? 72 : 48,
            gutter,
            wide ? 72 : 56,
          ),
          child: _TopStories(stories: _stories),
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [spotlight, stories],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: (width * 0.4).clamp(360.0, 600.0), child: spotlight),
              Expanded(child: stories),
            ],
          ),
        );
      },
    );
  }
}

class _SpotlightField extends StatelessWidget {
  const _SpotlightField({
    required this.theme,
    required this.wide,
    required this.gutter,
  });

  final String theme;
  final bool wide;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HomePalette.orange,
      padding: EdgeInsets.fromLTRB(
        gutter,
        wide ? 72 : 48,
        wide ? 48 : gutter,
        wide ? 72 : 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Spotlight",
                style: _baloo(
                  40,
                  weight: FontWeight.w700,
                  height: 1.1,
                  spacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  theme,
                  maxLines: 1,
                  style: _baloo(
                    wide ? 96 : 64,
                    weight: FontWeight.w800,
                    height: 1.0,
                    spacing: wide ? -2.5 : -1.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: wide ? 56 : 32),
          _SquareButton(
            label: 'View Stories',
            background: HomePalette.ink,
            hoverBackground: HomePalette.inkHover,
            foreground: HomePalette.cream,
            onTap: () => _openSpotlightStories(context),
          ),
        ],
      ),
    );
  }
}

class _TopStories extends StatelessWidget {
  const _TopStories({required this.stories});

  final Future<List<Story>> stories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Stories',
          style: _baloo(40, weight: FontWeight.w700, height: 1.1, spacing: -0.8),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<Story>>(
          future: stories,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _StoriesLoading();
            }
            final list = snapshot.data ?? const <Story>[];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No stories for this theme yet.',
                  style: _baloo(18, color: HomePalette.soft),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final story in list) _StoryEntry(story: story),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StoryEntry extends StatefulWidget {
  const _StoryEntry({required this.story});

  final Story story;

  @override
  State<_StoryEntry> createState() => _StoryEntryState();
}

class _StoryEntryState extends State<_StoryEntry> {
  bool _pointerHover = false;
  bool _focus = false;

  bool get _hover => _pointerHover || _focus;

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _pointerHover = v),
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _openSpotlightStories(context);
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openSpotlightStories(context),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: HomePalette.rule)),
          ),
          foregroundDecoration:
              _focus
                  ? BoxDecoration(
                    border: Border.all(color: HomePalette.ink, width: 2),
                  )
                  : null,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      style: _baloo(
                        26,
                        weight: FontWeight.w700,
                        height: 1.2,
                        color:
                            _hover ? HomePalette.orangeText : HomePalette.ink,
                      ),
                      child: Text(
                        '“${_stripQuotes(story.title)}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    offset: Offset(_hover ? 0 : -0.3, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _hover ? 1 : 0,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 22,
                          color: HomePalette.orangeText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  story.story,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _baloo(18, color: HomePalette.soft, height: 1.55),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    story.country,
                    style: _baloo(
                      15,
                      weight: FontWeight.w700,
                      color: HomePalette.orangeText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.favorite,
                    size: 15,
                    color: HomePalette.soft,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${story.likes}',
                    style: _baloo(
                      15,
                      weight: FontWeight.w600,
                      color: HomePalette.soft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoriesLoading extends StatelessWidget {
  const _StoriesLoading();

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(height: height, color: HomePalette.rule),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: HomePalette.rule)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bar(0.55, 22),
                const SizedBox(height: 14),
                bar(0.9, 12),
                const SizedBox(height: 8),
                bar(0.7, 12),
              ],
            ),
          ),
      ],
    );
  }
}

/// The page's close: what lumina is, the invitation to share, and the footer,
/// on a deep ink field.
class HomeClosingSection extends StatelessWidget {
  const HomeClosingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 900;
        final gutter = homeGutter(width);

        final about = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LuminaHeading(before: 'What is ', after: '?', wide: wide),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                'Lumina is a platform dedicated to illuminating hidden '
                'inequalities and sharing stories of marginalized communities. '
                'Our goal is to bring awareness, spark dialogue, and empower '
                'individuals to create change. Join us in uncovering untold '
                'stories and shaping a more equitable future.',
                style: _baloo(
                  wide ? 20 : 18,
                  color: HomePalette.creamSoft,
                  height: 1.6,
                ),
              ),
            ),
          ],
        );

        final join = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LuminaHeading(before: 'Join the ', after: ' Community', wide: wide),
            const SizedBox(height: 20),
            Text(
              'Share your experience and help illuminate hidden stories. '
              'Your voice matters!',
              style: _baloo(
                wide ? 20 : 18,
                color: HomePalette.creamSoft,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _SquareButton(
              label: 'Share Your Story',
              background: HomePalette.orange,
              hoverBackground: HomePalette.orangeHover,
              foreground: HomePalette.ink,
              onTap: () => Navigator.pushNamed(context, '/postStory'),
            ),
          ],
        );

        return ClipRect(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                color: HomePalette.ink,
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  wide ? 120 : 72,
                  gutter,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: about),
                              const SizedBox(width: 96),
                              Expanded(flex: 5, child: join),
                            ],
                          )
                        else ...[
                          about,
                          const SizedBox(height: 56),
                          join,
                        ],
                        SizedBox(height: wide ? 120 : 72),
                        Container(
                          height: 1,
                          color: HomePalette.cream.withOpacity(0.14),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'lumina 2025',
                          style: _baloo(
                            14,
                            weight: FontWeight.w500,
                            color: HomePalette.creamSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // One leaf, cropped by the band's edge.
              if (wide)
                const Positioned(
                  right: -48,
                  bottom: 36,
                  child: IgnorePointer(
                    child: WavingLeaf(
                      assetPath: 'assets/orange_leaf.png',
                      width: 220,
                      initialAngle: -0.35,
                      amplitude: 0.04,
                      duration: Duration(seconds: 4),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LuminaHeading extends StatelessWidget {
  const _LuminaHeading({
    required this.before,
    required this.after,
    required this.wide,
  });

  final String before;
  final String after;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final style = _baloo(
      wide ? 44 : 34,
      weight: FontWeight.w700,
      color: HomePalette.cream,
      height: 1.1,
      spacing: -0.8,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: before),
          const TextSpan(
            text: 'lumina',
            style: TextStyle(color: HomePalette.orange),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

/// Square-cornered action with a sliding arrow on hover and a focus outline.
class _SquareButton extends StatefulWidget {
  const _SquareButton({
    required this.label,
    required this.background,
    required this.hoverBackground,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color hoverBackground;
  final Color foreground;
  final VoidCallback onTap;

  @override
  State<_SquareButton> createState() => _SquareButtonState();
}

class _SquareButtonState extends State<_SquareButton> {
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
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          decoration: BoxDecoration(
            color: _hover ? widget.hoverBackground : widget.background,
            border: Border.all(
              color: _focus ? widget.foreground : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: _baloo(
                  18,
                  weight: FontWeight.w700,
                  color: widget.foreground,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                offset: Offset(_hover ? 0.25 : 0, 0),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: widget.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
