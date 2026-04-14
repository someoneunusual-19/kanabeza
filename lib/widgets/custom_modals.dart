import 'package:flutter/material.dart';

class CustomModals {
  /// Beautiful Animated Modal for Kanabeza
  static Future<T?> showKanabezaModal<T>({
    required BuildContext context,
    required Widget child,
    double heightFactor = 0.65,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation1, animation2) {
        return const SizedBox.shrink(); // Required for pageBuilder
      },
      transitionBuilder: (context, animation, secondaryAnimation, childWidget) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return Transform.scale(
          scale: Tween<double>(begin: 0.75, end: 1.0).evaluate(curvedAnimation),
          child: Opacity(
            opacity: animation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                height: MediaQuery.of(context).size.height * heightFactor,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // Supports light & dark mode
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightBlue.withOpacity(0.25),
                      blurRadius: 30,
                      spreadRadius: 8,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: child,   // ← This is your passed widget
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Success Modal with animation
  static void showSuccessModal(
    BuildContext context,
    String message, {
    VoidCallback? onDone,
  }) {
    showKanabezaModal(
      context: context,
      heightFactor: 0.42,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF4CAF50),
              size: 85,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDone?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF81D4FA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}