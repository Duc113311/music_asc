import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'tour_controller.dart';

/// Marks the widget the tour highlights for [id]. Registers a `GlobalKey` with
/// [TourController] while mounted; a no-op when the controller is not
/// registered (widget tests).
class TourAnchor extends StatefulWidget {
  const TourAnchor({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  State<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends State<TourAnchor> {
  final GlobalKey _key = GlobalKey();

  TourController? get _controller =>
      Get.isRegistered<TourController>() ? Get.find<TourController>() : null;

  @override
  void initState() {
    super.initState();
    _controller?.registerAnchor(widget.id, _key);
  }

  @override
  void dispose() {
    _controller?.unregisterAnchor(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
