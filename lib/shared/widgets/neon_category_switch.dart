// lib/shared/widgets/neon_category_switch.dart
import 'package:flutter/material.dart';

class NeonCategorySwitch extends StatelessWidget {
  final String title;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NeonCategorySwitch({
    super.key,
    required this.title,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Marge standardisée pour tous tes lobbys
      margin: const EdgeInsets.only(bottom: 15), 
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF050515), // Ton fond Dark
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: value ? color : Colors.white10)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title, 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: value ? Colors.white : Colors.white38
            )
          ),
          Switch(
            value: value, 
            activeTrackColor: color, 
            activeThumbColor: Colors.white, 
            onChanged: onChanged
          ),
        ],
      ),
    );
  }
}