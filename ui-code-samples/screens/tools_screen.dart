import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/entitlements.dart';
import '../subscription/premium_gate.dart';
import '../subscription/pro_cards.dart';
import '../widgets/pdf_ui.dart';
import 'pdf_actions.dart';

/// PDF Tools hub: every PDF capability grouped by what the user wants to do.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static final List<(String, List<PdfTool>)> groups = [
    ('Create PDF', [PdfActions.scan, PdfActions.imagesToPdf, PdfActions.importFiles]),
    (
      'Manage PDF',
      [PdfActions.merge, PdfActions.split, PdfActions.organize, PdfActions.rotate, PdfActions.extract, PdfActions.deletePages],
    ),
    ('Edit PDF', [PdfActions.sign, PdfActions.addText, PdfActions.annotate, PdfActions.watermark, PdfActions.redact]),
    ('Optimize PDF', [PdfActions.compress, PdfActions.protect]),
    ('OCR & Text', [PdfActions.ocr, PdfActions.extractText, PdfActions.searchText]),
    ('Share & Export', [PdfActions.share, PdfActions.printPdf]),
  ];

  @override
  Widget build(BuildContext context) {
    final entitlements = context.watch<EntitlementService>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: LargeTitle(title: 'PDF Tools', subtitle: 'All the tools you need')),
            const SliverToBoxAdapter(child: ProBanner()),
            for (final g in groups) ...[
              SliverToBoxAdapter(child: SectionLabel(g.$1)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    mainAxisExtent: 128,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final t = g.$2[i];
                      final f = t.feature;
                      return ToolCard(
                        icon: t.icon,
                        color: t.color,
                        label: t.label,
                        subtitle: t.subtitle,
                        badge: f != null && !entitlements.isUnlocked(f) ? const ProBadge(compact: true) : null,
                        onTap: () => t.open(context),
                      );
                    },
                    childCount: g.$2.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}
