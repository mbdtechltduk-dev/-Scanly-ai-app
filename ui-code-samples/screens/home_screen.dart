import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/entitlements.dart';
import '../core/format.dart';
import '../documents/document_actions.dart';
import '../documents/document_screen.dart';
import '../documents/import_flows.dart';
import '../models/records.dart';
import '../repositories/document_repository.dart';
import '../search/search_screen.dart';
import '../services/native_bridge.dart';
import '../subscription/paywall_screen.dart';
import '../subscription/premium_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/doc_widgets.dart';
import '../widgets/pdf_ui.dart';
import 'pdf_actions.dart';

class _HomeData {
  const _HomeData({
    required this.recent,
    required this.folders,
    required this.folderCounts,
    required this.stats,
    required this.storage,
  });

  final List<DocumentRecord> recent;
  final List<FolderRecord> folders;
  final Map<String, int> folderCounts;
  final LibraryStats stats;
  final StorageInfo? storage;
}

/// PDF workspace: Scan to PDF hero, the main PDF actions, recent documents, folders
/// and on-device storage.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenDocuments, required this.onOpenFolder, required this.onOpenTools});

  final VoidCallback onOpenDocuments;
  final ValueChanged<String> onOpenFolder;
  final VoidCallback onOpenTools;

  /// Home priority order (PDF first).
  static final List<PdfTool> quickTools = [
    PdfActions.createPdf,
    PdfActions.imagesToPdf,
    PdfActions.merge,
    PdfActions.compress,
    PdfActions.ocr,
    PdfActions.split,
    PdfActions.organize,
  ];

  Future<_HomeData> _load(DocumentRepository repo) async {
    final results = await Future.wait<Object?>([
      repo.recentDocuments(limit: 5),
      repo.folders(),
      repo.folderDocCounts(),
      repo.stats(),
      NativeBridge.storageInfo(),
    ]);
    return _HomeData(
      recent: results[0] as List<DocumentRecord>,
      folders: results[1] as List<FolderRecord>,
      folderCounts: results[2] as Map<String, int>,
      stats: results[3] as LibraryStats,
      storage: results[4] as StorageInfo?,
    );
  }

  Future<void> _newFolder(BuildContext context) async {
    final repo = context.read<DocumentRepository>();
    final name = await showTextInput(context, title: 'New folder', hint: 'Folder name', confirmLabel: 'Create', maxLength: 60);
    if (name != null) await repo.createFolder(name);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DocumentRepository>();
    final entitlements = context.watch<EntitlementService>();
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: RepoFutureBuilder<_HomeData>(
        revision: repo.revision,
        load: () => _load(repo),
        builder: (context, data) => ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // Brand header.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          label: 'PDF Pro – Scan & OCR',
                          excludeSemantics: true,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'PDF Pro\n', style: TextStyle(color: scheme.primary)),
                                const TextSpan(text: 'Scan & OCR'),
                              ],
                            ),
                            style: textTheme.headlineMedium?.copyWith(height: 1.08),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'FAST · PRIVATE · ON-DEVICE',
                          style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 1.6, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  if (!entitlements.isPremium)
                    IconButton(
                      onPressed: () => PaywallScreen.open(context),
                      icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.orange),
                      tooltip: 'PDF Pro Premium',
                    ),
                  IconButton(onPressed: () => SearchScreen.open(context), icon: const Icon(Icons.search_rounded), tooltip: 'Search documents'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _ScanHero(onTap: () => ImportFlows.scan(context)),
            ),
            SectionLabel('PDF tools', actionLabel: 'All tools', onAction: onOpenTools),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, box) {
                  final columns = box.maxWidth >= 560 ? 8 : 4;
                  final width = (box.maxWidth - (columns - 1) * 10) / columns;
                  final tiles = [
                    for (final t in quickTools)
                      _QuickTile(
                        tool: t,
                        locked: t.feature != null && !entitlements.isUnlocked(t.feature!),
                      ),
                    _QuickTile.more(onTap: onOpenTools),
                  ];
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [for (final t in tiles) SizedBox(width: width, child: t)],
                  );
                },
              ),
            ),
            SectionLabel(
              'Recent documents',
              actionLabel: data.recent.isEmpty ? null : 'See all',
              onAction: onOpenDocuments,
            ),
            if (data.recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.picture_as_pdf_rounded, color: AppColors.red, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No documents yet', style: textTheme.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              'Scan or create a PDF to see it here. Everything stays on this device.',
                              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final d in data.recent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DocRow(
                          doc: d,
                          onTap: () => DocumentScreen.open(context, d.id),
                          onMore: () => DocumentActions.showMenu(context, d),
                        ),
                      ),
                  ],
                ),
              ),
            SectionLabel('Folders', actionLabel: 'New folder', onAction: () => _newFolder(context)),
            if (data.folders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Organise documents into folders and subfolders.',
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              )
            else
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  itemCount: data.folders.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final f = data.folders[i];
                    return SizedBox(
                      width: 200,
                      child: FolderCard(folder: f, count: data.folderCounts[f.id] ?? 0, onTap: () => onOpenFolder(f.id)),
                    );
                  },
                ),
              ),
            const SectionLabel('Storage'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StorageCard(stats: data.stats, storage: data.storage),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final red = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Scan to PDF. Turn your documents into high-quality PDFs.',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Gaps.radiusL),
          boxShadow: [BoxShadow(color: red.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Material(
          color: red,
          borderRadius: BorderRadius.circular(Gaps.radiusL),
          clipBehavior: Clip.antiAlias,
          child: PressScale(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Icon(Icons.photo_camera_rounded, color: red, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scan to PDF',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Turn your documents into high-quality PDFs.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required PdfTool this.tool, required this.locked}) : onMore = null;

  const _QuickTile.more({required VoidCallback onTap})
      : tool = null,
        locked = false,
        onMore = onTap;

  final PdfTool? tool;
  final bool locked;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final t = tool;
    final icon = t?.icon ?? Icons.apps_rounded;
    final color = t?.color ?? AppColors.slate;
    final label = t?.label ?? 'More Tools';
    return Semantics(
      button: true,
      label: locked ? '$label, Premium' : label,
      excludeSemantics: true,
      child: SoftCard(
        onTap: t != null ? () => t.open(context) : onMore,
        child: SizedBox(
          height: 96,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTile(icon: icon, color: color, size: 40),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
              if (locked) const Positioned(top: 6, right: 6, child: ProBadge(compact: true)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.stats, required this.storage});

  final LibraryStats stats;
  final StorageInfo? storage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final s = storage;
    final total = s?.totalBytes ?? 0;
    final free = s?.freeBytes ?? 0;
    final usedByOthers = total > 0 ? (total - free - stats.bytes).clamp(0, total) : 0;
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(icon: Icons.sd_storage_rounded, color: AppColors.blue, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${pluralize(stats.documents, 'document')} · ${pluralize(stats.pages, 'page')}',
                  style: textTheme.titleSmall,
                ),
              ),
              Text(formatBytes(stats.bytes), style: textTheme.titleSmall?.copyWith(color: AppColors.blue)),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(flex: (usedByOthers * 1000 ~/ total).clamp(1, 1000), child: Container(color: scheme.outline)),
                    Expanded(flex: (stats.bytes * 1000 ~/ total).clamp(1, 1000), child: Container(color: AppColors.blue)),
                    Expanded(flex: (free * 1000 ~/ total).clamp(1, 1000), child: Container(color: scheme.surfaceContainerHighest)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${formatBytes(free)} free of ${formatBytes(total)} on this device',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
