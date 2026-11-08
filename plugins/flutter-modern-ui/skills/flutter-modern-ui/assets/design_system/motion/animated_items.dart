import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../context_ext.dart';
import '../tokens.dart';
import 'entrance.dart';

/// A sliver list (or grid, with [gridDelegate]) that animates changes by
/// diffing [items] against the previous build, matched by [keyOf]:
///
/// - removed items shrink and fade (lists) or fade and scale down (grids),
///   and their neighbours slide into place;
/// - inserted items grow and fade in;
/// - kept items keep their State (an expanded tile stays expanded, even when
///   an insert above it shifts its index);
/// - a changed order (new sort) or the first non-empty data replays the
///   staggered entrance;
/// - only items built in the first frame get the entrance, not items that
///   scroll into view later.
///
/// Use inside a CustomScrollView. [keyOf] must return unique, stable ids.
/// Durations become zero under reduced motion.
class AnimatedItems<T> extends StatefulWidget {
  const AnimatedItems({
    super.key,
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    this.gridDelegate,
    this.spacing = 0,
    this.entrance = true,
  });

  final List<T> items;
  final Object Function(T item) keyOf;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Grid mode when set.
  final SliverGridDelegate? gridDelegate;

  /// Gap below each list item; it animates with the item. Grids use the
  /// delegate's spacing.
  final double spacing;

  /// Staggered entrance on first data and on reorder.
  final bool entrance;

  @override
  State<AnimatedItems<T>> createState() => _AnimatedItemsState<T>();
}

class _AnimatedItemsState<T> extends State<AnimatedItems<T>> {
  final List<T> _items = <T>[];
  final Map<Object, int> _indexOf = <Object, int>{};
  GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();
  GlobalKey<SliverAnimatedGridState> _gridKey = GlobalKey<SliverAnimatedGridState>();
  bool _entranceOpen = false;
  Duration _duration = AppDurations.medium;

  bool get _isGrid => widget.gridDelegate != null;

  @override
  void initState() {
    super.initState();
    _reset(widget.items, entrance: widget.entrance);
  }

  @override
  void didUpdateWidget(AnimatedItems<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.gridDelegate == null) != (widget.gridDelegate == null)) {
      _reset(widget.items, entrance: false);
    } else {
      _diff(widget.items);
    }
  }

  /// Rebuilds the sliver from scratch (new key), optionally with the entrance.
  void _reset(List<T> items, {required bool entrance}) {
    _items
      ..clear()
      ..addAll(items);
    _reindex();
    _listKey = GlobalKey<SliverAnimatedListState>();
    _gridKey = GlobalKey<SliverAnimatedGridState>();
    _entranceOpen = entrance;
    if (entrance) {
      // Items built in this frame animate in; items built later don't.
      WidgetsBinding.instance.addPostFrameCallback((_) => _entranceOpen = false);
    }
  }

  void _diff(List<T> next) {
    final keyOf = widget.keyOf;
    final nextKeys = <Object>[for (final item in next) keyOf(item)];
    final nextSet = nextKeys.toSet();
    assert(nextSet.length == nextKeys.length, 'AnimatedItems: keyOf must return unique keys.');

    // First data after an empty list: entrance instead of a burst of inserts.
    // Still empty: nothing to do (and removals still animating keep going).
    if (_items.isEmpty) {
      if (next.isNotEmpty) _reset(next, entrance: widget.entrance);
      return;
    }

    // 1. Kept items must keep their relative order; otherwise rebuild with
    //    the entrance. Checked before any removal is started, so no
    //    animation runs on a sliver that is about to be replaced.
    final kept = <Object>[
      for (final item in _items)
        if (nextSet.contains(keyOf(item))) keyOf(item),
    ];
    final keptSet = kept.toSet();
    final nextKept = <Object>[for (final key in nextKeys) if (keptSet.contains(key)) key];
    if (!listEquals(kept, nextKept)) {
      _reset(next, entrance: widget.entrance);
      return;
    }

    // 2. Removals, from the end so earlier indexes stay valid.
    for (var i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      if (!keptSet.contains(keyOf(item))) {
        _items.removeAt(i);
        _remove(i, item);
      }
    }

    // 3. Inserts, in ascending order: before index i everything already
    //    matches `next`, so i is the right slot.
    for (var i = 0; i < next.length; i++) {
      if (keptSet.contains(nextKeys[i])) continue;
      _items.insert(i, next[i]);
      _insert(i);
    }

    // 4. Same keys, fresh data.
    for (var i = 0; i < next.length; i++) {
      _items[i] = next[i];
    }
    _reindex();
  }

  void _reindex() {
    _indexOf.clear();
    for (var i = 0; i < _items.length; i++) {
      _indexOf[widget.keyOf(_items[i])] = i;
    }
  }

  void _insert(int index) {
    if (_isGrid) {
      _gridKey.currentState?.insertItem(index, duration: _duration);
    } else {
      _listKey.currentState?.insertItem(index, duration: _duration);
    }
  }

  void _remove(int index, T item) {
    Widget removed(BuildContext context, Animation<double> animation) => _wrap(context, item, animation, index);
    if (_isGrid) {
      _gridKey.currentState?.removeItem(index, removed, duration: _duration);
    } else {
      _listKey.currentState?.removeItem(index, removed, duration: _duration);
    }
  }

  /// Maps a child's key to its current index so kept items keep their State.
  int? _findIndex(Key key) => key is ValueKey<Object> ? _indexOf[key.value] : null;

  Widget _build(BuildContext context, int index, Animation<double> animation) =>
      _wrap(context, _items[index], animation, index);

  /// Same widget shape for present and removed items, keyed by id, so a
  /// removed item keeps its State while it animates out.
  Widget _wrap(BuildContext context, T item, Animation<double> animation, int index) {
    final child = Padding(
      padding: EdgeInsets.only(bottom: _isGrid ? 0 : widget.spacing),
      child: widget.itemBuilder(context, item),
    );

    final Widget transition;
    if (_isGrid) {
      final t = animation.drive(CurveTween(curve: AppCurves.standard));
      transition = FadeTransition(
        opacity: t,
        child: ScaleTransition(scale: t.drive(Tween<double>(begin: 0.95, end: 1)), child: child),
      );
    } else {
      final t = animation.drive(CurveTween(curve: AppCurves.emphasized));
      transition = SizeTransition(
        sizeFactor: t,
        alignment: AlignmentDirectional.topStart,
        child: FadeTransition(opacity: t, child: child),
      );
    }

    return KeyedSubtree(
      key: ValueKey<Object>(widget.keyOf(item)),
      child: Entrance(index: index, animate: _entranceOpen, child: transition),
    );
  }

  @override
  Widget build(BuildContext context) {
    _duration = context.motion(AppDurations.medium);
    final gridDelegate = widget.gridDelegate;

    if (gridDelegate != null) {
      return SliverAnimatedGrid(
        key: _gridKey,
        gridDelegate: gridDelegate,
        initialItemCount: _items.length,
        findChildIndexCallback: _findIndex,
        itemBuilder: _build,
      );
    }
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      findChildIndexCallback: _findIndex,
      itemBuilder: _build,
    );
  }
}
