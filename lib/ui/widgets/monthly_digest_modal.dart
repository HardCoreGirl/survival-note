import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tactical_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/survival_providers.dart';

class MonthlyDigestModal extends ConsumerWidget {
  const MonthlyDigestModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: TacticalTheme.slate800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const MonthlyDigestModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isKo = ref.watch(localeProvider).languageCode == 'ko';
    final expiringItems = ref.watch(expiringDigestItemsProvider);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: TacticalTheme.amber500,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.monthlyDigestTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.monthlyDigestSubtitle,
            style: const TextStyle(
              color: TacticalTheme.slate400,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: expiringItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = expiringItems[index];
                final daysLeft = item.daysUntilExpiry(now);
                final isUrgent = daysLeft <= 30;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TacticalTheme.slate900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUrgent
                          ? TacticalTheme.red500
                          : TacticalTheme.amber500,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName(isKo),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.formattedExpiryMonth} • ${l10n.localizeCategory(item.category)}',
                              style: const TextStyle(
                                color: TacticalTheme.slate400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: TacticalTheme.amber500,
                          foregroundColor: TacticalTheme.slate900,
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
                          '+${item.defaultShelfLifeMonths}m',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
