import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A point of light that eases toward the user's pointer and, when the
/// pointer is idle or absent (touch screens), wanders slowly on its own.
class DriftingLight {
  DriftingLight({this.followRate = 6.0, this.idleAfter = 2.5});

  final double followRate;
  final double idleAfter;

  Offset? position;
  Offset? _lastPointer;
  double _idle = double.infinity;
  double _t = 0;

  /// Whether the light is currently following the pointer.
  bool get isFollowing => _idle < idleAfter;

  Offset update(Size size, double dt, Offset? pointer, {double motion = 1}) {
    _t += dt * motion;
    _idle += dt;
    if (pointer != null && pointer != _lastPointer) {
      _idle = 0;
      _lastPointer = pointer;
    }
    if (pointer == null) _lastPointer = null;

    final wander = Offset(
      size.width *
          (0.5 + 0.30 * math.sin(_t * 0.21) + 0.08 * math.sin(_t * 0.67)),
      size.height *
          (0.42 + 0.20 * math.cos(_t * 0.29) + 0.06 * math.sin(_t * 0.91)),
    );
    final following = isFollowing && _lastPointer != null;
    final goal = following ? _lastPointer! : wander;
    final rate = following ? followRate : 0.9;
    position =
        position == null
            ? goal
            : Offset.lerp(position, goal, 1 - math.exp(-rate * dt));
    return position!;
  }
}

/// Base state for the hero backgrounds: drives a frame ticker, exposes a
/// monotonic clock and a repaint notifier, and respects "reduce motion".
abstract class HeroTickerState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  /// Notifies painters to repaint without rebuilding widgets.
  final ValueNotifier<int> repaint = ValueNotifier<int>(0);

  /// Seconds of ambient motion since the background appeared.
  double elapsed = 0;

  /// 1.0 normally; much lower when the OS asks for reduced motion.
  double motion = 1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    motion = MediaQuery.of(context).disableAnimations ? 0.15 : 1;
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = now;
    if (!_onScreen()) return; // Don't animate or repaint while scrolled away.
    elapsed += dt * motion;
    onTick(dt);
    repaint.value++;
  }

  bool _onScreen() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return true;
    final top = box.localToGlobal(Offset.zero).dy;
    final viewHeight = MediaQuery.sizeOf(context).height;
    return top + box.size.height > 0 && top < viewHeight;
  }

  /// Called every frame with the real (unscaled) frame delta in seconds.
  void onTick(double dt);

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    super.dispose();
  }
}
