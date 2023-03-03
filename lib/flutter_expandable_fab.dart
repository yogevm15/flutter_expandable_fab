library flutter_expandable_fab;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

// Inspired by this article.
// https://docs.flutter.dev/cookbook/effects/expandable-fab

/// The type of behavior of this widget.
enum ExpandableFabType { fan, up, left }

/// The size of the expanded FAB.
enum ExpandableFabSize { small, regular }

/// Style of the overlay.
@immutable
class ExpandableFabOverlayStyle {
  ExpandableFabOverlayStyle({
    this.color,
    this.blur,
  }) {
    assert(color == null || blur == null);
    assert(color != null || blur != null);
  }

  /// The color to paint behind the Fab.
  final Color? color;

  /// The strength of the blur behind Fab.
  final double? blur;
}

/// Style of the close button.
@immutable
class ExpandableFabCloseButtonStyle {
  const ExpandableFabCloseButtonStyle({
    this.child = const Icon(Icons.close),
    this.foregroundColor,
    this.backgroundColor,
  });

  /// The widget below the close button widget in the tree.
  final Widget child;

  /// The default foreground color for icons and text within the button.
  final Color? foregroundColor;

  /// The button's background color.
  final Color? backgroundColor;
}

/// Fab button that can show/hide multiple action buttons with animation.
@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    Key? key,
    this.distance = 100,
    this.duration = const Duration(milliseconds: 250),
    this.fanAngle = 90,
    this.initialOpen = false,
    this.type = ExpandableFabType.fan,
    this.collapsedFabSize = ExpandableFabSize.regular,
    this.expandedFabSize = ExpandableFabSize.small,
    this.closeButtonStyle = const ExpandableFabCloseButtonStyle(),
    this.foregroundColor,
    this.backgroundColor,
    this.child = const Icon(Icons.menu),
    this.childrenOffset = const Offset(4, 4),
    required this.children,
    this.onOpen,
    this.afterOpen,
    this.onClose,
    this.afterClose,
    this.overlayStyle,
    this.openButtonHeroTag,
    this.closeButtonHeroTag,
  }) : super(key: key);

  /// Distance from children.
  final double distance;

  /// Animation duration.
  final Duration duration;

  /// Angle of opening when fan type.
  final double fanAngle;

  /// Open at initial display.
  final bool initialOpen;

  /// The type of behavior of this widget.
  final ExpandableFabType type;

  /// The size of the collapsed FAB.
  final ExpandableFabSize collapsedFabSize;

  /// The size of the expanded FAB.
  final ExpandableFabSize expandedFabSize;

  /// Style of the close button.
  final ExpandableFabCloseButtonStyle closeButtonStyle;

  /// The widget below this widget in the tree.
  final Widget child;

  /// For positioning of children widgets.
  final Offset childrenOffset;

  /// The widgets below this widget in the tree.
  final List<Widget> children;

  /// The default foreground color for icons and text within the button.
  final Color? foregroundColor;

  /// The button's background color.
  final Color? backgroundColor;

  /// Will be called before opening the menu.
  final VoidCallback? onOpen;

  /// Will be called after opening the menu.
  final VoidCallback? afterOpen;

  /// Will be called before the menu closes.
  final VoidCallback? onClose;

  /// Will be called after the menu closes.
  final VoidCallback? afterClose;

  /// Provides the style for overlay. No overlay when null.
  final ExpandableFabOverlayStyle? overlayStyle;

  /// The tag to apply to the open button's [Hero] widget.
  final Object? openButtonHeroTag;

  /// The tag to apply to the close button's [Hero] widget.
  final Object? closeButtonHeroTag;

  @override
  State<ExpandableFab> createState() => ExpandableFabState();
}

class ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  /// Returns whether the menu is open
  bool get isOpen => _open;

  /// Display or hide the menu.
  void toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        widget.onOpen?.call();
        _controller.forward().then((value) {
          widget.afterOpen?.call();
        });
      } else {
        widget.onClose?.call();
        _controller.reverse().then((value) {
          widget.afterClose?.call();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: widget.duration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  _buildButtons();
  }

  Widget _buildButtons() {
    final blur = widget.overlayStyle?.blur;
    final overlayColor = widget.overlayStyle?.color;
    return GestureDetector(
      onTap: () => toggle(),
      child: Stack(
        children: [
          if (blur != null)
            IgnorePointer(
              ignoring: !_open,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: _open ? blur : 0.0),
                duration: widget.duration,
                curve: Curves.easeInOut,
                builder: (_, value, child) {
                  if (value < 0.001) {
                    return child!;
                  }
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                    child: child,
                  );
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          if (overlayColor != null)
            IgnorePointer(
              ignoring: !_open,
              child: AnimatedOpacity(
                duration: widget.duration,
                opacity: _open ? 1 : 0,
                curve: Curves.easeInOut,
                child: Container(
                  color: overlayColor,
                ),
              ),
            ),
          Stack(
              children: [
                _buildTapToCloseFab(),
                ..._buildExpandingActionButtons(),
                _buildTapToOpenFab(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    final style = widget.closeButtonStyle;
    switch (widget.expandedFabSize) {
      case ExpandableFabSize.small:
        return FloatingActionButton.small(
          heroTag: widget.closeButtonHeroTag,
          foregroundColor: style.foregroundColor,
          backgroundColor: style.backgroundColor,
          onPressed: toggle,
          child: style.child,
        );
      case ExpandableFabSize.regular:
        return FloatingActionButton(
          heroTag: widget.closeButtonHeroTag,
          foregroundColor: style.foregroundColor,
          backgroundColor: style.backgroundColor,
          onPressed: toggle,
          child: style.child,
        );
    }
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = widget.fanAngle / (count - 1);
    final addedDistance = widget.expandedFabSize == ExpandableFabSize.regular ? 8 : 0;
    for (var i = 0; i < count; i++) {
      final double dir, dist;
      switch (widget.type) {
        case ExpandableFabType.fan:
          dir = step * i;
          dist = widget.distance + addedDistance;
          break;
        case ExpandableFabType.up:
          dir = 90;
          dist = widget.distance * (i + 1) + addedDistance;
          break;
        case ExpandableFabType.left:
          dir = 0;
          dist = widget.distance * (i + 1) + addedDistance;
          break;
      }
      children.add(
        _ExpandingActionButton(
          directionInDegrees: dir + (90 - widget.fanAngle) / 2,
          maxDistance: dist,
          progress: _expandAnimation,
          offset: widget.childrenOffset,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    final duration = widget.duration;
    final transformValues = widget.expandedFabSize == ExpandableFabSize.regular ? 1.0 : 0.715;

    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? transformValues : 1.0,
          _open ? transformValues : 1.0,
          1.0,
        ),
        duration: duration,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: duration,
          child: widget.collapsedFabSize == ExpandableFabSize.regular
              ? FloatingActionButton(
            heroTag: widget.openButtonHeroTag,
            foregroundColor: widget.foregroundColor,
            backgroundColor: widget.backgroundColor,
            onPressed: toggle,
            child: AnimatedRotation(
              duration: duration,
              turns: _open ? -0.5 : 0,
              child: widget.child,
            ),
          )
              : FloatingActionButton.small(
            heroTag: widget.openButtonHeroTag,
            foregroundColor: widget.foregroundColor,
            backgroundColor: widget.backgroundColor,
            onPressed: toggle,
            child: AnimatedRotation(
              duration: duration,
              turns: _open ? -0.5 : 0,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.offset,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final pos = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: pos.dx,
          bottom: pos.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}
