import 'package:flutter/material.dart';

/// Page route builder dengan animasi slide + fade yang halus.
/// Gunakan: Navigator.push(context, SmoothRoute(page: TargetPage()));
class SmoothRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Extension pada Navigator untuk push dengan transisi halus
extension SmoothNav on NavigatorState {
  Future<T?> smoothPush<T>(Widget page) {
    return push<T>(SmoothRoute<T>(page: page));
  }

  Future<T?> smoothPushReplace<T>(Widget page) {
    return pushReplacement<T, void>(SmoothRoute<T>(page: page));
  }
}
