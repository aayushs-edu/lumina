import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuminaNavbar extends StatelessWidget {
  final String currentPage;

  const LuminaNavbar({Key? key, this.currentPage = ''}) : super(key: key);

  static const _orange = Color(0xFFFF6600);
  static const _ink = Color(0xFF2A1A16);
  static const _rule = Color(0xFFEADBD2);

  void _go(BuildContext context, String page, String route) {
    if (currentPage != page) Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 640;

    final links = Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 4 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _rule),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavLink(
            label: 'Explore',
            active: currentPage == 'explore',
            compact: narrow,
            onTap: () => _go(context, 'explore', '/explore'),
          ),
          _NavLink(
            label: 'Post a Story',
            active: currentPage == 'postStory',
            compact: narrow,
            onTap: () => _go(context, 'postStory', '/postStory'),
          ),
          _NavLink(
            label: 'LuminaLens',
            active: currentPage == 'luminaLens',
            compact: narrow,
            onTap: () => _go(context, 'luminaLens', '/luminaLens'),
          ),
        ],
      ),
    );

    final wordmark = _NavLink(
      label: 'lumina',
      wordmark: true,
      active: false,
      compact: narrow,
      onTap: () => _go(context, 'home', '/'),
    );

    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AppBar(
        toolbarHeight: 80,
        // Transparent over the hero; a warm-white bar once content scrolls
        // underneath, so the wordmark and links never sit on busy content.
        backgroundColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.scrolledUnder)
                  ? const Color(0xF2FFFCFA)
                  : Colors.transparent,
        ),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: narrow ? 12 : 16,
        title:
            narrow
                ? Row(children: [wordmark, const Spacer(), links])
                : Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(child: links),
                    Align(alignment: Alignment.centerLeft, child: wordmark),
                  ],
                ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.compact = false,
    this.wordmark = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;
  final bool wordmark;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.wordmark || widget.active || _hover
            ? LuminaNavbar._orange
            : LuminaNavbar._ink;
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
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.wordmark ? 4 : (widget.compact ? 8 : 14),
            vertical: 6,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    widget.active
                        ? LuminaNavbar._orange
                        : (_focus ? LuminaNavbar._ink : Colors.transparent),
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 15, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: GoogleFonts.baloo2(
                  fontSize:
                      widget.wordmark
                          ? (widget.compact ? 20 : 22)
                          : (widget.compact ? 14 : 15),
                  fontWeight:
                      widget.wordmark ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
