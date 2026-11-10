import 'dart:math';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inspection_check.dart';
import '../models/item.dart';
import '../models/preset_item.dart';
import '../models/survival_mode.dart';

class StorageRepository {
  static const String itemsBoxName = 'survival_items_v6_box';
  static const String inspectionBoxName = 'inspection_check_v2_box';
  static const String settingsBoxName = 'app_settings_v2_box';
  static const String inspectionKey = 'current_inspection';
  static const String localeKey = 'preferred_locale';
  static const String householdCountKey = 'household_count';
  static const String householdConfiguredKey = 'household_configured';
  static const String guestIdKey = 'guest_user_id';
  static const String googleLinkedKey = 'is_google_linked';
  static const String linkedEmailKey = 'linked_google_email';
  static const String authTokenKey = 'gurren_auth_token';
  static const String refreshTokenKey = 'gurren_refresh_token';
  static const String serverDisplayIdKey = 'gurren_server_display_id';
  static const String serverDisplayNameKey = 'gurren_server_display_name';

  final Map<String, Item> _memoryItems = {};
  InspectionCheck _memoryInspection = InspectionCheck(
    lastInspectedAt: DateTime.now().subtract(const Duration(days: 150)),
    cycleMonths: 6,
  );
  String _memoryLocale = _detectDefaultLocaleCode();
  int _memoryHouseholdCount = 1;
  bool _memoryHouseholdConfigured = false;
  late String _memoryGuestId;
  bool _memoryGoogleLinked = false;
  String? _memoryLinkedEmail;
  String? _memoryAuthToken;
  String? _memoryRefreshToken;
  String? _memoryServerDisplayId;
  String? _memoryServerDisplayName;
  bool _hiveReady = false;
  SharedPreferences? _prefs;

  /// If system/browser language is Korean ('ko'), default to 'ko'; otherwise always default to 'en'.
  static String _detectDefaultLocaleCode() {
    try {
      final sysLang =
          PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      return sysLang == 'ko' ? 'ko' : 'en';
    } catch (_) {
      return 'en';
    }
  }

  StorageRepository() {
    final randomNum = 1000 + Random().nextInt(9000);
    _memoryGuestId = 'Guest-#$randomNum';
    for (final item in SurvivalCatalog.buildMasterChecklist(DateTime.now())) {
      _memoryItems[item.id] = item;
    }
  }

  Future<void> init() async {
    // 1. SharedPreferences (웹/앱 모두에서 가장 안정적인 영구 키-값 저장소) 우선 로드
    try {
      _prefs = await SharedPreferences.getInstance();
      final pGuestId = _prefs?.getString(guestIdKey);
      if (pGuestId != null && pGuestId.isNotEmpty) {
        _memoryGuestId = pGuestId;
      }
      _memoryAuthToken = _prefs?.getString(authTokenKey);
      _memoryRefreshToken = _prefs?.getString(refreshTokenKey);
      _memoryServerDisplayId = _prefs?.getString(serverDisplayIdKey);
      _memoryServerDisplayName = _prefs?.getString(serverDisplayNameKey);
    } catch (e) {
      debugPrint('SharedPreferences init fallback: $e');
    }

    // 2. Hive 데이터베이스 로드 (타임아웃 10초로 안정성 확보)
    try {
      await Hive.initFlutter().timeout(const Duration(seconds: 10));

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SurvivalModeAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ItemAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(InspectionCheckAdapter());
      }

      final itemsBox = await Hive.openBox<Item>(itemsBoxName)
          .timeout(const Duration(seconds: 10));
      final inspectionBox = await Hive.openBox<InspectionCheck>(
        inspectionBoxName,
      ).timeout(const Duration(seconds: 10));
      final settingsBox = await Hive.openBox<String>(settingsBoxName)
          .timeout(const Duration(seconds: 10));

      _hiveReady = true;

      for (final entry in _memoryItems.entries) {
        if (!itemsBox.containsKey(entry.key)) {
          await itemsBox.put(entry.key, entry.value);
        }
      }
      for (final item in itemsBox.values) {
        _memoryItems[item.id] = item;
      }

      final savedInspection = inspectionBox.get(inspectionKey);
      if (savedInspection != null) {
        _memoryInspection = savedInspection;
      } else {
        await inspectionBox.put(inspectionKey, _memoryInspection);
      }

      final defaultLocale = _detectDefaultLocaleCode();
      _memoryLocale =
          settingsBox.get(localeKey, defaultValue: defaultLocale) ??
              defaultLocale;
      final rawCount =
          settingsBox.get(householdCountKey, defaultValue: '1') ?? '1';
      _memoryHouseholdCount = int.tryParse(rawCount) ?? 1;
      _memoryHouseholdConfigured =
          (settingsBox.get(householdConfiguredKey, defaultValue: 'false') ??
                  'false') ==
              'true';

      final existingGuestId = settingsBox.get(guestIdKey);
      if (existingGuestId != null && existingGuestId.isNotEmpty) {
        _memoryGuestId = existingGuestId;
      } else {
        await settingsBox.put(guestIdKey, _memoryGuestId);
        await _prefs?.setString(guestIdKey, _memoryGuestId);
      }

      _memoryGoogleLinked =
          (settingsBox.get(googleLinkedKey, defaultValue: 'false') ??
                  'false') ==
              'true';
      _memoryLinkedEmail = settingsBox.get(linkedEmailKey);

      _memoryAuthToken ??= settingsBox.get(authTokenKey);
      _memoryRefreshToken ??= settingsBox.get(refreshTokenKey);
      _memoryServerDisplayId ??= settingsBox.get(serverDisplayIdKey);
      _memoryServerDisplayName ??= settingsBox.get(serverDisplayNameKey);
    } catch (e) {
      debugPrint('Hive init fallback to in-memory/prefs storage: $e');
      _hiveReady = false;
    }
  }

  List<Item> getAllItems() {
    final items = _memoryItems.values.toList();
    items.sort((a, b) {
      // 1순위: 서버 카탈로그 displayOrder (10, 20, 30...)
      if (a.displayOrder != b.displayOrder) {
        return a.displayOrder.compareTo(b.displayOrder);
      }
      // 2순위: 유통기한 관리 품목 우선
      if (a.hasExpiry != b.hasExpiry) {
        return a.hasExpiry ? -1 : 1;
      }
      // 3순위: 유통기한이 있는 품목끼리는 만료일 임박 순
      if (a.hasExpiry && b.hasExpiry) {
        final expiryCmp = a.expiryMonth.compareTo(b.expiryMonth);
        if (expiryCmp != 0) return expiryCmp;
      }
      // 4순위: 고유 ID 순 (체크박스 토글 시 위치가 튀지 않도록 고정)
      return a.id.compareTo(b.id);
    });
    return items;
  }

  Future<void> saveItem(Item item) async {
    _memoryItems[item.id] = item;
    if (_hiveReady) {
      try {
        await Hive.box<Item>(itemsBoxName).put(item.id, item);
      } catch (_) {}
    }
  }

  Future<void> deleteItem(String id) async {
    _memoryItems.remove(id);
    if (_hiveReady) {
      try {
        await Hive.box<Item>(itemsBoxName).delete(id);
      } catch (_) {}
    }
  }

  InspectionCheck getInspectionCheck() => _memoryInspection;

  Future<void> saveInspectionCheck(InspectionCheck check) async {
    _memoryInspection = check;
    if (_hiveReady) {
      try {
        await Hive.box<InspectionCheck>(inspectionBoxName)
            .put(inspectionKey, check);
      } catch (_) {}
    }
  }

  String getSavedLocaleCode() => _memoryLocale;

  Future<void> saveLocaleCode(String languageCode) async {
    _memoryLocale = languageCode;
    if (_hiveReady) {
      try {
        await Hive.box<String>(settingsBoxName).put(localeKey, languageCode);
      } catch (_) {}
    }
  }

  int getHouseholdCount() => _memoryHouseholdCount;
  bool isHouseholdConfigured() => _memoryHouseholdConfigured;

  Future<void> saveHouseholdCount(int count, {bool markConfigured = true}) async {
    final clamped = count.clamp(1, 20);
    _memoryHouseholdCount = clamped;
    if (markConfigured) {
      _memoryHouseholdConfigured = true;
    }
    if (_hiveReady) {
      try {
        final box = Hive.box<String>(settingsBoxName);
        await box.put(householdCountKey, clamped.toString());
        if (markConfigured) {
          await box.put(householdConfiguredKey, 'true');
        }
      } catch (_) {}
    }
  }

  String getGuestId() => _memoryGuestId;
  bool isGoogleLinked() => _memoryGoogleLinked;
  String? getLinkedEmail() => _memoryLinkedEmail;

  Future<void> setGoogleLinked({
    required bool isLinked,
    String? email,
  }) async {
    _memoryGoogleLinked = isLinked;
    _memoryLinkedEmail = email;
    if (_hiveReady) {
      try {
        final box = Hive.box<String>(settingsBoxName);
        await box.put(googleLinkedKey, isLinked ? 'true' : 'false');
        if (email != null) {
          await box.put(linkedEmailKey, email);
        } else {
          await box.delete(linkedEmailKey);
        }
      } catch (_) {}
    }
  }

  // --- Gurren API Auth Session Methods ---

  String? getAuthToken() => _memoryAuthToken;
  String? getRefreshToken() => _memoryRefreshToken;
  String? getServerDisplayId() => _memoryServerDisplayId;
  String? getServerDisplayName() => _memoryServerDisplayName;

  Future<void> saveAuthSession({
    required String token,
    required String refreshToken,
    required String displayId,
    required String displayName,
  }) async {
    _memoryAuthToken = token;
    _memoryRefreshToken = refreshToken;
    _memoryServerDisplayId = displayId;
    _memoryServerDisplayName = displayName;

    // SharedPreferences 영구 저장
    try {
      await _prefs?.setString(authTokenKey, token);
      await _prefs?.setString(refreshTokenKey, refreshToken);
      await _prefs?.setString(serverDisplayIdKey, displayId);
      await _prefs?.setString(serverDisplayNameKey, displayName);
    } catch (_) {}

    // Hive 영구 저장
    if (_hiveReady) {
      try {
        final box = Hive.box<String>(settingsBoxName);
        await box.put(authTokenKey, token);
        await box.put(refreshTokenKey, refreshToken);
        await box.put(serverDisplayIdKey, displayId);
        await box.put(serverDisplayNameKey, displayName);
      } catch (_) {}
    }
  }

  Future<void> clearAuthSession() async {
    _memoryAuthToken = null;
    _memoryRefreshToken = null;
    _memoryServerDisplayId = null;
    _memoryServerDisplayName = null;

    try {
      await _prefs?.remove(authTokenKey);
      await _prefs?.remove(refreshTokenKey);
      await _prefs?.remove(serverDisplayIdKey);
      await _prefs?.remove(serverDisplayNameKey);
    } catch (_) {}

    if (_hiveReady) {
      try {
        final box = Hive.box<String>(settingsBoxName);
        await box.delete(authTokenKey);
        await box.delete(refreshTokenKey);
        await box.delete(serverDisplayIdKey);
        await box.delete(serverDisplayNameKey);
      } catch (_) {}
    }
  }
}
