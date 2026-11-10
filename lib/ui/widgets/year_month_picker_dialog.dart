import 'package:flutter/material.dart';
import '../../core/theme/tactical_theme.dart';
import '../../l10n/app_localizations.dart';

/// Custom Year-Month (`YYYY-MM`) wheel/grid dialog picker so users never have to
/// enter exact day-of-month dates when registering survival supplies.
class YearMonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const YearMonthPickerDialog({
    super.key,
    required this.initialDate,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (_) => YearMonthPickerDialog(initialDate: initialDate),
    );
  }

  @override
  State<YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<YearMonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentYear = DateTime.now().year;
    final years = List.generate(15, (i) => currentYear + i);

    return AlertDialog(
      backgroundColor: TacticalTheme.slate800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: TacticalTheme.slate700),
      ),
      title: Text(
        l10n.selectYearMonth,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year Selector Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: TacticalTheme.slate900,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TacticalTheme.slate700),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  dropdownColor: TacticalTheme.slate900,
                  style: const TextStyle(
                    color: TacticalTheme.amber500,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  items: years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text('$y'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedYear = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 12-Month Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == _selectedMonth;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _selectedMonth = month),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? TacticalTheme.amber500
                          : TacticalTheme.slate900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? TacticalTheme.amber500
                            : TacticalTheme.slate700,
                      ),
                    ),
                    child: Text(
                      month.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: isSelected
                            ? TacticalTheme.slate900
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: TacticalTheme.slate400),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: TacticalTheme.amber500,
            foregroundColor: TacticalTheme.slate900,
          ),
          onPressed: () {
            Navigator.of(context).pop(DateTime(_selectedYear, _selectedMonth, 1));
          },
          child: Text(
            l10n.confirm,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
