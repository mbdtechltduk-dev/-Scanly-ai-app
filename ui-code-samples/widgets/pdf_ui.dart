import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// PDF Pro brand mark: a document with a "PDF" label, scan brackets and a camera lens.
/// Drawn in code so it stays sharp at every size and needs no image assets.
class PdfProLogo extends StatelessWidget {
  const PdfProLogo({super.key, this.size = 64, this.onRed = false});

  final double size;

  /// When true the mark is drawn for a red background (white page, no red tile).
  final bool onRed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PDF Pro logo',
      image: true,
      child: SizedBox(width: size, height: size, child: CustomPaint(painter: _LogoPainter(onRed: onRed))),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.onRed});

  final bool onRed;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    if (!onRed) {
      final tile = RRect.fromRectAndRadius(Offset.zero & Size(s, s), Radius.circular(s * 0.23));
      canvas.drawRRect(
        tile,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF5147), Color(0xFFE5261C)],
          ).createShader(Offset.zero & Size(s, s)),
      );
    }
    final white = Paint()..color = Colors.white;
    // Scan brackets.
    final bracket = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;
    final m = s * 0.14;
    final l = s * 0.15;
    for (final c in [Offset(m, m), Offset(s - m, m), Offset(s - m, s - m), Offset(m, s - m)]) {
      final dx = c.dx < s / 2 ? l : -l;
      final dy = c.dy < s / 2 ? l : -l;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + dy)
          ..lineTo(c.dx, c.dy)
          ..lineTo(c.dx + dx, c.dy),
        bracket,
      );
    }
    // Page with folded corner.
    final page = Rect.fromLTWH(s * 0.27, s * 0.22, s * 0.44, s * 0.56);
    final fold = s * 0.12;
    final pagePath = Path()
      ..moveTo(page.left + s * 0.03, page.top)
      ..lineTo(page.right - fold, page.top)
      ..lineTo(page.right, page.top + fold)
      ..lineTo(page.right, page.bottom - s * 0.03)
      ..quadraticBezierTo(page.right, page.bottom, page.right - s * 0.03, page.bottom)
      ..lineTo(page.left + s * 0.03, page.bottom)
      ..quadraticBezierTo(page.left, page.bottom, page.left, page.bottom - s * 0.03)
      ..lineTo(page.left, page.top + s * 0.03)
      ..quadraticBezierTo(page.left, page.top, page.left + s * 0.03, page.top)
      ..close();
    canvas.drawShadow(pagePath, AppColors.navy, s * 0.02, false);
    canvas.drawPath(pagePath, white);
    canvas.drawPath(
      Path()
        ..moveTo(page.right - fold, page.top)
        ..lineTo(page.right - fold, page.top + fold)
        ..lineTo(page.right, page.top + fold)
        ..close(),
      Paint()..color = const Color(0xFFFFC9C5),
    );
    // Text lines.
    final line = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      final y = page.top + s * (0.11 + i * 0.065);
      canvas.drawLine(Offset(page.left + s * 0.06, y), Offset(page.right - s * (i == 0 ? 0.16 : 0.08), y), line);
    }
    // "PDF" label.
    final label = RRect.fromRectAndRadius(
      Rect.fromLTWH(page.left - s * 0.06, page.top + s * 0.25, s * 0.38, s * 0.15),
      Radius.circular(s * 0.035),
    );
    canvas.drawRRect(label, Paint()..color = onRed ? AppColors.navy : const Color(0xFFD7261D));
    final tp = TextPainter(
      text: TextSpan(
        text: 'PDF',
        style: TextStyle(color: Colors.white, fontSize: s * 0.105, fontWeight: FontWeight.w900, letterSpacing: s * 0.003),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(label.left + (label.width - tp.width) / 2, label.top + (label.height - tp.height) / 2));
    tp.dispose();
    // Camera lens.
    final c = Offset(page.right - s * 0.01, page.bottom - s * 0.02);
    final r = s * 0.13;
    canvas.drawCircle(c, r * 1.12, white);
    canvas.drawCircle(c, r, Paint()..color = AppColors.navy);
    canvas.drawCircle(
      c,
      r * 0.68,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)]).createShader(Rect.fromCircle(center: c, radius: r * 0.68)),
    );
    canvas.drawCircle(c + Offset(-r * 0.22, -r * 0.22), r * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.onRed != onRed;
}

/// White (dark: navy) rounded surface with a soft shadow instead of a border.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.onTap, this.onLongPress, this.padding, this.radius = Gaps.radius, this.color});

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = padding == null ? child : Padding(padding: padding!, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppColors.softShadow(theme.brightness),
        border: isDark ? Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null && onLongPress == null
            ? content
            : PressScale(child: InkWell(onTap: onTap, onLongPress: onLongPress, child: content)),
      ),
    );
  }
}

/// Subtle press feedback: scales the child to 97% while pressed.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Rounded square with a tinted background and a coloured icon (tool / row icon).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, this.size = 44, this.filled = false});

  final IconData icon;
  final Color color;
  final double size;

  /// Solid background with a white icon (iOS settings style).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: filled ? Colors.white : color, size: size * 0.52),
    );
  }
}

/// Vertical tool card: coloured icon tile above a label (and optional subtitle).
class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  /// Optional corner badge (e.g. a PRO pill).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final b = badge;
    final sub = subtitle;
    return Semantics(
      button: true,
      label: sub == null ? label : '$label, $sub',
      excludeSemantics: true,
      child: SoftCard(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTile(icon: icon, color: color, size: 46),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(fontSize: 13, height: 1.15),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (b != null) Positioned(top: 8, right: 8, child: b),
          ],
        ),
      ),
    );
  }
}

/// iOS-style large title header used at the top of tab screens.
class LargeTitle extends StatelessWidget {
  const LargeTitle({super.key, required this.title, this.subtitle, this.trailing = const []});

  final String title;
  final String? subtitle;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sub = subtitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 10, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: textTheme.headlineMedium)),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(sub, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// Section label ("PDF CREATION") with an optional trailing action.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.actionLabel, this.onAction, this.padding = const EdgeInsets.fromLTRB(20, 22, 12, 10)});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          if (label != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(minimumSize: const Size(44, 36), padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}

/// iOS-style grouped list section.
class GroupedSection extends StatelessWidget {
  const GroupedSection({super.key, this.title, required this.children, this.footer});

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final t = title;
    final f = footer;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, indent: 64, color: scheme.outlineVariant.withValues(alpha: 0.7)));
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 22, 6, 8),
              child: Semantics(
                header: true,
                child: Text(
                  t.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.6),
                ),
              ),
            ),
          SoftCard(child: Column(children: rows)),
          if (f != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
              child: Text(f, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}

/// iOS-style settings row: coloured icon square, title, optional subtitle and trailing.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.destructive = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Defaults to true when [onTap] is set and there's no [trailing] widget.
  final bool? showChevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sub = subtitle;
    final tr = trailing;
    final chevron = showChevron ?? (onTap != null && tr == null);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              IconTile(icon: icon, color: destructive ? AppColors.danger : color, size: 34, filled: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: destructive ? AppColors.danger : null),
                    ),
                    if (sub != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(sub, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                  ],
                ),
              ),
              ?tr,
              if (chevron) Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

enum StatusKind { empty, loading, success, error }

/// Full empty / loading / success / error state with an illustration and actions.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.icon,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.progress,
  });

  final StatusKind kind;
  final String title;
  final String? message;
  final IconData? icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Loading only: 0..1, or null for indeterminate.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final msg = message;
    final pl = primaryLabel;
    final sl = secondaryLabel;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusArt(kind: kind, icon: icon, progress: progress),
            const SizedBox(height: 22),
            Semantics(
              liveRegion: kind == StatusKind.success || kind == StatusKind.error,
              child: Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
            ),
            if (msg != null) ...[
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            if (pl != null) ...[
              const SizedBox(height: 26),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: onPrimary, child: Text(pl))),
            ],
            if (sl != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onSecondary,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.surfaceContainerHigh,
                    foregroundColor: scheme.onSurface,
                  ),
                  child: Text(sl),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusArt extends StatelessWidget {
  const _StatusArt({required this.kind, required this.icon, required this.progress});

  final StatusKind kind;
  final IconData? icon;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color color, IconData glyph) = switch (kind) {
      StatusKind.empty => (AppColors.blue, icon ?? Icons.folder_open_rounded),
      StatusKind.loading => (scheme.primary, icon ?? Icons.picture_as_pdf_rounded),
      StatusKind.success => (AppColors.green, icon ?? Icons.check_rounded),
      StatusKind.error => (AppColors.danger, icon ?? Icons.priority_high_rounded),
    };
    final halo = Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: isDark ? 0.14 : 0.08)),
    );
    switch (kind) {
      case StatusKind.loading:
        return SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              halo,
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(value: progress, strokeWidth: 5, strokeCap: StrokeCap.round),
              ),
              Icon(glyph, size: 34, color: color),
            ],
          ),
        );
      case StatusKind.success:
      case StatusKind.error:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Stack(
            alignment: Alignment.center,
            children: [
              halo,
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 8))],
                ),
                child: Icon(glyph, color: Colors.white, size: 42),
              ),
            ],
          ),
        );
      case StatusKind.empty:
        return Stack(
          alignment: Alignment.center,
          children: [
            halo,
            Transform.rotate(
              angle: -math.pi / 40,
              child: Container(
                width: 70,
                height: 84,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.softShadow(Theme.of(context).brightness),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(glyph, color: color, size: 34),
              ),
            ),
          ],
        );
    }
  }
}

/// Full-screen success page shown after a PDF or document has been created.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: StatusView(
          kind: StatusKind.success,
          title: title,
          message: message,
          primaryLabel: primaryLabel,
          onPrimary: onPrimary,
          secondaryLabel: secondaryLabel,
          onSecondary: onSecondary,
        ),
      ),
    );
  }
}
