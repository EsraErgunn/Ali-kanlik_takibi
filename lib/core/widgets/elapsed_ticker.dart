import 'dart:async';
import 'package:flutter/material.dart';

String formatElapsed(Duration d) {
  final days = d.inDays;
  final h = d.inHours % 24;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${days}g ${two(h)}s ${two(m)}d ${two(s)}sn';
}

class ElapsedTicker extends StatefulWidget {
  const ElapsedTicker({
    super.key,
    required this.since,
    this.style,
  });

  final DateTime since;
  final TextStyle? style;

  @override
  State<ElapsedTicker> createState() => _ElapsedTickerState();
}

class _ElapsedTickerState extends State<ElapsedTicker> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(widget.since);
    final safeDiff = diff.isNegative ? Duration.zero : diff;

    return Text(
      formatElapsed(safeDiff),
      style: (widget.style ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
