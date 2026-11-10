import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/tactical_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/survival_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _monthlyDigestEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(accountProvider);
    final householdCount = ref.watch(householdCountProvider);
    final isHouseholdConfigured = ref.watch(householdConfiguredProvider);
    final inspection = ref.watch(inspectionProvider);
    final locale = ref.watch(localeProvider);
    final isKo = locale.languageCode == 'ko';
    final daysRemaining = inspection.daysRemaining(DateTime.now());
    final isOverdue = daysRemaining <= 0;
    final nextDate = inspection.nextInspectionDate;
    final formattedNextDate = isKo
        ? '${nextDate.year}년 ${nextDate.month}월 ${nextDate.day}일'
        : '${nextDate.year}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}';
    final inspectionDDay = daysRemaining > 0
        ? 'D-$daysRemaining'
        : (daysRemaining == 0 ? 'D-Day' : 'D+${daysRemaining.abs()}');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.tune_rounded, color: TacticalTheme.amber500),
            const SizedBox(width: 8),
            Text(l10n.navSettings),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. Account & Guest ID / Google Linking Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TacticalTheme.slate800,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: account.isGoogleLinked
                    ? TacticalTheme.emerald500.withOpacity(0.6)
                    : TacticalTheme.amber500.withOpacity(0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      account.isGoogleLinked
                          ? Icons.cloud_done_rounded
                          : Icons.person_pin_circle_outlined,
                      color: account.isGoogleLinked
                          ? TacticalTheme.emerald500
                          : TacticalTheme.amber500,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.accountSectionTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (account.isGoogleLinked
                                ? TacticalTheme.emerald500
                                : TacticalTheme.amber500)
                            .withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: account.isGoogleLinked
                              ? TacticalTheme.emerald500
                              : TacticalTheme.amber500,
                        ),
                      ),
                      child: Text(
                        account.isGoogleLinked
                            ? l10n.googleLinkedBadge
                            : l10n.guestBadge,
                        style: TextStyle(
                          color: account.isGoogleLinked
                              ? TacticalTheme.emerald500
                              : TacticalTheme.amber500,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Unified Profile Info Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TacticalTheme.slate900,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TacticalTheme.slate700),
                  ),
                  child: Column(
                    children: [
                      // Row 1: 회원 아이디 (Account ID)
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: TacticalTheme.amber500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isKo ? '회원 ID' : 'Account ID',
                            style: const TextStyle(
                              color: TacticalTheme.slate400,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            account.serverDisplayId ?? account.guestId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: TacticalTheme.slate800, height: 1),
                      ),
                      // Row 2: 닉네임 (Nickname)
                      Row(
                        children: [
                          const Icon(
                            Icons.face_outlined,
                            size: 18,
                            color: TacticalTheme.emerald500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isKo ? '닉네임' : 'Nickname',
                            style: const TextStyle(
                              color: TacticalTheme.slate400,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            account.serverDisplayName ?? (isKo ? '생존자' : 'Survivor'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (account.isGoogleLinked && account.linkedEmail != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: TacticalTheme.slate800, height: 1),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: Color(0xFF4285F4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isKo ? '연동 이메일' : 'Email',
                              style: const TextStyle(
                                color: TacticalTheme.slate400,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              account.linkedEmail!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Account Explanation Text
                Text(
                  account.isGoogleLinked
                      ? (isKo
                          ? 'Google 계정에 안전하게 연동되어 브라우저 캐시를 지우거나 기기를 변경해도 데이터가 보존됩니다.'
                          : 'Your data is safely backed up to your Google account.')
                      : (isKo
                          ? '현재 게스트 모드로 이용 중입니다. 브라우저 캐시 삭제 시 데이터가 유실되지 않도록 Google 계정을 연동해 두세요.'
                          : 'You are using Guest Mode. Link your Google account to prevent data loss when switching devices or clearing browser cache.'),
                  style: const TextStyle(
                    color: TacticalTheme.slate400,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: account.isGoogleLinked
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TacticalTheme.red500,
                            side: const BorderSide(
                              color: TacticalTheme.slate700,
                            ),
                          ),
                          onPressed: account.isLoading
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: TacticalTheme.slate800,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(color: TacticalTheme.slate700),
                                      ),
                                      title: Text(
                                        isKo ? 'Google 계정 로그아웃' : 'Disconnect Google',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      content: Text(
                                        isKo
                                            ? '로그아웃 하시겠습니까? 로컬 게스트 모드로 전환됩니다.'
                                            : 'Are you sure you want to disconnect? You will be switched to guest mode.',
                                        style: const TextStyle(color: TacticalTheme.slate300),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text(
                                            l10n.cancel,
                                            style: const TextStyle(color: TacticalTheme.slate400),
                                          ),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: TacticalTheme.red500,
                                          ),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text(
                                            isKo ? '로그아웃' : 'Disconnect',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && context.mounted) {
                                    await ref.read(accountProvider.notifier).logoutGoogle();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isKo
                                              ? '로그아웃 되었습니다. (게스트 모드로 전환)'
                                              : 'Logged out. (Switched to guest mode)'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: account.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: TacticalTheme.red500,
                                  ),
                                )
                              : const Icon(Icons.logout_rounded, size: 18),
                          label: Text(account.isLoading
                              ? (isKo ? '처리 중...' : 'Processing...')
                              : (isKo ? 'Google 계정 로그아웃' : 'Log out')),
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: TacticalTheme.slate900,
                          ),
                          onPressed: account.isLoading
                              ? null
                              : () async {
                                  final ok = await ref.read(accountProvider.notifier).loginWithGoogle();
                                  if (context.mounted) {
                                    if (ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isKo
                                              ? 'Google 계정으로 성공적으로 연동되었습니다.'
                                              : 'Successfully linked Google account.'),
                                        ),
                                      );
                                    } else {
                                      final err = ref.read(accountProvider).errorMessage;
                                      if (err != null && err.isNotEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: TacticalTheme.red500,
                                            content: Text(err),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          icon: account.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: TacticalTheme.slate900,
                                  ),
                                )
                              : const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 26,
                                  color: Color(0xFFEA4335),
                                ),
                          label: Text(
                            account.isLoading
                                ? (isKo ? '로그인 중...' : 'Signing in...')
                                : l10n.linkGoogleButton,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Household / Evacuee Count Configuration Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TacticalTheme.slate800,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHouseholdConfigured
                    ? TacticalTheme.slate700
                    : TacticalTheme.amber500,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: TacticalTheme.amber500,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.householdLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isHouseholdConfigured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    TacticalTheme.emerald500.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                l10n.householdConfirmedBadge,
                                style: const TextStyle(
                                  color: TacticalTheme.emerald500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: householdCount > 1
                          ? () => ref
                              .read(householdCountProvider.notifier)
                              .decrement()
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: TacticalTheme.amber500,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: TacticalTheme.amber500,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.householdPeopleCount(householdCount),
                        style: const TextStyle(
                          color: TacticalTheme.slate900,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: householdCount < 20
                          ? () => ref
                              .read(householdCountProvider.notifier)
                              .increment()
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: TacticalTheme.amber500,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.householdDescription,
                  style: const TextStyle(
                    color: TacticalTheme.slate400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. 6-Month Periodic Gear Inspection Section
          Container(
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
                    Icon(
                      Icons.battery_charging_full,
                      color: isOverdue
                          ? TacticalTheme.red500
                          : TacticalTheme.amber500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.inspectionTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isOverdue
                                ? TacticalTheme.red500
                                : TacticalTheme.amber500)
                            .withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$formattedNextDate ($inspectionDDay)',
                        style: TextStyle(
                          color: isOverdue
                              ? TacticalTheme.red500
                              : TacticalTheme.amber500,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.inspectionSubtitle,
                  style: const TextStyle(
                    color: TacticalTheme.slate400,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: TacticalTheme.amber500,
                      foregroundColor: TacticalTheme.slate900,
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
                    icon: const Icon(Icons.task_alt),
                    label: Text(
                      l10n.completeInspection,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Anti-Fatigue Notification Settings
          Container(
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
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: TacticalTheme.amber500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.settingsNotificationTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: TacticalTheme.amber500,
                    title: Text(
                      l10n.settingsMonthlyDigestToggle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.settingsMonthlyDigestDesc,
                        style: const TextStyle(
                          color: TacticalTheme.slate400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    value: _monthlyDigestEnabled,
                    onChanged: (val) =>
                        setState(() => _monthlyDigestEnabled = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Language Selection
          Container(
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
                    const Icon(
                      Icons.language_rounded,
                      color: TacticalTheme.amber500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.settingsLanguageTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('한국어 (Korean)')),
                        selected: locale.languageCode == 'ko',
                        selectedColor: TacticalTheme.amber500,
                        labelStyle: TextStyle(
                          color: locale.languageCode == 'ko'
                              ? TacticalTheme.slate900
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) =>
                            ref.read(localeProvider.notifier).setLocale('ko'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('English')),
                        selected: locale.languageCode == 'en',
                        selectedColor: TacticalTheme.amber500,
                        labelStyle: TextStyle(
                          color: locale.languageCode == 'en'
                              ? TacticalTheme.slate900
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) =>
                            ref.read(localeProvider.notifier).setLocale('en'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              final buildNumber = snapshot.data?.buildNumber ?? '1';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'Survival Note v$version+$buildNumber',
                    style: const TextStyle(
                      color: TacticalTheme.slate500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
