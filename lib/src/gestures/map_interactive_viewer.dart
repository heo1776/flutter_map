import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/controller/internal_map_controller.dart';

typedef ChildBuilder = Widget Function(
  BuildContext context,
  MapOptions options,
  MapCamera camera,
);

class MapInteractiveViewer extends StatefulWidget {
  final ChildBuilder builder;
  final InternalMapController controller;

  const MapInteractiveViewer({
    super.key,
    required this.builder,
    required this.controller,
  });

  @override
  State<MapInteractiveViewer> createState() => MapInteractiveViewerState();
}

class MapInteractiveViewerState extends State<MapInteractiveViewer>
    with TickerProviderStateMixin {
  TapGesture? _tap;
  LongPressGesture? _longPress;
  SecondaryTapGesture? _secondaryTap;
  SecondaryLongPressGesture? _secondaryLongPress;
  TertiaryTapGesture? _tertiaryTap;
  TertiaryLongPressGesture? _tertiaryLongPress;
  DoubleTapGesture? _doubleTap;
  ScrollWheelZoomGesture? _scrollWheelZoom;
  MultiInputGesture? _multiInput;
  DragGesture? _drag;
  DoubleTapDragZoomGesture? _doubleTapDragZoom;
  CtrlDragRotateGesture? _ctrlDragRotate;

  MapCamera get _camera => widget.controller.camera;

  MapOptions get _options => widget.controller.options;

  InteractionOptions get _interactionOptions => _options.interactionOptions;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(reload);

    // callback gestures for the application
    if (_options.onTap != null) {
      _tap = TapGesture(controller: widget.controller);
    }
    if (_options.onLongPress != null) {
      _longPress = LongPressGesture(controller: widget.controller);
    }
    if (_options.onSecondaryTap != null) {
      _secondaryTap = SecondaryTapGesture(controller: widget.controller);
    }
    if (_options.onSecondaryLongPress != null) {
      _secondaryLongPress =
          SecondaryLongPressGesture(controller: widget.controller);
    }
    if (_options.onTertiaryTap != null) {
      _tertiaryTap = TertiaryTapGesture(controller: widget.controller);
    }
    if (_options.onTertiaryLongPress != null) {
      _tertiaryLongPress =
          TertiaryLongPressGesture(controller: widget.controller);
    }
    // gestures that change the map camera
    updateGestures(_interactionOptions.flags);
  }

  @override
  void dispose() {
    widget.controller.removeListener(reload);
    super.dispose();
  }

  void reload() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        // mouse scroll wheel
        if (event is PointerScrollEvent) {
          _scrollWheelZoom?.submit(event);
        }
      },
      child: GestureDetector(
        onTapDown: _tap?.setDetails,
        onTapCancel: _tap?.reset,
        onTap: _tap?.submit,

        onLongPressStart: _longPress?.submit,

        onSecondaryTapDown: _secondaryTap?.setDetails,
        onSecondaryTapCancel: _secondaryTap?.reset,
        onSecondaryTap: _secondaryTap?.submit,

        onSecondaryLongPressStart: _secondaryLongPress?.submit,

        onDoubleTapDown: (details) {
          _doubleTapDragZoom?.isActive = true;
          _doubleTap?.setDetails(details);
        },
        onDoubleTapCancel: () {
          _doubleTapDragZoom?.isActive = true;
          _doubleTap?.reset();
        },
        onDoubleTap: () {
          _doubleTapDragZoom?.isActive = false;
          _doubleTap?.submit();
        },

        onTertiaryTapDown: _tertiaryTap?.setDetails,
        onTertiaryTapCancel: _tertiaryTap?.reset,
        onTertiaryTapUp: _tertiaryTap?.submit,

        onTertiaryLongPressStart: _tertiaryLongPress?.submit,

        // pan and scale, scale is a superset of the pan gesture
        onScaleStart: (details) {
          if (_ctrlDragRotate?.ctrlPressed ?? false) {
            _ctrlDragRotate!.start();
          } else if (_doubleTapDragZoom?.isActive ?? false) {
            _doubleTapDragZoom!.start(details);
          } else {
            _multiInput?.start(details);
          }
        },
        onScaleUpdate: (details) {
          if (_ctrlDragRotate?.ctrlPressed ?? false) {
            _ctrlDragRotate!.update(details);
          } else if (_doubleTapDragZoom?.isActive ?? false) {
            _doubleTapDragZoom!.update(details);
          } else {
            _multiInput?.update(details);
          }
        },
        onScaleEnd: (details) {
          if (_ctrlDragRotate?.ctrlPressed ?? false) {
            _ctrlDragRotate!.end();
          } else if (_doubleTapDragZoom?.isActive ?? false) {
            _doubleTapDragZoom!.isActive = false;
            _doubleTapDragZoom!.end(details);
          } else {
            _multiInput?.end(details);
          }
        },

        child: widget.builder(context, _options, _camera),
      ),
    );
  }

  /// Used by the internal map controller to update interaction gestures
  void updateGestures(int flags) {
    _multiInput = MultiInputGesture(controller: widget.controller);

    if (InteractiveFlag.hasDrag(flags)) {
      _drag = DragGesture(controller: widget.controller);
    } else {
      _drag?.end();
      _drag = null;
    }

    if (InteractiveFlag.hasDoubleTapZoom(flags)) {
      _doubleTap = DoubleTapGesture(controller: widget.controller);
    } else {
      _doubleTap = null;
    }

    if (InteractiveFlag.hasScrollWheelZoom(flags)) {
      _scrollWheelZoom = ScrollWheelZoomGesture(controller: widget.controller);
    } else {
      _scrollWheelZoom = null;
    }

    if (InteractiveFlag.hasCtrlDragRotate(flags)) {
      _ctrlDragRotate = CtrlDragRotateGesture(controller: widget.controller);
    } else {
      _ctrlDragRotate = null;
    }

    if (InteractiveFlag.hasDoubleTapDragZoom(flags)) {
      _doubleTapDragZoom =
          DoubleTapDragZoomGesture(controller: widget.controller);
    } else {
      _doubleTapDragZoom = null;
    }
  }

  /// Used by the internal map controller
  void interruptAnimatedMovement(MapEventMove event) {
    // TODO implement
  }
}
