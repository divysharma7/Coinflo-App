import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/services/excel_import_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 4-step import wizard: File → Map columns → Review duplicates → Confirm.
/// (ISSUE 9)
class ExcelImportPage extends ConsumerStatefulWidget {
  const ExcelImportPage({super.key});

  @override
  ConsumerState<ExcelImportPage> createState() => _ExcelImportPageState();
}

class _ExcelImportPageState extends ConsumerState<ExcelImportPage> {
  static const _mappingPrefsKey = 'excelColumnMapping';

  final _service = ExcelImportService();

  int _step = 0; // 0=file, 1=map, 2=duplicates, 3=confirm
  bool _busy = false;

  // Step 1
  File? _file;
  String? _fileName;
  int _fileSize = 0;
  String? _fileError;

  // Step 2
  RawSheet? _sheet;
  ColumnMapping _mapping = const ColumnMapping(
      date: -1, amount: -1, type: -1, category: -1);

  // Step 3
  ExcelParseResult? _parsed;
  Set<int> _duplicates = {};
  final Set<int> _skip = {};

  // Step 4
  String? _importError;

  static const _stepTitles = [
    'Select file',
    'Map columns',
    'Review duplicates',
    'Confirm import',
  ];

  // ─── Step 1: file ─────────────────────────────────────

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ExcelImportService.allowedExtensions.toList(),
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    final file = File(path);
    final name = picked!.files.single.name;
    final ext = name.split('.').last.toLowerCase();
    final size = file.lengthSync();

    String? error;
    if (!ExcelImportService.allowedExtensions.contains(ext)) {
      error = 'Unsupported file type. Use .xlsx or .csv.';
    } else if (size > ExcelImportService.maxFileBytes) {
      error = 'File is too large (${_fmtSize(size)}). Max is 10 MB.';
    }

    setState(() {
      _file = error == null ? file : null;
      _fileName = name;
      _fileSize = size;
      _fileError = error;
    });
  }

  // ─── Step transitions ─────────────────────────────────

  Future<void> _next() async {
    switch (_step) {
      case 0:
        await _enterMapping();
      case 1:
        await _enterDuplicates();
      case 2:
        setState(() => _step = 3);
      case 3:
        await _runImport();
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  Future<void> _enterMapping() async {
    if (_file == null) return;
    setState(() => _busy = true);
    try {
      final sheet = _service.readRawSheet(_file!);
      if (sheet.isEmpty) {
        setState(() {
          _busy = false;
          _fileError = 'The file has no data rows.';
        });
        return;
      }
      final mapping = await _loadOrDetectMapping(sheet.headers);
      setState(() {
        _sheet = sheet;
        _mapping = mapping;
        _busy = false;
        _step = 1;
      });
    } on Exception catch (e) {
      setState(() {
        _busy = false;
        _fileError = "Couldn't read that file: $e";
      });
    }
  }

  Future<ColumnMapping> _loadOrDetectMapping(List<String> headers) async {
    final auto = _service.autoDetect(headers);
    if (auto.isComplete) return auto;
    // Fall back to a previously-saved mapping (valid only if indices fit).
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_mappingPrefsKey);
    if (saved != null) {
      try {
        final m = ColumnMapping.fromJson(
            jsonDecode(saved) as Map<String, dynamic>);
        final maxIdx = headers.length - 1;
        final fits = [m.date, m.amount, m.type, m.category, m.source, m.note]
            .every((i) => i <= maxIdx);
        if (fits) return m;
      } on Exception catch (_) {
        // ignore malformed saved mapping
      }
    }
    return auto;
  }

  Future<void> _enterDuplicates() async {
    if (_sheet == null || !_mapping.isComplete) return;
    setState(() => _busy = true);

    // Persist the mapping for next time.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mappingPrefsKey, jsonEncode(_mapping.toJson()));

    final parsed = _service.parseRows(_sheet!, _mapping);
    final existing = await ref.read(repositoryProvider).watchAll().first;
    final dupes = _service.findDuplicateIndices(parsed.rows, existing);

    setState(() {
      _parsed = parsed;
      _duplicates = dupes;
      _skip
        ..clear()
        ..addAll(dupes); // default: skip detected duplicates
      _busy = false;
      _step = 2;
    });
  }

  Future<void> _runImport() async {
    final parsed = _parsed;
    if (parsed == null) return;
    setState(() {
      _busy = true;
      _importError = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final count =
          await _service.bulkInsert(parsed.rows, db, skip: _skip);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count transaction${count == 1 ? '' : 's'} imported'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/transactions');
    } on Exception catch (e) {
      setState(() {
        _busy = false;
        _importError = 'Import failed: $e';
      });
    }
  }

  // ─── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _header(),
                Expanded(child: _stepBody()),
                _bottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 24, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBackButton(onTap: _busy ? () {} : _back),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Import from Excel',
                    style: AppTextStyles.headingL
                        .copyWith(color: AppColors.black)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Step progress dots
          Row(
            children: List.generate(4, (i) {
              final active = i <= _step;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: active ? AppColors.black : AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Step ${_step + 1} of 4 · ${_stepTitles[_step]}',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500)),
        ],
      ),
    );
  }

  Widget _stepBody() {
    if (_busy) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.black));
    }
    switch (_step) {
      case 0:
        return _fileStep();
      case 1:
        return _mappingStep();
      case 2:
        return _duplicatesStep();
      default:
        return _confirmStep();
    }
  }

  // ─── Step 1 UI ────────────────────────────────────────

  Widget _fileStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                PhosphorIcon(PhosphorIcons.fileXls(),
                    size: 40, color: AppColors.gray500),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _fileName ?? 'Tap to select a .xlsx or .csv file',
                  style: AppTextStyles.bodyM.copyWith(
                      color: _fileName != null
                          ? AppColors.black
                          : AppColors.gray500),
                  textAlign: TextAlign.center,
                ),
                if (_fileName != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(_fmtSize(_fileSize),
                      style: AppTextStyles.labelS
                          .copyWith(color: AppColors.gray500)),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text('Max 10 MB',
                    style: AppTextStyles.labelS
                        .copyWith(color: AppColors.gray400)),
              ],
            ),
          ),
        ),
        if (_fileError != null) ...[
          const SizedBox(height: AppSpacing.md),
          _banner(_fileError!, AppColors.red, PhosphorIcons.warningCircle()),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your sheet needs a header row. The next step lets you match each '
          'column to Date, Amount, Type, Category, and (optionally) Source & '
          'Note.',
          style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
        ),
      ],
    );
  }

  // ─── Step 2 UI ────────────────────────────────────────

  Widget _mappingStep() {
    final sheet = _sheet!;
    final preview = sheet.rows.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      children: [
        Text('PREVIEW (first 5 rows)',
            style: AppTextStyles.section.copyWith(color: AppColors.gray500)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.xl,
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.gray100),
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              columnSpacing: 16,
              columns: [
                for (final h in sheet.headers)
                  DataColumn(
                      label: Text(h.isEmpty ? '—' : h,
                          style: AppTextStyles.labelM)),
              ],
              rows: [
                for (final r in preview)
                  DataRow(cells: [
                    for (var c = 0; c < sheet.headers.length; c++)
                      DataCell(Text(c < r.length ? r[c] : '',
                          style: AppTextStyles.bodyS)),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('MATCH COLUMNS',
            style: AppTextStyles.section.copyWith(color: AppColors.gray500)),
        const SizedBox(height: AppSpacing.sm),
        for (final f in ExcelImportService.fields)
          _mappingRow(f.key, f.label, f.required, sheet.headers),
      ],
    );
  }

  Widget _mappingRow(
      String key, String label, bool required, List<String> headers) {
    final value = _indexForField(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              required ? '$label *' : label,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.md,
                border: Border.all(
                  color: required && value < 0
                      ? AppColors.red
                      : AppColors.gray200,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: value >= 0 ? value : null,
                  hint: Text('Select column',
                      style: AppTextStyles.bodyM
                          .copyWith(color: AppColors.gray500)),
                  items: [
                    if (!required)
                      DropdownMenuItem(
                          value: -1,
                          child: Text('— None —',
                              style: AppTextStyles.bodyM
                                  .copyWith(color: AppColors.gray500))),
                    for (var i = 0; i < headers.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                            headers[i].isEmpty ? 'Column ${i + 1}' : headers[i],
                            style: AppTextStyles.bodyM,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => _setField(key, v ?? -1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _indexForField(String key) => switch (key) {
        'date' => _mapping.date,
        'amount' => _mapping.amount,
        'type' => _mapping.type,
        'category' => _mapping.category,
        'source' => _mapping.source,
        _ => _mapping.note,
      };

  void _setField(String key, int idx) {
    setState(() {
      _mapping = switch (key) {
        'date' => _mapping.copyWith(date: idx),
        'amount' => _mapping.copyWith(amount: idx),
        'type' => _mapping.copyWith(type: idx),
        'category' => _mapping.copyWith(category: idx),
        'source' => _mapping.copyWith(source: idx),
        _ => _mapping.copyWith(note: idx),
      };
    });
  }

  // ─── Step 3 UI ────────────────────────────────────────

  Widget _duplicatesStep() {
    final parsed = _parsed!;
    final total = parsed.rows.length;
    final skipped = _skip.length;
    final toImport = total - skipped;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      children: [
        _banner(
          '$toImport new · $skipped skipped${_duplicates.isEmpty ? '' : ' (${_duplicates.length} duplicate${_duplicates.length == 1 ? '' : 's'} found)'}',
          AppColors.black,
          PhosphorIcons.copySimple(),
        ),
        if (parsed.errors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('${parsed.errors.length} row(s) skipped due to errors',
              style: AppTextStyles.labelM.copyWith(color: AppColors.red)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: const BoxDecoration(
                color: AppColors.white, borderRadius: AppRadius.xl),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in parsed.errors.take(20))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text('Row ${e.row}: ${e.message}',
                        style:
                            AppTextStyles.bodyS.copyWith(color: AppColors.red)),
                  ),
              ],
            ),
          ),
        ],
        if (_duplicates.isEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('No duplicates detected. All valid rows will be imported.',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
        ] else ...[
          const SizedBox(height: AppSpacing.lg),
          Text('DUPLICATES (uncheck to import anyway)',
              style: AppTextStyles.section.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: const BoxDecoration(
                color: AppColors.white, borderRadius: AppRadius.xl),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final i in _duplicates)
                  _duplicateRow(i, parsed.rows[i]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _duplicateRow(int index, ParsedRow row) {
    final skip = _skip.contains(index);
    return CheckboxListTile(
      value: skip,
      onChanged: (v) => setState(() {
        if (v == true) {
          _skip.add(index);
        } else {
          _skip.remove(index);
        }
      }),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.black,
      dense: true,
      title: Text(
        '${row.note ?? row.category} · ${row.amount.toStringAsFixed(0)}',
        style: AppTextStyles.bodyM,
      ),
      subtitle: Text(DateFormat('d MMM yyyy').format(row.date),
          style: AppTextStyles.labelM.copyWith(color: AppColors.gray500)),
    );
  }

  // ─── Step 4 UI ────────────────────────────────────────

  Widget _confirmStep() {
    final parsed = _parsed!;
    final importing = [
      for (var i = 0; i < parsed.rows.length; i++)
        if (!_skip.contains(i)) parsed.rows[i]
    ];
    final total =
        importing.fold<double>(0, (s, r) => s + r.amount.abs());
    final dates = importing.map((r) => r.date).toList()..sort();
    final range = dates.isEmpty
        ? '—'
        : '${DateFormat('d MMM').format(dates.first)} – ${DateFormat('d MMM yyyy').format(dates.last)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.xl,
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              _summaryRow('Transactions', '${importing.length}'),
              const Divider(height: AppSpacing.lg, color: AppColors.gray100),
              _summaryRow('Date range', range),
              const Divider(height: AppSpacing.lg, color: AppColors.gray100),
              _summaryRow('Total amount',
                  '₹${NumberFormat('#,##,###').format(total.toInt())}'),
            ],
          ),
        ),
        if (_importError != null) ...[
          const SizedBox(height: AppSpacing.md),
          _banner(_importError!, AppColors.red, PhosphorIcons.warningCircle()),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Importing runs as a single all-or-nothing operation — if anything '
          'fails, nothing is added.',
          style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
        Text(value,
            style: AppTextStyles.bodyM.copyWith(
                color: AppColors.black, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ─── Bottom bar ───────────────────────────────────────

  Widget _bottomBar() {
    final canNext = switch (_step) {
      0 => _file != null && _fileError == null,
      1 => _mapping.isComplete,
      2 => (_parsed?.rows.length ?? 0) - _skip.length > 0,
      _ => (_parsed?.rows.length ?? 0) - _skip.length > 0,
    };
    final label = switch (_step) {
      2 => 'Review & continue',
      3 => 'Import',
      _ => 'Next',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.ghost,
                label: 'Back',
                onTap: _busy ? () {} : _back,
                disabled: _busy,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            flex: 2,
            child: AppButton(
              label: _busy ? 'Working…' : label,
              onTap: (canNext && !_busy) ? _next : () {},
              disabled: !canNext || _busy,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared bits ──────────────────────────────────────

  Widget _banner(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdLg,
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodyM.copyWith(color: color)),
          ),
        ],
      ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
