import 'package:flutter/material.dart';

/// Wrapper yang membuat child muncul dengan animasi fade + slide ke atas.
/// Gunakan di setiap item ListView.builder untuk efek muncul satu-per-satu.
class SmoothListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const SmoothListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 40),
  });

  @override
  State<SmoothListItem> createState() => _SmoothListItemState();
}

class _SmoothListItemState extends State<SmoothListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Stagger: setiap item delay sedikit lebih lama
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer loading placeholder — kotak abu-abu bergerak ke kanan.
/// Ganti CircularProgressIndicator di list kosong/loading dengan ini.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(-0.5 + 2.0 * _ctrl.value, 0),
              colors: [
                cs.surfaceContainerHighest,
                cs.surfaceContainerHigh,
                cs.surfaceContainerHighest,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer card placeholder untuk loading state list
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const ShimmerBox(width: 120, height: 18),
              const Spacer(),
              ShimmerBox(width: 80, height: 28, borderRadius: BorderRadius.circular(16)),
            ]),
            const SizedBox(height: 10),
            ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(6)),
            const SizedBox(height: 6),
            ShimmerBox(width: 200, height: 14, borderRadius: BorderRadius.circular(6)),
            const SizedBox(height: 6),
            ShimmerBox(width: 150, height: 14, borderRadius: BorderRadius.circular(6)),
          ],
        ),
      ),
    );
  }
}
