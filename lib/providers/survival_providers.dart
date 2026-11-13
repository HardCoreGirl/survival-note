import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/inspection_check.dart';
import '../models/item.dart';
import '../models/survival_mode.dart';
import '../repositories/storage_repository.dart';
import '../services/gurren_auth_service.dart';
import '../services/gurren_survival_service.dart';
import '../services/notification_service.dart';

enum OwnershipFilter {
  all,
  owned,
  missing,
}

class AccountState {
  final String guestId;
  final bool isGoogleLinked;
  final String? linkedEmail;
  final String? authToken;
  final String? refreshToken;
  final String? serverDisplayId;
  final String? serverDisplayName;
  final bool isLoading;
  final String? errorMessage;

  bool get isServerConnected => authToken != null && authToken!.isNotEmpty;

  const AccountState({
    required this.guestId,
    required this.isGoogleLinked,
    this.linkedEmail,
    this.authToken,
    this.refreshToken,
    this.serverDisplayId,
    this.serverDisplayName,
    this.isLoading = false,
    this.errorMessage,
  });

  AccountState copyWith({
    String? guestId,
    bool? isGoogleLinked,
    String? linkedEmail,
    bool clearEmail = false,
    String? authToken,
    bool clearAuthToken = false,
    String? refreshToken,
    bool clearRefreshToken = false,
    String? serverDisplayId,
    bool clearServerDisplayId = false,
    String? serverDisplayName,
    bool clearServerDisplayName = false,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AccountState(
      guestId: guestId ?? this.guestId,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
      linkedEmail: clearEmail ? null : (linkedEmail ?? this.linkedEmail),
      authToken: clearAuthToken ? null : (authToken ?? this.authToken),
      refreshToken:
          clearRefreshToken ? null : (refreshToken ?? this.refreshToken),
      serverDisplayId: clearServerDisplayId
          ? null
          : (serverDisplayId ?? this.serverDisplayId),
      serverDisplayName: clearServerDisplayName
          ? null
          : (serverDisplayName ?? this.serverDisplayName),
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AccountNotifier extends StateNotifier<AccountState> {
  final StorageRepository _repository;
  final GurrenAuthService _authService;
  final Ref _ref;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '713333044036-v0dvl7nk5rbe3phgghfagjm4mn6fnlhi.apps.googleusercontent.com',
    scopes: ['email'],
  );

  AccountNotifier(this._repository, this._authService, this._ref)
      : super(
          AccountState(
            guestId: _repository.getGuestId(),
            isGoogleLinked: _repository.isGoogleLinked(),
            linkedEmail: _repository.getLinkedEmail(),
            authToken: _repository.getAuthToken(),
            refreshToken: _repository.getRefreshToken(),
            serverDisplayId: _repository.getServerDisplayId(),
            serverDisplayName: _repository.getServerDisplayName(),
          ),
        ) {
    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _ref.read(inventoryProvider.notifier).syncWithServer(token);
    }
  }

  /// Google 계정으로 로그인 / 연동
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final tokenToSend = (googleAuth.idToken != null && googleAuth.idToken!.isNotEmpty)
          ? googleAuth.idToken!
          : (googleAuth.accessToken ?? '');
      if (tokenToSend.isEmpty) {
        throw Exception('구글 인증 토큰을 가져오지 못했습니다.');
      }

      final result = await _authService.loginWithGoogle(tokenToSend);
      final displayName = result.displayName.isNotEmpty
          ? result.displayName
          : (googleUser.displayName ?? 'Google User');

      await _repository.saveAuthSession(
        token: result.token,
        refreshToken: result.refreshToken,
        displayId: result.displayId,
        displayName: displayName,
      );
      await _repository.setGoogleLinked(isLinked: true, email: googleUser.email);

      state = state.copyWith(
        isGoogleLinked: true,
        linkedEmail: googleUser.email,
        authToken: result.token,
        refreshToken: result.refreshToken,
        serverDisplayId: result.displayId,
        serverDisplayName: displayName,
        isLoading: false,
        clearErrorMessage: true,
      );

      // 새 구글 계정의 서버 아이템과 동기화
      await _ref.read(inventoryProvider.notifier).syncWithServer(result.token);
      return true;
    } catch (e) {
      debugPrint('Google login error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Google 로그아웃 (다시 로컬 게스트 계정으로 전환)
  Future<void> logoutGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _repository.clearAuthSession();
    await _repository.setGoogleLinked(isLinked: false, email: null);

    state = state.copyWith(
      isGoogleLinked: false,
      clearEmail: true,
      clearAuthToken: true,
      clearRefreshToken: true,
      clearServerDisplayId: true,
      clearServerDisplayName: true,
      isLoading: false,
    );

    await loginAsGuest(force: true);
  }

  Future<void> linkWithGoogle(String email) async {
    await _repository.setGoogleLinked(isLinked: true, email: email);
    state = state.copyWith(isGoogleLinked: true, linkedEmail: email);
  }

  Future<void> unlinkGoogle() async {
    await logoutGoogle();
  }

  /// Gurren API 서버에 게스트 계정으로 로그인 수행
  Future<bool> loginAsGuest({bool force = false}) async {
    // 1. 이미 현재 메모리(state)에 연결되어 있고 강제 재로그인이 아니면 유지
    if (!force && state.isServerConnected) {
      return true;
    }

    // 2. 저장소(SharedPreferences/Hive)에 기존 계정 토큰이 저장되어 있다면 복원하여 재사용
    final savedToken = _repository.getAuthToken();
    final savedRefreshToken = _repository.getRefreshToken();
    final savedDisplayId = _repository.getServerDisplayId();
    final savedDisplayName = _repository.getServerDisplayName();

    if (!force && savedToken != null && savedToken.isNotEmpty) {
      state = state.copyWith(
        authToken: savedToken,
        refreshToken: savedRefreshToken,
        serverDisplayId: savedDisplayId,
        serverDisplayName: savedDisplayName,
        isLoading: false,
        clearErrorMessage: true,
      );
      _ref.read(inventoryProvider.notifier).syncWithServer(savedToken);
      return true;
    }

    // 3. 토큰이 비어있지만 리프레시 토큰이 남아있는 경우 기존 계정 토큰 갱신 시도
    if (!force && savedRefreshToken != null && savedRefreshToken.isNotEmpty) {
      try {
        final refreshed = await _authService.refreshToken(savedRefreshToken);
        await _repository.saveAuthSession(
          token: refreshed.token,
          refreshToken: refreshed.refreshToken.isNotEmpty
              ? refreshed.refreshToken
              : savedRefreshToken,
          displayId: refreshed.displayId.isNotEmpty
              ? refreshed.displayId
              : (savedDisplayId ?? ''),
          displayName: refreshed.displayName.isNotEmpty
              ? refreshed.displayName
              : (savedDisplayName ?? ''),
        );
        state = state.copyWith(
          authToken: refreshed.token,
          refreshToken: refreshed.refreshToken.isNotEmpty
              ? refreshed.refreshToken
              : savedRefreshToken,
          serverDisplayId: refreshed.displayId.isNotEmpty
              ? refreshed.displayId
              : savedDisplayId,
          serverDisplayName: refreshed.displayName.isNotEmpty
              ? refreshed.displayName
              : savedDisplayName,
          isLoading: false,
          clearErrorMessage: true,
        );
        _ref.read(inventoryProvider.notifier).syncWithServer(refreshed.token);
        return true;
      } catch (_) {
        // refresh 실패 시 신규 등록으로 폴백
      }
    }

    // 4. 저장된 계정이 전혀 없는 최초 실행이거나 force==true일 때만 신규 게스트 등록!
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final result = await _authService.registerGuest();
      await _repository.saveAuthSession(
        token: result.token,
        refreshToken: result.refreshToken,
        displayId: result.displayId,
        displayName: result.displayName,
      );

      state = state.copyWith(
        authToken: result.token,
        refreshToken: result.refreshToken,
        serverDisplayId: result.displayId,
        serverDisplayName: result.displayName,
        isLoading: false,
        clearErrorMessage: true,
      );
      _ref.read(inventoryProvider.notifier).syncWithServer(result.token);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// 서버 세션 초기화
  Future<void> clearServerSession() async {
    await _repository.clearAuthSession();
    state = state.copyWith(
      clearAuthToken: true,
      clearRefreshToken: true,
      clearServerDisplayId: true,
      clearServerDisplayName: true,
      clearErrorMessage: true,
    );
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  throw UnimplementedError('StorageRepository must be overridden in main()');
});

final gurrenAuthServiceProvider = Provider<GurrenAuthService>((ref) {
  return GurrenAuthService();
});

final gurrenSurvivalServiceProvider = Provider<GurrenSurvivalService>((ref) {
  return GurrenSurvivalService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  final repo = ref.watch(storageRepositoryProvider);
  final authService = ref.watch(gurrenAuthServiceProvider);
  return AccountNotifier(repo, authService, ref);
});

/// Active Bottom Navigation Tab Index (0: Home, 1: 72h Bag, 2: 30d Shelter, 3: Board, 4: Settings)
final activeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Active Mode Toggle (`survivalBag` [72h] vs `shelterInPlace` [30d])
final activeModeProvider = StateProvider<SurvivalMode>((ref) {
  return SurvivalMode.survivalBag;
});

/// Ownership filter (`all`, `owned`, `missing`)
final ownershipFilterProvider = StateProvider<OwnershipFilter>((ref) {
  return OwnershipFilter.all;
});

/// Selected category filter (`null` means All Categories)
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Whether the user has explicitly confirmed/configured their household headcount
final householdConfiguredProvider = StateProvider<bool>((ref) {
  final repo = ref.watch(storageRepositoryProvider);
  return repo.isHouseholdConfigured();
});

/// Household / Evacuee Count Notifier (1 ~ 20 people)
class HouseholdCountNotifier extends StateNotifier<int> {
  final StorageRepository _repository;
  final Ref _ref;

  HouseholdCountNotifier(this._repository, this._ref)
      : super(_repository.getHouseholdCount());

  Future<void> setCount(int newCount) async {
    final clamped = newCount.clamp(1, 20);
    state = clamped;
    await _repository.saveHouseholdCount(clamped, markConfigured: true);
    _ref.read(householdConfiguredProvider.notifier).state = true;

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _ref.read(gurrenSurvivalServiceProvider).updateSettings(
        token: token,
        householdCount: clamped,
      ).catchError((e) {
        debugPrint('Failed to sync household count to server: $e');
        return <String, dynamic>{};
      });
    }
  }

  void updateFromRemote(int count) {
    final clamped = count.clamp(1, 20);
    state = clamped;
    _repository.saveHouseholdCount(clamped, markConfigured: true);
    _ref.read(householdConfiguredProvider.notifier).state = true;
  }

  Future<void> confirmCurrentCount() async {
    await _repository.saveHouseholdCount(state, markConfigured: true);
    _ref.read(householdConfiguredProvider.notifier).state = true;

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _ref.read(gurrenSurvivalServiceProvider).updateSettings(
        token: token,
        householdCount: state,
      ).catchError((e) {
        debugPrint('Failed to sync household count to server: $e');
        return <String, dynamic>{};
      });
    }
  }

  Future<void> increment() => setCount(state + 1);
  Future<void> decrement() => setCount(state - 1);
}

final householdCountProvider =
    StateNotifierProvider<HouseholdCountNotifier, int>((ref) {
  final repo = ref.watch(storageRepositoryProvider);
  return HouseholdCountNotifier(repo, ref);
});

/// App Locale Provider
class LocaleNotifier extends StateNotifier<Locale> {
  final StorageRepository _repository;

  LocaleNotifier(this._repository)
      : super(Locale(_repository.getSavedLocaleCode()));

  Future<void> toggleLocale() async {
    final nextCode = state.languageCode == 'en' ? 'ko' : 'en';
    state = Locale(nextCode);
    await _repository.saveLocaleCode(nextCode);
  }

  Future<void> setLocale(String code) async {
    state = Locale(code);
    await _repository.saveLocaleCode(code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final repo = ref.watch(storageRepositoryProvider);
  return LocaleNotifier(repo);
});

/// Inventory Items StateNotifier (Offline-first Hive + Auto Notification Sync)
class InventoryNotifier extends StateNotifier<List<Item>> {
  final StorageRepository _repository;
  final NotificationService _notifications;
  final GurrenSurvivalService _survivalService;
  final bool Function() _isKoreanGetter;
  final Ref _ref;

  InventoryNotifier(
    this._repository,
    this._notifications,
    this._survivalService,
    this._isKoreanGetter,
    this._ref,
  ) : super(_repository.getAllItems()) {
    _syncDigestNotifications();
    syncCatalogAffiliateLinks();
  }

  /// Fetches public catalog to immediately update Coupang / Amazon affiliate links from admin
  Future<void> syncCatalogAffiliateLinks() async {
    try {
      final catalog = await _survivalService.fetchCatalog();
      if (catalog.isEmpty) return;

      final officialCatalogIds = <String>{};
      bool changed = false;

      for (final raw in catalog) {
        final id = raw['id'] as String?;
        if (id == null || id.isEmpty) continue;
        officialCatalogIds.add(id);

        final krUrl = raw['affiliate_url_kr'] as String?;
        final enUrl = raw['affiliate_url_en'] as String?;
        final imgUrl = raw['affiliate_image_url'] as String?;
        final nameKo = raw['name_ko'] as String?;
        final nameEn = raw['name_en'] as String?;
        final category = raw['category'] as String?;

        final rawUnit = raw['unit'] as String?;
        final cleanUnit = (rawUnit != null && rawUnit != '?') ? rawUnit : null;
        final order = raw['display_order'] as int? ?? 999;

        final localIndex = state.indexWhere((e) => e.id == id || e.catalogItemId == id);
        if (localIndex != -1) {
          final local = state[localIndex];
          if (local.displayOrder != order ||
              local.affiliateUrlKr != krUrl ||
              local.affiliateUrlEn != enUrl ||
              local.affiliateImageUrl != imgUrl ||
              (nameKo != null && local.nameKo != nameKo) ||
              (category != null && local.category != category) ||
              (cleanUnit != null && local.unitKo != cleanUnit)) {
            final updated = local.copyWith(
              catalogItemId: id,
              affiliateUrlKr: krUrl,
              affiliateUrlEn: enUrl,
              affiliateImageUrl: imgUrl,
              nameKo: nameKo ?? local.nameKo,
              name: nameEn ?? local.name,
              category: category ?? local.category,
              unitKo: cleanUnit ?? local.unitKo,
              unitEn: cleanUnit ?? local.unitEn,
              displayOrder: order,
            );
            await _repository.saveItem(updated);
            changed = true;
          }
        } else {
          // If the official item is completely missing in local state, add it from catalog
          final modeStr = raw['mode'] as String? ?? 'bag';
          final mode = (modeStr == 'shelter')
              ? SurvivalMode.shelterInPlace
              : SurvivalMode.survivalBag;
          final unit = cleanUnit ?? '개';
          final importance = raw['importance'] as int? ?? 2;
          final qty = raw['default_quantity'] as int? ?? 1;
          final hasExp = raw['has_expiry'] as bool? ?? false;
          final expMonths = raw['default_expiry_months'] as int? ?? 12;

          final newItem = Item(
            id: id,
            catalogItemId: id,
            mode: mode,
            category: category ?? 'General',
            name: nameEn ?? 'Item',
            nameKo: nameKo ?? '품목',
            expiryMonth: DateTime.now().add(Duration(days: expMonths > 0 ? expMonths * 30 : 365)),
            defaultShelfLifeMonths: expMonths,
            isOwned: false,
            hasExpiry: hasExp,
            qtyPerPerson: qty,
            isSharedEquipment: {
              'chk-bag-firstaid',
              'chk-bag-light',
              'chk-bag-multitool',
              'chk-bag-radio',
              'chk-shl-burner',
              'chk-shl-toilet',
              'chk-shl-homemedkit',
              'chk-shl-extinguisher',
              'chk-shl-ducttape',
            }.contains(id),
            unitEn: unit,
            unitKo: unit,
            importance: importance,
            affiliateUrlKr: krUrl,
            affiliateUrlEn: enUrl,
            affiliateImageUrl: imgUrl,
            displayOrder: order,
          );
          await _repository.saveItem(newItem);
          changed = true;
        }
      }

      // Clean up legacy preset items (chk-*) that are no longer part of the 25 official items
      for (final item in List<Item>.from(state)) {
        if (item.id.startsWith('chk-') && !officialCatalogIds.contains(item.id)) {
          await _repository.deleteItem(item.id);
          changed = true;
        }
      }

      if (changed) {
        state = _repository.getAllItems();
      }
    } catch (e) {
      debugPrint('Sync catalog affiliate links skipped (offline/error): $e');
    }
  }

  /// Synchronizes local items and settings with Gurren API server
  Future<void> syncWithServer(String token) async {
    try {
      var serverItems = await _survivalService.fetchUserItems(token: token);

      if (serverItems.isEmpty) {
        // 1. 서버에 아직 유저 아이템이 없는 경우: 공식 카탈로그 기반으로 서버 초기화
        serverItems = await _survivalService.initUserItems(token: token);

        // 2. [핵심] 로그인 전 로컬에서 이미 체크/수정한 내용 및 커스텀 아이템을 서버로 일괄 Push
        final localItems = _repository.getAllItems();
        for (final local in localItems) {
          if (local.id.startsWith('chk-')) {
            // 카탈로그 기본 물품: 체크했거나 수량/유통기한/위치/메모를 바꿨으면 서버로 업데이트
            if (local.isOwned || local.qtyPerPerson != 1 || local.memo != null || local.storageLocation != null) {
              await _survivalService.updateUserItem(
                token: token,
                itemId: local.id,
                isOwned: local.isOwned,
                quantity: local.qtyPerPerson,
                expiryDate: local.hasExpiry ? local.expiryMonth : null,
                storageLocation: local.storageLocation,
                memo: local.memo,
              ).catchError((e) {
                debugPrint('Background push local item error: $e');
                return local;
              });
            }
          } else {
            // 사용자가 직접 추가한 커스텀 품목: 서버에 새로 등록
            await _survivalService.createCustomItem(
              token: token,
              mode: local.mode == SurvivalMode.shelterInPlace ? 'shelter' : 'bag',
              category: local.category,
              name: local.name,
              quantity: local.qtyPerPerson,
              unit: local.unitKo,
              importance: local.importance,
              hasExpiry: local.hasExpiry,
              expiryDate: local.hasExpiry ? local.expiryMonth : null,
              storageLocation: local.storageLocation,
              memo: local.memo,
            ).catchError((e) {
              debugPrint('Background push custom item error: $e');
              return local;
            });
          }
        }

        // 3. 로컬의 가족 인원수 및 점검일 설정도 서버로 Push
        final localHousehold = _repository.getHouseholdCount();
        final localInspection = _repository.getInspectionCheck();
        await _survivalService.updateSettings(
          token: token,
          householdCount: localHousehold,
          lastInspectedAt: localInspection.lastInspectionDate,
          inspectionCycleMonths: localInspection.cycleMonths,
        ).catchError((e) {
          debugPrint('Background push settings error: $e');
          return <String, dynamic>{};
        });

        // Push 완료 후 최신 서버 상태 다시 로드
        serverItems = await _survivalService.fetchUserItems(token: token);
      } else {
        // 4. 서버에 이미 데이터가 있는 경우 (다른 브라우저 등에서 로그인한 경우):
        // 서버의 설정(인원수, 점검일)을 로컬에 다운로드하여 적용
        try {
          final settings = await _survivalService.fetchSettings(token: token);
          if (settings['household_count'] is int) {
            _ref.read(householdCountProvider.notifier).updateFromRemote(settings['household_count'] as int);
          }
          if (settings['last_inspected_at'] is String && (settings['last_inspected_at'] as String).isNotEmpty) {
            final parsedDate = DateTime.tryParse(settings['last_inspected_at'] as String);
            final cycle = settings['inspection_cycle_months'] as int? ?? 6;
            if (parsedDate != null) {
              _ref.read(inspectionProvider.notifier).updateFromRemote(parsedDate, cycle);
            }
          }
        } catch (e) {
          debugPrint('Failed to fetch settings from server: $e');
        }
      }

      // 5. 서버에 없는 로컬 품목 삭제 (삭제 동기화)
      final serverCatalogIds = serverItems.map((e) => e.catalogItemId ?? e.id).toSet();
      for (final item in List<Item>.from(state)) {
        if (!serverCatalogIds.contains(item.catalogItemId ?? item.id)) {
          await _repository.deleteItem(item.id);
        }
      }

      // 6. 서버의 최신 물품 상태(체크 여부, 수량, 유통기한, 보관장소, 메모 등)를 로컬에 완전 반영
      for (final sItem in serverItems) {
        final localIndex = state.indexWhere((e) => e.id == sItem.id || e.catalogItemId == sItem.id);
        Item toSave = sItem;
        if (localIndex != -1) {
          final local = state[localIndex];
          toSave = local.copyWith(
            catalogItemId: sItem.catalogItemId ?? local.catalogItemId,
            affiliateUrlKr: sItem.affiliateUrlKr ?? local.affiliateUrlKr,
            affiliateUrlEn: sItem.affiliateUrlEn ?? local.affiliateUrlEn,
            affiliateImageUrl: sItem.affiliateImageUrl ?? local.affiliateImageUrl,
            nameKo: sItem.nameKo,
            name: sItem.name,
            category: sItem.category,
            isOwned: sItem.isOwned,
            qtyPerPerson: sItem.qtyPerPerson,
            expiryMonth: sItem.hasExpiry ? sItem.expiryMonth : local.expiryMonth,
            hasExpiry: sItem.hasExpiry,
            storageLocation: sItem.storageLocation,
            memo: sItem.memo,
            importance: sItem.importance,
            displayOrder: sItem.displayOrder,
            unitKo: sItem.unitKo != '?' ? sItem.unitKo : local.unitKo,
            unitEn: sItem.unitEn != '?' ? sItem.unitEn : local.unitEn,
          );
        } else {
          if (toSave.unitKo == '?') {
            toSave = toSave.copyWith(unitKo: '병', unitEn: 'bottles');
          }
        }
        await _repository.saveItem(toSave);
      }
      state = _repository.getAllItems();
      await _syncDigestNotifications();
    } catch (e) {
      debugPrint('Sync with server skipped (offline/error): $e');
      if (e.toString().contains('401')) {
        Future.microtask(() async {
          final ok = await _ref.read(accountProvider.notifier).loginAsGuest(force: true);
          if (ok) {
            final freshToken = _ref.read(accountProvider).authToken;
            if (freshToken != null && freshToken.isNotEmpty) {
              await syncWithServer(freshToken);
            }
          }
        });
      }
    }
  }

  Future<void> addItem(Item item) async {
    await _repository.saveItem(item);
    state = _repository.getAllItems();
    await _syncDigestNotifications();

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _survivalService
          .createCustomItem(
            token: token,
            mode: item.mode == SurvivalMode.shelterInPlace ? 'shelter' : 'bag',
            category: item.category,
            name: item.name,
            quantity: item.qtyPerPerson,
            unit: item.unitKo,
            importance: item.importance,
            hasExpiry: item.hasExpiry,
            expiryDate: item.hasExpiry ? item.expiryMonth : null,
            storageLocation: item.storageLocation,
            memo: item.memo,
          )
          .then((createdServerItem) async {
            if (createdServerItem.id != item.id) {
              await _repository.deleteItem(item.id);
              await _repository.saveItem(createdServerItem);
              state = _repository.getAllItems();
            }
          })
          .catchError((e) {
            debugPrint('Background create item error: $e');
            return item;
          });
    }
  }

  Future<void> updateItem(Item updated) async {
    await _repository.saveItem(updated);
    state = _repository.getAllItems();
    await _syncDigestNotifications();

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _survivalService
          .updateUserItem(
            token: token,
            itemId: updated.id,
            isOwned: updated.isOwned,
            quantity: updated.qtyPerPerson,
            expiryDate: updated.hasExpiry ? updated.expiryMonth : null,
            storageLocation: updated.storageLocation,
            memo: updated.memo,
            customName: updated.id.startsWith('chk-') ? null : updated.name,
          )
          .catchError((e) {
            debugPrint('Background update item error: $e');
            return updated;
          });
    }
  }

  /// Toggles whether the user owns/packed this checklist item ("있다 / 없다")
  Future<void> toggleItemOwned(String itemId) async {
    final index = state.indexWhere((e) => e.id == itemId);
    if (index == -1) return;

    final current = state[index];
    final now = DateTime.now();
    final updatedExpiry = (!current.isOwned &&
            current.hasExpiry &&
            current.daysUntilExpiry(now) <= 0)
        ? DateTime(now.year, now.month + current.defaultShelfLifeMonths, 1)
        : current.expiryMonth;

    final updated = current.copyWith(
      isOwned: !current.isOwned,
      expiryMonth: updatedExpiry,
    );
    await _repository.saveItem(updated);
    state = _repository.getAllItems();
    await _syncDigestNotifications();

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _survivalService
          .updateUserItem(
            token: token,
            itemId: itemId,
            isOwned: updated.isOwned,
            quantity: updated.qtyPerPerson,
            storageLocation: updated.storageLocation,
            memo: updated.memo,
            expiryDate: updated.hasExpiry ? updated.expiryMonth : null,
          )
          .catchError((e) {
            debugPrint('Background toggle item error: $e');
            return updated;
          });
    }
  }

  /// Updates the expiry Year-Month of a checklist item directly from the card
  Future<void> updateItemExpiry(String itemId, DateTime newExpiryMonth) async {
    final index = state.indexWhere((e) => e.id == itemId);
    if (index == -1) return;

    final updated = state[index].copyWith(
      expiryMonth: DateTime(newExpiryMonth.year, newExpiryMonth.month, 1),
      isOwned: true,
    );
    await _repository.saveItem(updated);
    state = _repository.getAllItems();
    await _syncDigestNotifications();

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _survivalService
          .updateUserItem(
            token: token,
            itemId: itemId,
            isOwned: true,
            quantity: updated.qtyPerPerson,
            storageLocation: updated.storageLocation,
            memo: updated.memo,
            expiryDate: updated.expiryMonth,
          )
          .catchError((e) {
            debugPrint('Background update expiry error: $e');
            return updated;
          });
    }
  }

  /// 1-Tap Rolling Stock Reset ("Consume & Replace"):
  /// Automatically extends the item's expiryMonth by `defaultShelfLifeMonths` from now.
  Future<Item> consumeAndRestock(String itemId) async {
    final index = state.indexWhere((e) => e.id == itemId);
    if (index == -1) throw StateError('Item not found');

    final updated = state[index].consumeAndRestock(DateTime.now());
    await _repository.saveItem(updated);
    state = _repository.getAllItems();
    await _syncDigestNotifications();

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _survivalService
          .updateUserItem(
            token: token,
            itemId: itemId,
            isOwned: true,
            quantity: updated.qtyPerPerson,
            storageLocation: updated.storageLocation,
            memo: updated.memo,
            expiryDate: updated.expiryMonth,
          )
          .catchError((e) {
            debugPrint('Background consumeAndRestock error: $e');
            return updated;
          });
    }
    return updated;
  }

  Future<void> deleteItem(String itemId) async {
    await _repository.deleteItem(itemId);
    state = _repository.getAllItems();
    await _syncDigestNotifications();

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _survivalService
          .deleteUserItem(
            token: token,
            itemId: itemId,
          )
          .catchError((e) {
            debugPrint('Background delete item error: $e');
          });
    }
  }

  Future<void> _syncDigestNotifications() async {
    await _notifications.syncMonthlyRollingStockDigest(
      allItems: state,
      isKorean: _isKoreanGetter(),
    );
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<Item>>((ref) {
  final repo = ref.watch(storageRepositoryProvider);
  final notifications = ref.watch(notificationServiceProvider);
  final survivalService = ref.watch(gurrenSurvivalServiceProvider);
  return InventoryNotifier(
    repo,
    notifications,
    survivalService,
    () => ref.read(localeProvider).languageCode == 'ko',
    ref,
  );
});

/// All items for the currently selected mode (before category/ownership filters)
final modeItemsProvider = Provider<List<Item>>((ref) {
  final mode = ref.watch(activeModeProvider);
  final allItems = ref.watch(inventoryProvider);
  return allItems.where((item) => item.mode == mode && !item.isConsumed).toList();
});

/// Filtered items for the current mode, ownership status, and category filter
final filteredItemsProvider = Provider<List<Item>>((ref) {
  final modeItems = ref.watch(modeItemsProvider);
  final ownershipFilter = ref.watch(ownershipFilterProvider);
  final category = ref.watch(selectedCategoryProvider);

  return modeItems.where((item) {
    if (ownershipFilter == OwnershipFilter.owned && !item.isOwned) {
      return false;
    }
    if (ownershipFilter == OwnershipFilter.missing && item.isOwned) {
      return false;
    }
    if (category != null && item.category != category) return false;
    return true;
  }).toList();
});

/// Owned items expiring within 60 days for the Monthly Rolling Stock Digest modal & banner
final expiringDigestItemsProvider = Provider<List<Item>>((ref) {
  final allItems = ref.watch(inventoryProvider);
  final now = DateTime.now();
  return allItems
      .where((item) => item.isExpiringWithinDays(now, 60))
      .toList();
});

/// 6-Month Periodic Inspection StateNotifier
class InspectionNotifier extends StateNotifier<InspectionCheck> {
  final StorageRepository _repository;
  final NotificationService _notifications;
  final bool Function() _isKoreanGetter;
  final Ref _ref;

  InspectionNotifier(
    this._repository,
    this._notifications,
    this._isKoreanGetter,
    this._ref,
  ) : super(_repository.getInspectionCheck()) {
    _syncNotification();
  }

  Future<void> completeInspection() async {
    final now = DateTime.now();
    final updated = state.completeInspection(now);
    await _repository.saveInspectionCheck(updated);
    state = updated;
    await _syncNotification();

    final token = _repository.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _ref.read(gurrenSurvivalServiceProvider).updateSettings(
        token: token,
        lastInspectedAt: now,
      ).catchError((e) {
        debugPrint('Failed to sync inspection date to server: $e');
        return <String, dynamic>{};
      });
    }
  }

  void updateFromRemote(DateTime lastInspectedAt, int cycleMonths) {
    final nextDate = DateTime(
      lastInspectedAt.year,
      lastInspectedAt.month + cycleMonths,
      lastInspectedAt.day,
    );
    final updated = InspectionCheck(
      lastInspectionDate: lastInspectedAt,
      nextInspectionDate: nextDate,
      cycleMonths: cycleMonths,
    );
    _repository.saveInspectionCheck(updated);
    state = updated;
    _syncNotification();
  }

  Future<void> _syncNotification() async {
    await _notifications.syncPeriodicInspectionNotification(
      check: state,
      isKorean: _isKoreanGetter(),
    );
  }
}

final inspectionProvider =
    StateNotifierProvider<InspectionNotifier, InspectionCheck>((ref) {
  final repo = ref.watch(storageRepositoryProvider);
  final notifications = ref.watch(notificationServiceProvider);
  return InspectionNotifier(
    repo,
    notifications,
    () => ref.read(localeProvider).languageCode == 'ko',
    ref,
  );
});
