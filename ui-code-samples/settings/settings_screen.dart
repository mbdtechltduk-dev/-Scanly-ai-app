import '../legal/legal_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/entitlements.dart';
import '../core/format.dart';
import '../models/page_edit.dart';
import '../models/pdf_settings.dart';
import '../repositories/document_repository.dart';
import '../screens/trash_screen.dart';
import '../security/app_lock_service.dart';
import '../security/pin_setup_screen.dart';
import '../services/file_store.dart';
import '../services/settings_controller.dart';
import '../subscription/premium_gate.dart';
import '../subscription/legal_links.dart';
import '../subscription/pro_cards.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/pdf_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _bioAvailable;
  int? _cacheBytes;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final lock = context.read<AppLockService>();
    final files = context.read<FileStore>();
    final bio = await lock.biometricsAvailable();
    final cache = await files.tempSize();
    if (!mounted) return;
    setState(() {
      _bioAvailable = bio;
      _cacheBytes = cache;
    });
  }

  Future<void> _toggleLock(bool on) async {
    final lock = context.read<AppLockService>();
    if (on) {
      final ok = await PinSetupScreen.open(context);
      if (ok == true && mounted) showSnack(context, 'App Lock is on');
    } else {
      final ok = await showConfirm(context, title: 'Turn off App Lock?', confirmLabel: 'Turn off', destructive: true);
      if (ok) await lock.disable();
    }
  }

  Future<void> _clearCache() async {
    final files = context.read<FileStore>();
    await files.clearTemp();
    await _refresh();
    if (mounted) showSnack(context, 'Temporary files cleared');
  }

  Widget _chips<T>(List<T> values, T selected, String Function(T) label, ValueChanged<T> onSelected) => Padding(
        padding: const EdgeInsets.fromLTRB(62, 0, 14, 14),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final v in values) ChoiceChip(label: Text(label(v)), selected: v == selected, onSelected: (_) => onSelected(v)),
          ],
        ),
      );

  Widget _switchRow({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) =>
      SettingsRow(
        icon: icon,
        color: color,
        title: title,
        subtitle: subtitle,
        showChevron: false,
        onTap: onChanged == null ? null : () => onChanged(!value),
        trailing: Switch.adaptive(value: value, onChanged: onChanged),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final lock = context.watch<AppLockService>();
    final repo = context.watch<DocumentRepository>();
    final entitlements = context.watch<EntitlementService>();
    final pdf = s.pdfDefaults;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const LargeTitle(title: 'Settings'),
            const ProSettingsCard(),
            GroupedSection(
              title: 'App settings',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => s.themeMode = v.first,
                  ),
                ),
                _switchRow(
                  icon: Icons.vibration_rounded,
                  color: AppColors.slate,
                  title: 'Haptic feedback',
                  value: s.haptics,
                  onChanged: (v) => s.haptics = v,
                ),
              ],
            ),
            GroupedSection(
              title: 'Scanner settings',
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsRow(icon: Icons.auto_fix_high_rounded, color: AppColors.red, title: 'Default enhancement'),
                    _chips<FilterMode>(FilterMode.values, s.defaultFilter, (f) => f.label, (f) => s.defaultFilter = f),
                  ],
                ),
                _switchRow(
                  icon: Icons.camera_rounded,
                  color: AppColors.red,
                  title: 'Auto capture',
                  subtitle: 'Capture when the document is steady',
                  value: s.autoCapture,
                  onChanged: (v) => s.autoCapture = v,
                ),
                _switchRow(
                  icon: Icons.crop_rounded,
                  color: AppColors.blue,
                  title: 'Auto crop imported photos',
                  subtitle: 'Detect edges in gallery and file imports',
                  value: s.autoCropImports,
                  onChanged: (v) => s.autoCropImports = v,
                ),
                _switchRow(
                  icon: Icons.high_quality_rounded,
                  color: AppColors.green,
                  title: 'High resolution capture',
                  subtitle: 'Sharper text and better OCR. Turn off on low-memory devices.',
                  value: s.highResolutionScans,
                  onChanged: (v) => s.highResolutionScans = v,
                ),
              ],
            ),
            GroupedSection(
              title: 'OCR settings',
              children: [
                SettingsRow(
                  icon: Icons.translate_rounded,
                  color: AppColors.purple,
                  title: 'Default script',
                  subtitle: PremiumGate.effectiveOcrScript(context, s.ocrScript).label,
                  showChevron: false,
                  trailing: PopupMenuButton<OcrScript>(
                    icon: const Icon(Icons.expand_more_rounded),
                    tooltip: 'Choose script',
                    initialValue: s.ocrScript,
                    onSelected: (v) async {
                      if (!await PremiumGate.ensureOcrScript(context, v)) return;
                      s.ocrScript = v;
                    },
                    itemBuilder: (_) => [
                      for (final o in OcrScript.values)
                        PopupMenuItem(
                          value: o,
                          child: Row(
                            children: [
                              Expanded(child: Text(o.label)),
                              if (o != OcrScript.latin && !entitlements.isUnlocked(AppFeature.advancedOcr)) const ProBadge(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _switchRow(
                  icon: Icons.document_scanner_outlined,
                  color: AppColors.purple,
                  title: 'Recognise text after scanning',
                  subtitle: 'Makes new scans searchable automatically',
                  value: s.autoOcr,
                  onChanged: (v) => s.autoOcr = v,
                ),
              ],
            ),
            GroupedSection(
              title: 'PDF defaults',
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsRow(icon: Icons.description_rounded, color: AppColors.blue, title: 'Paper size'),
                    _chips<PaperSize>(
                      PaperSize.values.where((p) => p != PaperSize.custom).toList(),
                      pdf.paperSize,
                      (p) => p.label,
                      (p) => s.savePdfDefaults(pdf.copyWith(paperSize: p)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsRow(icon: Icons.photo_size_select_large_rounded, color: AppColors.blue, title: 'Image quality'),
                    _chips<ExportQuality>(
                      ExportQuality.values,
                      pdf.quality,
                      (q) => q.label,
                      (q) => s.savePdfDefaults(pdf.copyWith(quality: q)),
                    ),
                  ],
                ),
                _switchRow(
                  icon: Icons.manage_search_rounded,
                  color: AppColors.purple,
                  title: 'Searchable PDFs',
                  subtitle: 'Include recognised text in exported PDFs',
                  value: pdf.searchable,
                  onChanged: (v) => s.savePdfDefaults(pdf.copyWith(searchable: v)),
                ),
              ],
            ),
            GroupedSection(
              title: 'Security',
              children: [
                _switchRow(
                  icon: Icons.lock_rounded,
                  color: AppColors.navy,
                  title: 'App Lock',
                  subtitle: 'Require a PIN to open PDF Pro',
                  value: lock.enabled,
                  onChanged: _toggleLock,
                ),
                if (lock.enabled) ...[
                  SettingsRow(
                    icon: Icons.pin_rounded,
                    color: AppColors.navy,
                    title: 'Change PIN',
                    onTap: () => PinSetupScreen.open(context),
                  ),
                  _switchRow(
                    icon: Icons.fingerprint_rounded,
                    color: AppColors.green,
                    title: 'Unlock with biometrics',
                    subtitle: _bioAvailable == false ? 'Not available or not set up on this device' : 'Face ID, Touch ID or fingerprint',
                    value: s.biometricEnabled && (_bioAvailable ?? false),
                    onChanged: _bioAvailable == true ? (v) => s.biometricEnabled = v : null,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SettingsRow(icon: Icons.timer_rounded, color: AppColors.orange, title: 'Lock after leaving the app'),
                      _chips<int>(
                        const [0, 60, 300],
                        s.lockTimeoutSeconds,
                        (secs) => switch (secs) { 0 => 'Immediately', 60 => '1 minute', _ => '5 minutes' },
                        (secs) => s.lockTimeoutSeconds = secs,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            GroupedSection(
              title: 'Storage',
              children: [
                FutureBuilder<LibraryStats>(
                  future: repo.stats(),
                  builder: (context, snap) {
                    final st = snap.data;
                    return SettingsRow(
                      icon: Icons.folder_rounded,
                      color: AppColors.blue,
                      title: 'Documents on this device',
                      subtitle: st == null ? '…' : '${pluralize(st.documents, 'document')} · ${formatBytes(st.bytes)}',
                    );
                  },
                ),
                SettingsRow(
                  icon: Icons.cleaning_services_rounded,
                  color: AppColors.slate,
                  title: 'Temporary files',
                  subtitle: _cacheBytes == null ? '…' : formatBytes(_cacheBytes!),
                  trailing: TextButton(onPressed: _clearCache, child: const Text('Clear')),
                ),
                SettingsRow(
                  icon: Icons.delete_rounded,
                  color: AppColors.danger,
                  title: 'Recently deleted',
                  subtitle: 'Kept for 30 days',
                  onTap: () => TrashScreen.open(context),
                ),
              ],
            ),
            GroupedSection(
              title: 'Legal & support',
              children: [
                SettingsRow(
                  icon: Icons.privacy_tip_rounded,
                  color: AppColors.blue,
                  title: 'Privacy Policy',
                  subtitle: 'View policy',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LegalScreen(title: 'Privacy Policy'))),
                ),
                SettingsRow(
                  icon: Icons.article_rounded,
                  color: AppColors.slate,
                  title: 'Terms of Use',
                  subtitle: 'View terms',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LegalScreen(title: 'Terms of Use'))),
                ),
                SettingsRow(
                  icon: Icons.gavel_rounded,
                  color: AppColors.slate,
                  title: 'EULA',
                  subtitle: 'End User License Agreement',
                  onTap: () => LegalLinks.openEula(context),
                ),
                if (LegalLinks.hasSupport)
                  SettingsRow(
                    icon: Icons.support_agent_rounded,
                    color: AppColors.orange,
                    title: 'Contact Support',
                    subtitle: 'Get help by e-mail',
                    onTap: () => LegalLinks.contactSupport(context),
                  ),
                SettingsRow(
                  icon: Icons.description_outlined,
                  color: AppColors.slate,
                  title: 'Open-source licences',
                  onTap: () => showLicensePage(context: context, applicationName: 'PDF Pro – Scan & OCR'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scanning, enhancement, OCR, signatures and PDF processing run entirely on this device. '
                      'Documents are stored in the app\'s private storage and are never uploaded. '
                      'PDF Pro includes no analytics SDK. Google ML Kit (on-device OCR and the Android system scanner) '
                      'may send anonymous performance diagnostics to Google — never document content.',
                      style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
