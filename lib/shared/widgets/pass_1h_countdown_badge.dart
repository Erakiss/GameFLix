// lib/shared/widgets/pass_1h_countdown_badge.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_shared.dart';
import 'package:gameflix/state/access_control_provider.dart';

/// Badge néon dynamique affichant le compte à rebours du Pass Soirée 1H.
/// Se met à jour chaque seconde et disparaît automatiquement à l'expiration.
class Pass1hCountdownBadge extends StatefulWidget {
  const Pass1hCountdownBadge({super.key});

  @override
  State<Pass1hCountdownBadge> createState() => _Pass1hCountdownBadgeState();
}

class _Pass1hCountdownBadgeState extends State<Pass1hCountdownBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessCtrl = context.watch<AccessControlProvider>();
    final strings = AppStrings.of(context);

    if (!accessCtrl.isPass1hActive) {
      return const SizedBox.shrink();
    }

    final remaining = accessCtrl.pass1hRemainingTime;
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amberAccent, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.amberAccent.withValues(alpha: 0.35),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.amberAccent,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            strings.pass1hCountdownLabel(minutes, seconds),
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
