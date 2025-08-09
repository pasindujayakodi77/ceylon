import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final String label; // e.g., "Verified"
  const VerifiedBadge({
    super.key,
    this.size = 18,
    this.label = 'Verified',
    required String businessId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: size, color: const Color(0xFF1E88E5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
