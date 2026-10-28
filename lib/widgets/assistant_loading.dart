import 'package:flutter/material.dart';

/// Quiet, accessible progress indicator without a spinning loader.
class AssistantLoading extends StatefulWidget {
  final String label;
  const AssistantLoading({super.key, required this.label});
  @override
  State<AssistantLoading> createState() => _AssistantLoadingState();
}

class _AssistantLoadingState extends State<AssistantLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1400));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
      _pulse.value = .5;
    } else {
      _pulse.repeat(reverse: true);
    }
  }
  @override
  void dispose() { _pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(liveRegion: true, label: widget.label,
      child: ExcludeSemantics(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          FadeTransition(opacity: Tween<double>(begin: .3, end: .85).animate(_pulse),
            child: Icon(Icons.auto_awesome_outlined, size: 18, color: color)),
          const SizedBox(width: 10),
          Flexible(child: Text(widget.label,
            style: TextStyle(fontSize: 12, height: 1.5, color: color))),
        ]))));
  }
}
