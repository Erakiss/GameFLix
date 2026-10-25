// lib/shared/widgets/neon_category_switch.dart
import 'package:flutter/material.dart';

class NeonCategorySwitch extends StatelessWidget {
  final String title;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLocked;
  final VoidCallback? onLockedTap;

  const NeonCategorySwitch({
    super.key,
    required this.title,
    required this.color,
    required this.value,
    required this.onChanged,
    this.isLocked = false,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? onLockedTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Marge standardisée pour tous tes lobbys
        margin: const EdgeInsets.only(bottom: 15), 
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF050515), // Ton fond Dark
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(
            color: isLocked
                ? Colors.redAccent.withValues(alpha: 0.5)
                : (value ? color : Colors.white10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: isLocked
                        ? Colors.white54
                        : (value ? Colors.white : Colors.white38),
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.redAccent, size: 12),
                        SizedBox(width: 4),
                        Text(
                          "SPICY",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (isLocked)
              IconButton(
                icon: const Icon(Icons.lock_outline_rounded, color: Colors.redAccent, size: 24),
                onPressed: onLockedTap,
              )
            else
              Switch(
                value: value, 
                activeTrackColor: color, 
                activeThumbColor: Colors.white, 
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }
}
