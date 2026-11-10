import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/tactical_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../models/preset_item.dart';
import '../../models/survival_mode.dart';
import '../../providers/survival_providers.dart';
import 'year_month_picker_dialog.dart';

class AddItemBottomSheet extends ConsumerStatefulWidget {
  final Item? existingItem;

  const AddItemBottomSheet({
    super.key,
    this.existingItem,
  });

  static Future<void> show(
    BuildContext context, {
    Item? existingItem,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TacticalTheme.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddItemBottomSheet(existingItem: existingItem),
    );
  }

  @override
  ConsumerState<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends ConsumerState<AddItemBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _memoController;
  late SurvivalMode _mode;
  late String _selectedCategory;
  late DateTime _expiryMonth;
  int _defaultShelfLifeMonths = 12;
  int _qtyPerPerson = 1;
  int _importance = 3;
  bool _hasExpiry = true;

  bool get _isEditing => widget.existingItem != null;
  bool get _isServerPreset =>
      widget.existingItem != null && widget.existingItem!.isPreset;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    final isKo = ref.read(localeProvider).languageCode == 'ko';

    if (existing != null) {
      _mode = existing.mode;
      _selectedCategory = existing.category;
      _nameController = TextEditingController(text: existing.displayName(isKo));
      _memoController = TextEditingController(text: existing.memo ?? '');
      _expiryMonth = existing.expiryMonth;
      _defaultShelfLifeMonths = existing.defaultShelfLifeMonths;
      _qtyPerPerson = existing.qtyPerPerson;
      _importance = existing.importance;
      _hasExpiry = existing.hasExpiry;
    } else {
      _mode = ref.read(activeModeProvider);
      _selectedCategory = SurvivalCatalog.categoriesForMode(_mode).first;
      _nameController = TextEditingController();
      _memoController = TextEditingController();
      final now = DateTime.now();
      _expiryMonth = DateTime(now.year, now.month + 12, 1);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final memoText = _memoController.text.trim();
    final isKo = ref.read(localeProvider).languageCode == 'ko';

    if (_isEditing) {
      final existing = widget.existingItem!;
      final updated = existing.copyWith(
        category: _isServerPreset ? existing.category : _selectedCategory,
        name: isKo ? existing.name : name,
        nameKo: isKo ? name : existing.nameKo,
        storageLocation: null,
        clearStorageLocation: true,
        memo: memoText.isEmpty ? null : memoText,
        clearMemo: memoText.isEmpty,
        expiryMonth: _expiryMonth,
        defaultShelfLifeMonths: _defaultShelfLifeMonths,
        hasExpiry: _hasExpiry,
        qtyPerPerson: _isServerPreset ? existing.qtyPerPerson : _qtyPerPerson,
        importance: _isServerPreset ? existing.importance : _importance,
      );
      await ref.read(inventoryProvider.notifier).updateItem(updated);
    } else {
      final item = Item(
        id: const Uuid().v4(),
        mode: _mode,
        category: _selectedCategory,
        name: name,
        nameKo: isKo ? name : null,
        storageLocation: null,
        memo: memoText.isEmpty ? null : memoText,
        expiryMonth: _expiryMonth,
        defaultShelfLifeMonths: _defaultShelfLifeMonths,
        isOwned: true,
        hasExpiry: _hasExpiry,
        qtyPerPerson: _qtyPerPerson,
        importance: _importance,
      );
      await ref.read(inventoryProvider.notifier).addItem(item);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existingItem;
    if (existing == null) return;
    await ref.read(inventoryProvider.notifier).deleteItem(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKo = ref.watch(localeProvider).languageCode == 'ko';
    final categories = SurvivalCatalog.categoriesForMode(_mode);
    final formattedYm =
        '${_expiryMonth.year}-${_expiryMonth.month.toString().padLeft(2, '0')}';

    final shelfLifeOptions = {6, 12, 24, 36, 60, _defaultShelfLifeMonths}
        .toList()
      ..sort();
    final qtyOptions = {1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 60, _qtyPerPerson}
        .toList()
      ..sort();

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TacticalTheme.slate700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? l10n.editItem : l10n.addItem,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isEditing)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: TacticalTheme.red500,
                    ),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.deleteItem),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Item or Pouch/Batch Name
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.itemNameLabel,
                hintText: l10n.itemNameHint,
                prefixIcon: const Icon(
                  Icons.inventory_2_outlined,
                  color: TacticalTheme.amber500,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category Dropdown + Qty Per Person
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: categories.contains(_selectedCategory)
                        ? _selectedCategory
                        : categories.first,
                    dropdownColor: TacticalTheme.slate900,
                    style: TextStyle(
                      color: _isServerPreset ? Colors.white70 : Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: _isServerPreset
                          ? (isKo ? '${l10n.categoryLabel} (수정 불가)' : '${l10n.categoryLabel} (Locked)')
                          : l10n.categoryLabel,
                      suffixIcon: _isServerPreset
                          ? const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: TacticalTheme.slate500,
                            )
                          : null,
                    ),
                    disabledHint: Text(
                      l10n.localizeCategory(_selectedCategory),
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                    items: categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              l10n.localizeCategory(cat),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isServerPreset
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _qtyPerPerson,
                    dropdownColor: TacticalTheme.slate900,
                    style: TextStyle(
                      color: _isServerPreset ? Colors.white70 : Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: _isServerPreset
                          ? (isKo ? '${l10n.qtyPerPersonLabel} (수정 불가)' : '${l10n.qtyPerPersonLabel} (Locked)')
                          : l10n.qtyPerPersonLabel,
                      suffixIcon: _isServerPreset
                          ? const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: TacticalTheme.slate500,
                            )
                          : null,
                    ),
                    disabledHint: Text(
                      '$_qtyPerPerson',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    items: qtyOptions
                        .map(
                          (q) => DropdownMenuItem(
                            value: q,
                            child: Text('$q'),
                          ),
                        )
                        .toList(),
                    onChanged: _isServerPreset
                        ? null
                        : (val) {
                            if (val != null) setState(() => _qtyPerPerson = val);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Optional Memo / Note Field
            TextField(
              controller: _memoController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.memoLabel,
                hintText: l10n.memoHint,
                prefixIcon: const Icon(
                  Icons.sticky_note_2_outlined,
                  color: TacticalTheme.amber500,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Toggle whether this item tracks expiration
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: TacticalTheme.amber500,
              title: Text(
                l10n.tracksExpiryLabel,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              value: _hasExpiry,
              onChanged: (val) => setState(() => _hasExpiry = val),
            ),

            if (_hasExpiry) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await YearMonthPickerDialog.show(
                          context,
                          initialDate: _expiryMonth,
                        );
                        if (picked != null) {
                          setState(() => _expiryMonth = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.expiryMonthLabel,
                          prefixIcon: const Icon(
                            Icons.calendar_month,
                            color: TacticalTheme.amber500,
                          ),
                        ),
                        child: Text(
                          formattedYm,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _defaultShelfLifeMonths,
                      dropdownColor: TacticalTheme.slate900,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: l10n.shelfLifeMonthsLabel,
                      ),
                      items: shelfLifeOptions
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text('+$m m'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _defaultShelfLifeMonths = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: TacticalTheme.amber500,
                  foregroundColor: TacticalTheme.slate900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _save,
                icon: Icon(_isEditing ? Icons.save_outlined : Icons.add_task),
                label: Text(
                  _isEditing ? l10n.saveChanges : l10n.saveItem,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
