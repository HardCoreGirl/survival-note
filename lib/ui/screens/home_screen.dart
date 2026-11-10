import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tactical_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../models/preset_item.dart';
import '../../models/survival_mode.dart';
import '../../providers/survival_providers.dart';
import '../widgets/add_item_bottom_sheet.dart';
import '../widgets/affiliate_purchase_dialog.dart';
import '../widgets/year_month_picker_dialog.dart';

class HomeScreen extends ConsumerWidget {
  final SurvivalMode mode;

  const HomeScreen({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ownershipFilter = ref.watch(ownershipFilterProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final householdCount = ref.watch(householdCountProvider);
    final allItems = ref.watch(inventoryProvider);

    final modeItems = allItems
        .where((item) => item.mode == mode && !item.isConsumed)
        .toList();

    final categories = SurvivalCatalog.categoriesForMode(mode);
    final effectiveCategory =
        (selectedCategory != null && categories.contains(selectedCategory))
            ? selectedCategory
            : null;

    final items = modeItems.where((item) {
      if (ownershipFilter == OwnershipFilter.owned && !item.isOwned) {
        return false;
      }
      if (ownershipFilter == OwnershipFilter.missing && item.isOwned) {
        return false;
      }
      if (effectiveCategory != null && item.category != effectiveCategory) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.displayOrder != b.displayOrder) {
          return a.displayOrder.compareTo(b.displayOrder);
        }
        if (a.hasExpiry != b.hasExpiry) {
          return a.hasExpiry ? -1 : 1;
        }
        if (a.hasExpiry && b.hasExpiry) {
          final cmp = a.expiryMonth.compareTo(b.expiryMonth);
          if (cmp != 0) return cmp;
        }
        return a.id.compareTo(b.id);
      });

    final totalCount = modeItems.length;
    final ownedCount = modeItems.where((e) => e.isOwned).length;
    final missingCount = totalCount - ownedCount;
    final readinessPercent =
        totalCount == 0 ? 0 : ((ownedCount / totalCount) * 100).round();

    final isBagMode = mode == SurvivalMode.survivalBag;
    final screenTitle =
        isBagMode ? l10n.modeSurvivalBag : l10n.modeShelterInPlace;
    final screenIcon = isBagMode ? Icons.hiking : Icons.home_work_outlined;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(screenIcon, color: TacticalTheme.amber500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$screenTitle ($ownedCount/$totalCount)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Compact Headcount Badge -> Tapping jumps to Settings Tab (index 3)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              backgroundColor: TacticalTheme.slate800,
              side: const BorderSide(color: TacticalTheme.slate700),
              visualDensity: VisualDensity.compact,
              avatar: const Icon(
                Icons.groups_rounded,
                size: 16,
                color: TacticalTheme.amber500,
              ),
              label: Text(
                l10n.householdPeopleCount(householdCount),
                style: const TextStyle(
                  color: TacticalTheme.amber500,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                ref.read(activeTabIndexProvider.notifier).state = 4;
              },
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Slim Progress Line
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalCount == 0 ? 0 : ownedCount / totalCount,
                      minHeight: 5,
                      backgroundColor: TacticalTheme.slate800,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        readinessPercent >= 80
                            ? TacticalTheme.emerald500
                            : TacticalTheme.amber500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Ownership Status Filter Tabs (전체 / ✓ 보유중 / ☐ 미보유)
                  Row(
                    children: [
                      Expanded(
                        child: _OwnershipFilterChip(
                          label: l10n.filterAll(totalCount),
                          selected: ownershipFilter == OwnershipFilter.all,
                          activeColor: TacticalTheme.amber500,
                          onTap: () => ref
                              .read(ownershipFilterProvider.notifier)
                              .state = OwnershipFilter.all,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OwnershipFilterChip(
                          label: l10n.filterOwned(ownedCount),
                          selected: ownershipFilter == OwnershipFilter.owned,
                          activeColor: TacticalTheme.emerald500,
                          onTap: () => ref
                              .read(ownershipFilterProvider.notifier)
                              .state = OwnershipFilter.owned,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OwnershipFilterChip(
                          label: l10n.filterMissing(missingCount),
                          selected: ownershipFilter == OwnershipFilter.missing,
                          activeColor: TacticalTheme.red500,
                          onTap: () => ref
                              .read(ownershipFilterProvider.notifier)
                              .state = OwnershipFilter.missing,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(l10n.allCategories),
                          selected: effectiveCategory == null,
                          selectedColor: TacticalTheme.amber500,
                          labelStyle: TextStyle(
                            color: effectiveCategory == null
                                ? TacticalTheme.slate900
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => ref
                              .read(selectedCategoryProvider.notifier)
                              .state = null,
                        ),
                        const SizedBox(width: 8),
                        ...categories.map((cat) {
                          final isSelected = effectiveCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(l10n.localizeCategory(cat)),
                              selected: isSelected,
                              selectedColor: TacticalTheme.amber500,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? TacticalTheme.slate900
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) => ref
                                  .read(selectedCategoryProvider.notifier)
                                  .state = isSelected ? null : cat,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 5. Checklist Inventory List
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l10n.emptyInventory,
                  style: const TextStyle(color: TacticalTheme.slate400),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _SupplyItemCard(
                    item: items[index],
                    householdCount: householdCount,
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(activeModeProvider.notifier).state = mode;
          AddItemBottomSheet.show(context);
        },
        icon: const Icon(Icons.add),
        label: Text(
          l10n.addItem,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _OwnershipFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _OwnershipFilterChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.2)
              : TacticalTheme.slate800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : TacticalTheme.slate700,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? activeColor : TacticalTheme.slate400,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SupplyItemCard extends ConsumerWidget {
  final Item item;
  final int householdCount;

  const _SupplyItemCard({
    required this.item,
    required this.householdCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isKo = ref.watch(localeProvider).languageCode == 'ko';
    final now = DateTime.now();
    final daysLeft = item.daysUntilExpiry(now);

    Color badgeColor = TacticalTheme.slate400;
    String badgeText = l10n.missingBadge;

    if (item.isOwned) {
      if (!item.hasExpiry) {
        badgeColor = TacticalTheme.emerald500;
        badgeText = l10n.permanentGearBadge;
      } else if (daysLeft < 0) {
        badgeColor = TacticalTheme.red500;
        badgeText = l10n.expiredBadge;
      } else if (daysLeft <= 30) {
        badgeColor = TacticalTheme.red500;
        badgeText = l10n.d30Badge;
      } else if (daysLeft <= 60) {
        badgeColor = TacticalTheme.amber500;
        badgeText = l10n.d60Badge;
      } else {
        badgeColor = TacticalTheme.emerald500;
        badgeText = l10n.safeBadge;
      }
    }

    final showRollingResetButton =
        item.isOwned && item.hasExpiry && daysLeft <= 60;

    return Card(
      color: item.isOwned
          ? TacticalTheme.slate800
          : TacticalTheme.slate900.withValues(alpha: 0.6),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isOwned
              ? TacticalTheme.slate700
              : TacticalTheme.slate800,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            ref.read(inventoryProvider.notifier).toggleItemOwned(item.id),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: item.isOwned
                    ? TacticalTheme.emerald500
                    : TacticalTheme.amber500.withValues(alpha: 0.6),
                width: 3.5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interactive Checkbox ("있다 / 없다")
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 2),
                    child: Icon(
                      item.isOwned
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: item.isOwned
                          ? TacticalTheme.emerald500
                          : TacticalTheme.slate400,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                item.displayName(isKo),
                                style: TextStyle(
                                  color: item.isOwned
                                      ? Colors.white
                                      : TacticalTheme.slate400,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Recommended Quantity Badge scaled by Household Count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: TacticalTheme.amber500.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color:
                                      TacticalTheme.amber500.withOpacity(0.6),
                                ),
                              ),
                              child: Text(
                                item.formattedRecommendedQuantity(
                                  householdCount,
                                  isKo,
                                ),
                                style: const TextStyle(
                                  color: TacticalTheme.amber500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              l10n.localizeCategory(item.category),
                              style: const TextStyle(
                                color: TacticalTheme.slate400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge, Edit Button & Expiry Month
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isOwned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeColor),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          else
                            // High-converting prominent Buy button for missing items
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                AffiliatePurchaseDialog.show(
                                  context,
                                  item: item,
                                  householdCount: householdCount,
                                  isKo: isKo,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: TacticalTheme.amber500,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 13,
                                      color: TacticalTheme.slate900,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isKo ? '구매' : 'Buy',
                                      style: const TextStyle(
                                        color: TacticalTheme.slate900,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          // Edit Item / Memo Button
                          IconButton(
                            onPressed: () {
                              AddItemBottomSheet.show(
                                context,
                                existingItem: item,
                              );
                            },
                            icon: const Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                              color: TacticalTheme.slate400,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            tooltip: l10n.editItem,
                          ),
                        ],
                      ),
                      if (item.isOwned && item.hasExpiry) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () async {
                            final picked = await YearMonthPickerDialog.show(
                              context,
                              initialDate: item.expiryMonth,
                            );
                            if (picked != null) {
                              await ref
                                  .read(inventoryProvider.notifier)
                                  .updateItemExpiry(item.id, picked);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 13,
                                color: TacticalTheme.amber500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.formattedExpiryMonth,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Optional Memo Display Block
              if (item.memo != null && item.memo!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: TacticalTheme.slate900.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TacticalTheme.slate700),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 14,
                        color: TacticalTheme.amber500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.memo!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (showRollingResetButton) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: TacticalTheme.amber500,
                        foregroundColor: TacticalTheme.slate900,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        final updated = await ref
                            .read(inventoryProvider.notifier)
                            .consumeAndRestock(item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.restockedToast(
                                  updated.displayName(isKo),
                                  updated.defaultShelfLifeMonths,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.autorenew, size: 16),
                      label: Text(
                        l10n.consumeAndRestock(item.defaultShelfLifeMonths),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
