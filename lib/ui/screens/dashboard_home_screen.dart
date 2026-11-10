import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tactical_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/survival_mode.dart';
import '../../providers/survival_providers.dart';
import '../widgets/monthly_digest_modal.dart';

class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final account = ref.watch(accountProvider);
    final householdCount = ref.watch(householdCountProvider);
    final isHouseholdConfigured = ref.watch(householdConfiguredProvider);
    final allItems = ref.watch(inventoryProvider);
    final expiringDigestItems = ref.watch(expiringDigestItemsProvider);
    final inspection = ref.watch(inspectionProvider);

    final bagItems = allItems
        .where((e) => e.mode == SurvivalMode.survivalBag && !e.isConsumed)
        .toList();
    final bagTotal = bagItems.length;
    final bagOwned = bagItems.where((e) => e.isOwned).length;
    final bagMissing = bagTotal - bagOwned;
    final bagPercent = bagTotal == 0 ? 0 : ((bagOwned / bagTotal) * 100).round();

    final shelterItems = allItems
        .where((e) => e.mode == SurvivalMode.shelterInPlace && !e.isConsumed)
        .toList();
    final shelterTotal = shelterItems.length;
    final shelterOwned = shelterItems.where((e) => e.isOwned).length;
    final shelterMissing = shelterTotal - shelterOwned;
    final shelterPercent =
        shelterTotal == 0 ? 0 : ((shelterOwned / shelterTotal) * 100).round();

    final overallTotal = bagTotal + shelterTotal;
    final overallOwned = bagOwned + shelterOwned;
    final overallPercent =
        overallTotal == 0 ? 0 : ((overallOwned / overallTotal) * 100).round();

    final daysUntilInspection = inspection.daysRemaining(DateTime.now());
    final isInspectionOverdue = daysUntilInspection <= 0;
    final nextInspectionDate = inspection.nextInspectionDate;
    final formattedNextInspectionDate = locale.languageCode == 'ko'
        ? '${nextInspectionDate.year}년 ${nextInspectionDate.month}월 ${nextInspectionDate.day}일'
        : '${nextInspectionDate.year}-${nextInspectionDate.month.toString().padLeft(2, '0')}-${nextInspectionDate.day.toString().padLeft(2, '0')}';
    final inspectionDDay = daysUntilInspection > 0
        ? 'D-$daysUntilInspection'
        : (daysUntilInspection == 0 ? 'D-Day' : 'D+${daysUntilInspection.abs()}');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: TacticalTheme.amber500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.appTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          // 0. Actionable Setup Warning Banners (Unconfigured Household / Unlinked Guest Account)
          if (!isHouseholdConfigured) ...[
            _SetupWarningBanner(
              icon: Icons.groups_rounded,
              message: l10n.homeWarnHouseholdUnset,
              actionLabel: l10n.homeWarnTapToSettings,
              accentColor: TacticalTheme.amber500,
              onTap: () => ref.read(activeTabIndexProvider.notifier).state = 4,
            ),
            const SizedBox(height: 8),
          ],
          if (!account.isGoogleLinked) ...[
            _SetupWarningBanner(
              icon: Icons.cloud_off_rounded,
              message: l10n.homeWarnAccountUnlinked(account.guestId),
              actionLabel: l10n.homeWarnTapToSettings,
              accentColor: const Color(0xFFFB923C),
              onTap: () => ref.read(activeTabIndexProvider.notifier).state = 4,
            ),
            const SizedBox(height: 12),
          ],

          // 1. Overall Preparedness Summary Hero Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TacticalTheme.slate800, Color(0xFF162238)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TacticalTheme.amber500.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: overallTotal == 0
                            ? 0
                            : overallOwned / overallTotal,
                        strokeWidth: 7,
                        backgroundColor: TacticalTheme.slate900,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overallPercent >= 80
                              ? TacticalTheme.emerald500
                              : TacticalTheme.amber500,
                        ),
                      ),
                      Center(
                        child: Text(
                          '$overallPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashboardOverallTitle,
                        style: const TextStyle(
                          color: TacticalTheme.amber500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dashboardOverallStatus(overallPercent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dashboardPackedVsMissing(
                          overallOwned,
                          overallTotal - overallOwned,
                        ),
                        style: const TextStyle(
                          color: TacticalTheme.slate400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. 72h Survival Bag Readiness Card (Tapping jumps to Tab 1)
          _ModeSummaryCard(
            icon: Icons.hiking,
            title: l10n.modeSurvivalBag,
            percent: bagPercent,
            ownedCount: bagOwned,
            missingCount: bagMissing,
            totalCount: bagTotal,
            accentColor: TacticalTheme.amber500,
            tapHint: l10n.dashboardTapToManage,
            onTap: () {
              ref.read(activeModeProvider.notifier).state =
                  SurvivalMode.survivalBag;
              ref.read(activeTabIndexProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 12),

          // 3. 30d Shelter-in-Place Readiness Card (Tapping jumps to Tab 2)
          _ModeSummaryCard(
            icon: Icons.home_work_outlined,
            title: l10n.modeShelterInPlace,
            percent: shelterPercent,
            ownedCount: shelterOwned,
            missingCount: shelterMissing,
            totalCount: shelterTotal,
            accentColor: TacticalTheme.emerald500,
            tapHint: l10n.dashboardTapToManage,
            onTap: () {
              ref.read(activeModeProvider.notifier).state =
                  SurvivalMode.shelterInPlace;
              ref.read(activeTabIndexProvider.notifier).state = 2;
            },
          ),
          const SizedBox(height: 14),

          // 4. Monthly Rolling Stock Digest Summary Card (Show ONLY when items are expiring)
          if (expiringDigestItems.isNotEmpty) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => MonthlyDigestModal.show(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TacticalTheme.slate800,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TacticalTheme.amber500),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: TacticalTheme.amber500,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.monthlyDigestTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.monthlyDigestBanner(
                              expiringDigestItems.length,
                            ),
                            style: const TextStyle(
                              color: TacticalTheme.amber500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: TacticalTheme.amber500,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 5. 6-Month Periodic Inspection Compact Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TacticalTheme.slate800,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TacticalTheme.slate700),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.battery_charging_full,
                  color: isInspectionOverdue
                      ? TacticalTheme.red500
                      : TacticalTheme.amber500,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.inspectionTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$formattedNextInspectionDate ($inspectionDDay)',
                        style: TextStyle(
                          color: isInspectionOverdue
                              ? TacticalTheme.red500
                              : TacticalTheme.slate400,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TacticalTheme.amber500,
                    side: const BorderSide(color: TacticalTheme.amber500),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () async {
                    await ref
                        .read(inspectionProvider.notifier)
                        .completeInspection();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.inspectionResetToast)),
                      );
                    }
                  },
                  child: Text(
                    l10n.completeInspection,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupWarningBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final Color accentColor;
  final VoidCallback onTap;

  const _SetupWarningBanner({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.14),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: accentColor.withOpacity(0.65)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              actionLabel,
              style: TextStyle(
                color: accentColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int percent;
  final int ownedCount;
  final int missingCount;
  final int totalCount;
  final Color accentColor;
  final String tapHint;
  final VoidCallback onTap;

  const _ModeSummaryCard({
    required this.icon,
    required this.title,
    required this.percent,
    required this.ownedCount,
    required this.missingCount,
    required this.totalCount,
    required this.accentColor,
    required this.tapHint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = totalCount == 0 ? 0.0 : ownedCount / totalCount;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TacticalTheme.slate800,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TacticalTheme.slate700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: TacticalTheme.slate900,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dashboardPackedVsMissing(ownedCount, missingCount),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  tapHint,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
