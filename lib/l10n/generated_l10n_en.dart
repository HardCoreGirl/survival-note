// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'generated_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GeneratedAppLocalizationsEn extends GeneratedAppLocalizations {
  GeneratedAppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Survival & Shelter Manager';

  @override
  String get modeSurvivalBag => '72h Survival Bag';

  @override
  String get modeShelterInPlace => '30d Shelter-in-Place';

  @override
  String get inspectionTitle => '6-Month Periodic Inspection';

  @override
  String get inspectionSubtitle =>
      'Check battery leakage, power bank charge & seasonal gear';

  @override
  String inspectionDueInDays(int days) {
    return 'Next check in $days days';
  }

  @override
  String get inspectionOverdue => 'Inspection Overdue!';

  @override
  String get completeInspection => 'Complete Inspection';

  @override
  String get inspectionResetToast =>
      'Inspection completed! Next check scheduled in 6 months.';

  @override
  String monthlyDigestBanner(int count) {
    return '$count items expiring within 60 days. Tap to review.';
  }

  @override
  String get monthlyDigestTitle => 'Monthly Rolling Stock Digest';

  @override
  String get monthlyDigestSubtitle =>
      'Consume and replace these items before expiration to maintain readiness.';

  @override
  String get notificationMonthlyTitle =>
      '[Survival Alert] Monthly Rolling Stock Check';

  @override
  String notificationMonthlyBody(int count) {
    return '[Survival Alert] $count items need replacement this month. Consume them before expiration!';
  }

  @override
  String get notificationInspectionTitle =>
      '[Survival Alert] 6-Month Gear Inspection Due';

  @override
  String get notificationInspectionBody =>
      'Time to inspect battery leakage, power bank charge, and seasonal survival gear.';

  @override
  String consumeAndRestock(int months) {
    return 'Consume & Restock (+${months}m)';
  }

  @override
  String restockedToast(String name, int months) {
    return '$name restocked! Expiry extended by $months months.';
  }

  @override
  String get addItem => 'Add Supply';

  @override
  String get quickPresets => '1-Tap Expiry Presets';

  @override
  String get itemNameLabel => 'Item or Pouch/Batch Name';

  @override
  String get itemNameHint => 'e.g., Snack Pouch #1, Bottled Water';

  @override
  String get categoryLabel => 'Category';

  @override
  String get storageLocationLabel => 'Storage Location (Optional)';

  @override
  String get storageLocationHint => 'e.g., Top Pouch, Pantry Tier 2';

  @override
  String get expiryMonthLabel => 'Expiry Year-Month (YYYY-MM)';

  @override
  String get shelfLifeMonthsLabel => 'Default Shelf Life (Months)';

  @override
  String get saveItem => 'Save to Inventory';

  @override
  String get emptyInventory => 'No supplies registered in this mode yet.';

  @override
  String get allCategories => 'All';

  @override
  String get presetRamyeon => 'Instant Noodles (+6m)';

  @override
  String get presetWater => 'Water (+12m)';

  @override
  String get presetFirstAid => 'First Aid (+24m)';

  @override
  String get presetCanned => 'Canned Goods (+36m)';

  @override
  String get presetFreezeDried => 'Freeze-Dried Rice (+60m)';

  @override
  String get presetBatteries => 'Alkaline Batteries (+36m)';

  @override
  String get catBagFoodWater => 'Food & Water';

  @override
  String get catBagFirstAid => 'First Aid & Hygiene';

  @override
  String get catBagWarmth => 'Warmth & Protective Gear';

  @override
  String get catBagLightComm => 'Light & Comm';

  @override
  String get catBagTools => 'Tools & Safety';

  @override
  String get catShelterFoodWater => 'Bulk Food & Water';

  @override
  String get catShelterEnergy => 'Emergency Energy & Cooking';

  @override
  String get catShelterSanitation => 'Sanitation & Waste';

  @override
  String get catShelterMedical => 'Medical & Care';

  @override
  String get catShelterDefense => 'Home Defense & Repair';

  @override
  String get selectYearMonth => 'Select Expiry Year & Month';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get expiredBadge => 'EXPIRED';

  @override
  String get d30Badge => 'D-30 URGENT';

  @override
  String get d60Badge => 'D-60 SOON';

  @override
  String get safeBadge => 'READY';
}
