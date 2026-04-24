import 'package:flutter/material.dart';

class AppBottomSheet {
  static void show({
    required BuildContext context,
    required Widget child,
    String title = "",
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to expand with keyboard
      backgroundColor: Colors.transparent, // We use a custom container for styling
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Moves sheet above keyboard
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A), // Matches our Deep Charcoal theme
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(title, style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                )),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}