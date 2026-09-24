import 'package:flutter/material.dart';

import 'colors.dart';

/// Project cover photos shipped inside the app bundle so a chantier always
/// shows a real image — even fully offline, which is the normal case on site.
const kProjectCovers = <String>[
  'assets/images/covers/cover-01.jpg',
  'assets/images/covers/cover-02.jpg',
  'assets/images/covers/cover-03.jpg',
  'assets/images/covers/cover-04.jpg',
];

/// Brand mark used as a last-resort visual when a cover cannot be resolved.
const kBrandIcon =
    'assets/branding/Alliya-Kalenda-app-icon-bigA-calendar-1024-rounded.png';

/// Picks a stable cover for [seed] so the same project keeps the same photo
/// across restarts, without needing a stored URL.
String coverForSeed(String seed) {
  if (seed.isEmpty) return kProjectCovers.first;
  final hash = seed.codeUnits.fold<int>(
    7,
    (sum, unit) => (sum * 31 + unit) & 0x7fffffff,
  );
  return kProjectCovers[hash % kProjectCovers.length];
}

/// Renders a project cover — bundled asset or remote URL — with an animated
/// skeleton while it loads and a branded placeholder if it cannot be shown.
class ProjectCover extends StatelessWidget {
  const ProjectCover({
    required this.source,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final String source;
  final BoxFit fit;
  final Alignment alignment;

  bool get _isRemote => source.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const ProjectCoverFallback();
    if (_isRemote) {
      return Image.network(
        source,
        fit: fit,
        alignment: alignment,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const CoverSkeleton(),
        errorBuilder: (context, error, stackTrace) =>
            const ProjectCoverFallback(),
      );
    }
    return Image.asset(
      source,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) =>
          const ProjectCoverFallback(),
    );
  }
}

/// Soft pulsing placeholder shown while a remote cover downloads.
class CoverSkeleton extends StatefulWidget {
  const CoverSkeleton({super.key});

  @override
  State<CoverSkeleton> createState() => _CoverSkeletonState();
}

class _CoverSkeletonState extends State<CoverSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => ColoredBox(
      color: Color.lerp(
        kSurfaceHigh,
        const Color(0xffd3deea),
        _controller.value,
      )!,
      child: const Center(
        child: Icon(Icons.photo_camera_back_outlined, size: 20, color: kNavy),
      ),
    ),
  );
}

/// On-brand placeholder: deep navy wash with the Alliya Kelenda mark.
class ProjectCoverFallback extends StatelessWidget {
  const ProjectCoverFallback({this.icon, super.key});

  final IconData? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [kNavy, Color(0xff17385f)],
      ),
    ),
    child: Center(
      child: icon != null
          ? Icon(icon, color: Colors.white24, size: 34)
          : Opacity(
              opacity: .16,
              child: Image.asset(kBrandIcon, width: 74, fit: BoxFit.contain),
            ),
    ),
  );
}
