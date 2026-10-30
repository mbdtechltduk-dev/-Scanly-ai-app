import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../models/records.dart';
import '../services/file_store.dart';
import '../theme/app_theme.dart';
import 'pdf_ui.dart';

/// Document thumbnail with graceful placeholder.
class DocThumb extends StatelessWidget {
  const DocThumb({super.key, required this.doc, this.radius = 12, this.cacheWidth = 360});

  final DocumentRecord doc;
  final double radius;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final files = Provider.of<FileStore>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    final thumb = doc.thumbPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: scheme.surfaceContainerHigh,
        child: thumb == null
            ? Center(
                child: Icon(
                  doc.isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                  color: doc.isPdf ? AppColors.red : AppColors.blue,
                ),
              )
            : Image.file(
                files.file(thumb),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                cacheWidth: cacheWidth,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant)),
              ),
      ),
    );
  }
}

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.doc});

  final DocumentRecord doc;

  @override
  Widget build(BuildContext context) {
    final isPdf = doc.isPdf;
    final color = isPdf ? AppColors.red : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        doc.typeLabel,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }
}

/// Grid card: thumbnail, name, pages · date, type badge, favourite star.
class DocCard extends StatelessWidget {
  const DocCard({
    super.key,
    required this.doc,
    required this.onTap,
    this.onLongPress,
    this.onMore,
    this.selected,
  });

  final DocumentRecord doc;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMore;

  /// Non-null in selection mode.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sel = selected;
    return Semantics(
      button: true,
      label: '${doc.name}, ${pluralize(doc.pageCount, 'page')}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Gaps.radius + 2),
          border: Border.all(color: sel == true ? scheme.primary : Colors.transparent, width: 2),
        ),
        child: SoftCard(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 0), child: DocThumb(doc: doc)),
                    Positioned(left: 14, top: 14, child: TypeBadge(doc: doc)),
                    if (doc.favorite)
                      const Positioned(right: 14, top: 12, child: Icon(Icons.star_rounded, color: AppColors.warning, size: 20)),
                    if (sel != null)
                      Positioned(
                        right: 12,
                        bottom: 6,
                        child: Icon(
                          sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: sel ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            '${pluralize(doc.pageCount, 'page')} · ${formatRelativeDate(doc.modifiedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (onMore != null && sel == null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onPressed: onMore,
                        tooltip: 'More',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List row variant.
class DocTile extends StatelessWidget {
  const DocTile({super.key, required this.doc, required this.onTap, this.onLongPress, this.onMore, this.selected, this.subtitle});

  final DocumentRecord doc;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMore;
  final bool? selected;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sel = selected;
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: sel == true,
      selectedTileColor: scheme.primary.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(width: 48, height: 60, child: DocThumb(doc: doc, radius: 8, cacheWidth: 160)),
      title: Row(
        children: [
          Flexible(child: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (doc.favorite) ...[
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
          ],
        ],
      ),
      subtitle: Text(
        subtitle ?? '${doc.typeLabel} · ${pluralize(doc.pageCount, 'page')} · ${formatBytes(doc.sizeBytes)} · ${formatRelativeDate(doc.modifiedAt)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: sel != null
          ? Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: sel ? scheme.primary : null)
          : (onMore == null ? null : IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: onMore, tooltip: 'More')),
    );
  }
}

class FolderCard extends StatelessWidget {
  const FolderCard({super.key, required this.folder, required this.count, required this.onTap, this.onMore});

  final FolderRecord folder;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      onTap: onTap,
      onLongPress: onMore,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            const IconTile(icon: Icons.folder_rounded, color: AppColors.blue, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                  Text(pluralize(count, 'document'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (onMore != null)
              IconButton(visualDensity: VisualDensity.compact, onPressed: onMore, icon: const Icon(Icons.more_horiz_rounded, size: 22), tooltip: 'Folder options'),
          ],
        ),
      ),
    );
  }
}

/// "My Documents" row: thumbnail, name, date, page count and file size.
class DocRow extends StatelessWidget {
  const DocRow({super.key, required this.doc, required this.onTap, this.onLongPress, this.onMore, this.selected});

  final DocumentRecord doc;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMore;

  /// Non-null in selection mode.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sel = selected;
    final more = onMore;
    return Semantics(
      button: true,
      selected: sel == true,
      label: '${doc.typeLabel} ${doc.name}, ${pluralize(doc.pageCount, 'page')}, ${formatBytes(doc.sizeBytes)}, ${formatRelativeDate(doc.modifiedAt)}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Gaps.radius + 2),
          border: Border.all(color: sel == true ? scheme.primary : Colors.transparent, width: 2),
        ),
        child: SoftCard(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 62,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DocThumb(doc: doc, radius: 9, cacheWidth: 160),
                      Positioned(left: 3, bottom: 3, child: TypeBadge(doc: doc)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall?.copyWith(fontSize: 15)),
                          ),
                          if (doc.favorite) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: AppColors.orange, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatRelativeDate(doc.modifiedAt)}, ${formatTime(doc.modifiedAt)}',
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        '${pluralize(doc.pageCount, 'page')} · ${formatBytes(doc.sizeBytes)}',
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (sel != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: sel ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  )
                else if (more != null)
                  IconButton(onPressed: more, icon: const Icon(Icons.more_vert_rounded), tooltip: 'More actions for ${doc.name}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state (kept for existing callers) rendered with the PDF Pro status style.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final a = action;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusView(kind: StatusKind.empty, icon: icon, title: title, message: message),
            if (a != null) ...[const SizedBox(height: 4), a],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Re-runs [load] whenever the repository changes (or [keyValue] changes).
class RepoFutureBuilder<T> extends StatefulWidget {
  const RepoFutureBuilder({super.key, required this.revision, required this.load, required this.builder, this.keyValue});

  final int revision;
  final Object? keyValue;
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<RepoFutureBuilder<T>> createState() => _RepoFutureBuilderState<T>();
}

class _RepoFutureBuilderState<T> extends State<RepoFutureBuilder<T>> {
  late Future<T> _future = widget.load();
  T? _last;

  @override
  void didUpdateWidget(covariant RepoFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision || oldWidget.keyValue != widget.keyValue) {
      _future = widget.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) _last = snap.data;
        final data = snap.data ?? _last;
        if (snap.hasError && data == null) {
          return StatusView(
            kind: StatusKind.error,
            title: 'Something Went Wrong',
            message: 'We couldn\'t load your documents. Please try again.',
            primaryLabel: 'Try Again',
            onPrimary: () => setState(() => _future = widget.load()),
          );
        }
        if (data == null) return const Center(child: CircularProgressIndicator());
        return widget.builder(context, data as T);
      },
    );
  }
}
