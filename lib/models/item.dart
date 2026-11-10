import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'survival_mode.dart';

part 'item.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class Item {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final SurvivalMode mode;

  @HiveField(2)
  final String category;

  /// Default / English name (or custom user-entered name)
  @HiveField(3)
  final String name;

  @HiveField(4)
  final String? storageLocation;

  /// Stores rough expiration Year-Month (normalized to YYYY-MM-01)
  @HiveField(5)
  final DateTime expiryMonth;

  /// Used for 1-Tap Rolling Stock Reset ("Consume & Restock")
  @HiveField(6)
  final int defaultShelfLifeMonths;

  @HiveField(7)
  final bool isConsumed;

  /// Whether the user currently has/packed this checklist item ("있다 / 없다")
  @HiveField(8)
  final bool isOwned;

  /// Whether this item tracks expiration dates (true for food/water/meds/batteries, false for permanent tools)
  @HiveField(9)
  final bool hasExpiry;

  /// Optional localized Korean name for built-in checklist items
  @HiveField(10)
  final String? nameKo;

  /// Base recommended quantity per 1 person (or per household if `isSharedEquipment` is true)
  @HiveField(11)
  final int qtyPerPerson;

  /// If true, this item is shared across the family/group (e.g., 1 radio, 1 stove) rather than multiplied by headcount
  @HiveField(12)
  final bool isSharedEquipment;

  /// Unit label in English (e.g., "bottles", "meals", "pcs")
  @HiveField(13)
  final String unitEn;

  /// Unit label in Korean (e.g., "병", "끼", "개", "매")
  @HiveField(14)
  final String unitKo;

  /// Optional user memo / note (e.g. brand, detailed count, family member allergies)
  @HiveField(15)
  final String? memo;

  /// Importance / Priority Level: 3 = Essential (필수), 2 = Recommended (권장), 1 = Optional (선택)
  @HiveField(16)
  final int importance;

  /// Optional official catalog item ID (null for user-created custom items)
  @HiveField(17)
  final String? catalogItemId;

  /// Affiliate product link for Korean users (Coupang Partners)
  @HiveField(18)
  final String? affiliateUrlKr;

  /// Affiliate product link for Global users (Amazon Associates)
  @HiveField(19)
  final String? affiliateUrlEn;

  /// Affiliate thumbnail image URL
  @HiveField(20)
  final String? affiliateImageUrl;

  /// Display order / priority from server catalog (10, 20, 30...; default 999 for custom)
  @HiveField(21)
  final int displayOrder;

  Item({
    required this.id,
    required this.mode,
    required this.category,
    required this.name,
    this.nameKo,
    this.storageLocation,
    required DateTime expiryMonth,
    required this.defaultShelfLifeMonths,
    this.isConsumed = false,
    this.isOwned = false,
    this.hasExpiry = true,
    this.qtyPerPerson = 1,
    this.isSharedEquipment = false,
    this.unitEn = 'pcs',
    this.unitKo = '개',
    this.memo,
    this.importance = 2,
    this.catalogItemId,
    this.affiliateUrlKr,
    this.affiliateUrlEn,
    this.affiliateImageUrl,
    this.displayOrder = 999,
  }) : expiryMonth = DateTime(expiryMonth.year, expiryMonth.month, 1);

  String displayName(bool isKo) {
    if (isKo && nameKo != null && nameKo!.isNotEmpty) {
      return nameKo!;
    }
    return name;
  }

  /// Returns the appropriate affiliate URL based on the user's active locale
  String? getAffiliateUrl(bool isKo) {
    if (isKo) {
      if (affiliateUrlKr != null && affiliateUrlKr!.isNotEmpty) {
        return affiliateUrlKr;
      }
      return affiliateUrlEn;
    }
    if (affiliateUrlEn != null && affiliateUrlEn!.isNotEmpty) {
      return affiliateUrlEn;
    }
    return affiliateUrlKr;
  }

  /// Calculates recommended quantity based on the household / evacuee count
  int recommendedQuantity(int householdCount) {
    final count = householdCount <= 0 ? 1 : householdCount;
    if (isSharedEquipment) return qtyPerPerson;
    return qtyPerPerson * count;
  }

  String formattedRecommendedQuantity(int householdCount, bool isKo) {
    final qty = recommendedQuantity(householdCount);
    final unit = isKo ? unitKo : unitEn;
    return isKo ? '권장: $qty$unit' : 'Rec: $qty $unit';
  }

  /// Formatted Year-Month string (`YYYY-MM`)
  String get formattedExpiryMonth =>
      '${expiryMonth.year}-${expiryMonth.month.toString().padLeft(2, '0')}';

  /// Approximate days until the end of the expiry month
  int daysUntilExpiry(DateTime now) {
    final endOfExpiryMonth =
        DateTime(expiryMonth.year, expiryMonth.month + 1, 0);
    return endOfExpiryMonth
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Only owned items with expiry dates count toward the Monthly Rolling Stock Digest
  bool isExpiringWithinDays(DateTime now, int maxDays) {
    if (!isOwned || !hasExpiry || isConsumed) return false;
    return daysUntilExpiry(now) <= maxDays;
  }

  /// Whether this item is an official preset item from the server/catalog
  bool get isPreset => catalogItemId != null || id.startsWith('chk-');

  /// 1-Tap Rolling Stock Reset: extends expiry from current date by `defaultShelfLifeMonths`
  Item consumeAndRestock(DateTime now) {
    final nextExpiry = DateTime(
      now.year,
      now.month + defaultShelfLifeMonths,
      1,
    );
    return copyWith(
      expiryMonth: nextExpiry,
      isConsumed: false,
      isOwned: true,
    );
  }

  Item copyWith({
    String? id,
    SurvivalMode? mode,
    String? category,
    String? name,
    String? nameKo,
    String? storageLocation,
    DateTime? expiryMonth,
    int? defaultShelfLifeMonths,
    bool? isConsumed,
    bool? isOwned,
    bool? hasExpiry,
    int? qtyPerPerson,
    bool? isSharedEquipment,
    String? unitEn,
    String? unitKo,
    String? memo,
    int? importance,
    String? catalogItemId,
    String? affiliateUrlKr,
    String? affiliateUrlEn,
    String? affiliateImageUrl,
    int? displayOrder,
    bool clearStorageLocation = false,
    bool clearMemo = false,
  }) {
    return Item(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      category: category ?? this.category,
      name: name ?? this.name,
      nameKo: nameKo ?? this.nameKo,
      storageLocation: clearStorageLocation
          ? null
          : (storageLocation ?? this.storageLocation),
      expiryMonth: expiryMonth ?? this.expiryMonth,
      defaultShelfLifeMonths:
          defaultShelfLifeMonths ?? this.defaultShelfLifeMonths,
      isConsumed: isConsumed ?? this.isConsumed,
      isOwned: isOwned ?? this.isOwned,
      hasExpiry: hasExpiry ?? this.hasExpiry,
      qtyPerPerson: qtyPerPerson ?? this.qtyPerPerson,
      isSharedEquipment: isSharedEquipment ?? this.isSharedEquipment,
      unitEn: unitEn ?? this.unitEn,
      unitKo: unitKo ?? this.unitKo,
      memo: clearMemo ? null : (memo ?? this.memo),
      importance: importance ?? this.importance,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      affiliateUrlKr: affiliateUrlKr ?? this.affiliateUrlKr,
      affiliateUrlEn: affiliateUrlEn ?? this.affiliateUrlEn,
      affiliateImageUrl: affiliateImageUrl ?? this.affiliateImageUrl,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  factory Item.fromServer(Map<String, dynamic> json) {
    final modeStr = json['mode'] as String? ?? 'bag';
    final mode = (modeStr == 'shelter')
        ? SurvivalMode.shelterInPlace
        : SurvivalMode.survivalBag;

    DateTime expiry = DateTime.now().add(const Duration(days: 365));
    final rawExpiry = json['expiry_date'];
    if (rawExpiry is String && rawExpiry.isNotEmpty) {
      final parsed = DateTime.tryParse(rawExpiry);
      if (parsed != null) expiry = parsed;
    }

    final unit = json['unit'] as String? ?? '개';
    final catalogId = json['catalog_item_id'] as String?;
    final serverId = json['id'] as String? ?? '';
    final id = (catalogId != null && catalogId.isNotEmpty) ? catalogId : serverId;

    final isShared = {
      'chk-bag-firstaid',
      'chk-bag-light',
      'chk-bag-multitool',
      'chk-bag-radio',
      'chk-shl-burner',
      'chk-shl-toilet',
      'chk-shl-homemedkit',
      'chk-shl-extinguisher',
      'chk-shl-ducttape',
    }.contains(id);

    return Item(
      id: id,
      mode: mode,
      category: json['category'] as String? ?? 'General',
      name: json['display_name_en'] as String? ??
          json['custom_name'] as String? ??
          'Item',
      nameKo: json['display_name_ko'] as String? ??
          json['custom_name'] as String? ??
          '품목',
      storageLocation: json['storage_location'] as String?,
      expiryMonth: expiry,
      defaultShelfLifeMonths: json['default_expiry_months'] as int? ?? 12,
      isConsumed: false,
      isOwned: json['is_owned'] as bool? ?? false,
      hasExpiry: json['has_expiry'] as bool? ?? false,
      qtyPerPerson: json['quantity'] as int? ?? 1,
      isSharedEquipment: json['is_shared_equipment'] as bool? ?? isShared,
      unitEn: unit,
      unitKo: unit,
      memo: json['memo'] as String?,
      importance: json['importance'] as int? ?? 2,
      catalogItemId: json['catalog_item_id'] as String?,
      affiliateUrlKr: json['affiliate_url_kr'] as String?,
      affiliateUrlEn: json['affiliate_url_en'] as String?,
      affiliateImageUrl: json['affiliate_image_url'] as String?,
      displayOrder: json['display_order'] as int? ?? 999,
    );
  }

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}
