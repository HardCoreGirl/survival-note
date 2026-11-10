import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tactical_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/survival_mode.dart';
import '../../providers/survival_providers.dart';
import 'community_board_screen.dart';
import 'dashboard_home_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  final List<int> _tabHistory = [0];
  LocalHistoryEntry? _historyEntry;
  bool _isPoppingHistory = false;

  static const List<String> _tabPaths = [
    '/home',
    '/bag',
    '/shelter',
    '/board',
    '/settings',
  ];

  @override
  void initState() {
    super.initState();
    // 백그라운드에서 gurren-api 게스트 로그인 자동 시도
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(accountProvider.notifier).loginAsGuest();
      }
    });
  }

  void _syncBrowserHistoryEntry(int nextIndex) {
    // Update browser URL & history stack so browser Back button works
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(_tabPaths[nextIndex]),
    );

    if (_historyEntry == null && _tabHistory.length > 1) {
      _historyEntry = LocalHistoryEntry(
        onRemove: () {
          _historyEntry = null;
          if (_tabHistory.length > 1) {
            _isPoppingHistory = true;
            _tabHistory.removeLast();
            final previousTab = _tabHistory.last;
            ref.read(activeTabIndexProvider.notifier).state = previousTab;
            _syncModeForTab(previousTab);
            _isPoppingHistory = false;

            // If there is still more history to pop, re-attach a LocalHistoryEntry
            if (_tabHistory.length > 1 && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _ensureLocalHistoryAttached();
                }
              });
            }
          }
        },
      );
      ModalRoute.of(context)?.addLocalHistoryEntry(_historyEntry!);
    }
  }

  void _ensureLocalHistoryAttached() {
    if (_historyEntry == null && _tabHistory.length > 1) {
      _historyEntry = LocalHistoryEntry(
        onRemove: () {
          _historyEntry = null;
          if (_tabHistory.length > 1) {
            _isPoppingHistory = true;
            _tabHistory.removeLast();
            final previousTab = _tabHistory.last;
            ref.read(activeTabIndexProvider.notifier).state = previousTab;
            _syncModeForTab(previousTab);
            _isPoppingHistory = false;

            if (_tabHistory.length > 1 && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _ensureLocalHistoryAttached();
                }
              });
            }
          }
        },
      );
      ModalRoute.of(context)?.addLocalHistoryEntry(_historyEntry!);
    }
  }

  void _syncModeForTab(int idx) {
    if (idx == 1) {
      ref.read(activeModeProvider.notifier).state = SurvivalMode.survivalBag;
      ref.read(selectedCategoryProvider.notifier).state = null;
    } else if (idx == 2) {
      ref.read(activeModeProvider.notifier).state = SurvivalMode.shelterInPlace;
      ref.read(selectedCategoryProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentIndex = ref.watch(activeTabIndexProvider);

    // Listen to tab changes (including jumps from Home warning banners or AppBar chips)
    ref.listen<int>(activeTabIndexProvider, (previous, next) {
      if (_isPoppingHistory) return;
      if (previous != next) {
        if (_tabHistory.isEmpty || _tabHistory.last != next) {
          _tabHistory.add(next);
        }
        _syncModeForTab(next);
        _syncBrowserHistoryEntry(next);
      }
    });

    const screens = [
      DashboardHomeScreen(),
      HomeScreen(mode: SurvivalMode.survivalBag),
      HomeScreen(mode: SurvivalMode.shelterInPlace),
      CommunityBoardScreen(),
      SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_tabHistory.length > 1) {
          _tabHistory.removeLast();
          final previousTab = _tabHistory.last;
          ref.read(activeTabIndexProvider.notifier).state = previousTab;
          _syncModeForTab(previousTab);
        } else if (currentIndex != 0) {
          ref.read(activeTabIndexProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: TacticalTheme.slate800,
          indicatorColor: TacticalTheme.amber500,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (idx) {
            if (idx == currentIndex) return;
            ref.read(activeTabIndexProvider.notifier).state = idx;
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(
                Icons.dashboard_outlined,
                color: TacticalTheme.slate400,
              ),
              selectedIcon: const Icon(
                Icons.dashboard_rounded,
                color: TacticalTheme.slate900,
              ),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(
                Icons.hiking_outlined,
                color: TacticalTheme.slate400,
              ),
              selectedIcon: const Icon(
                Icons.hiking,
                color: TacticalTheme.slate900,
              ),
              label: l10n.navBag,
            ),
            NavigationDestination(
              icon: const Icon(
                Icons.home_work_outlined,
                color: TacticalTheme.slate400,
              ),
              selectedIcon: const Icon(
                Icons.home_work_rounded,
                color: TacticalTheme.slate900,
              ),
              label: l10n.navShelter,
            ),
            NavigationDestination(
              icon: const Icon(
                Icons.forum_outlined,
                color: TacticalTheme.slate400,
              ),
              selectedIcon: const Icon(
                Icons.forum_rounded,
                color: TacticalTheme.slate900,
              ),
              label: l10n.navBoard,
            ),
            NavigationDestination(
              icon: const Icon(
                Icons.settings_outlined,
                color: TacticalTheme.slate400,
              ),
              selectedIcon: const Icon(
                Icons.settings_rounded,
                color: TacticalTheme.slate900,
              ),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
