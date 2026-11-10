import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'generated_l10n_en.dart';
import 'generated_l10n_ja.dart';
import 'generated_l10n_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GeneratedAppLocalizations
/// returned by `GeneratedAppLocalizations.of(context)`.
///
/// Applications need to include `GeneratedAppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/generated_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GeneratedAppLocalizations.localizationsDelegates,
///   supportedLocales: GeneratedAppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GeneratedAppLocalizations.supportedLocales
/// property.
abstract class GeneratedAppLocalizations {
  GeneratedAppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GeneratedAppLocalizations of(BuildContext context) {
    return Localizations.of<GeneratedAppLocalizations>(
        context, GeneratedAppLocalizations)!;
  }

  static const LocalizationsDelegate<GeneratedAppLocalizations> delegate =
      _GeneratedAppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Survival & Shelter Manager'**
  String get appTitle;

  /// No description provided for @modeSurvivalBag.
  ///
  /// In en, this message translates to:
  /// **'72h Survival Bag'**
  String get modeSurvivalBag;

  /// No description provided for @modeShelterInPlace.
  ///
  /// In en, this message translates to:
  /// **'30d Shelter-in-Place'**
  String get modeShelterInPlace;

  /// No description provided for @inspectionTitle.
  ///
  /// In en, this message translates to:
  /// **'6-Month Periodic Inspection'**
  String get inspectionTitle;

  /// No description provided for @inspectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check battery leakage, power bank charge & seasonal gear'**
  String get inspectionSubtitle;

  /// No description provided for @inspectionDueInDays.
  ///
  /// In en, this message translates to:
  /// **'Next check in {days} days'**
  String inspectionDueInDays(int days);

  /// No description provided for @inspectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Inspection Overdue!'**
  String get inspectionOverdue;

  /// No description provided for @completeInspection.
  ///
  /// In en, this message translates to:
  /// **'Complete Inspection'**
  String get completeInspection;

  /// No description provided for @inspectionResetToast.
  ///
  /// In en, this message translates to:
  /// **'Inspection completed! Next check scheduled in 6 months.'**
  String get inspectionResetToast;

  /// No description provided for @monthlyDigestBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} items expiring within 60 days. Tap to review.'**
  String monthlyDigestBanner(int count);

  /// No description provided for @monthlyDigestTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rolling Stock Digest'**
  String get monthlyDigestTitle;

  /// No description provided for @monthlyDigestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consume and replace these items before expiration to maintain readiness.'**
  String get monthlyDigestSubtitle;

  /// No description provided for @notificationMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'[Survival Alert] Monthly Rolling Stock Check'**
  String get notificationMonthlyTitle;

  /// No description provided for @notificationMonthlyBody.
  ///
  /// In en, this message translates to:
  /// **'[Survival Alert] {count} items need replacement this month. Consume them before expiration!'**
  String notificationMonthlyBody(int count);

  /// No description provided for @notificationInspectionTitle.
  ///
  /// In en, this message translates to:
  /// **'[Survival Alert] 6-Month Gear Inspection Due'**
  String get notificationInspectionTitle;

  /// No description provided for @notificationInspectionBody.
  ///
  /// In en, this message translates to:
  /// **'Time to inspect battery leakage, power bank charge, and seasonal survival gear.'**
  String get notificationInspectionBody;

  /// No description provided for @consumeAndRestock.
  ///
  /// In en, this message translates to:
  /// **'Consume & Restock (+{months}m)'**
  String consumeAndRestock(int months);

  /// No description provided for @restockedToast.
  ///
  /// In en, this message translates to:
  /// **'{name} restocked! Expiry extended by {months} months.'**
  String restockedToast(String name, int months);

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Supply'**
  String get addItem;

  /// No description provided for @quickPresets.
  ///
  /// In en, this message translates to:
  /// **'1-Tap Expiry Presets'**
  String get quickPresets;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item or Pouch/Batch Name'**
  String get itemNameLabel;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Snack Pouch #1, Bottled Water'**
  String get itemNameHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @storageLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Location (Optional)'**
  String get storageLocationLabel;

  /// No description provided for @storageLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Top Pouch, Pantry Tier 2'**
  String get storageLocationHint;

  /// No description provided for @expiryMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Year-Month (YYYY-MM)'**
  String get expiryMonthLabel;

  /// No description provided for @shelfLifeMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Shelf Life (Months)'**
  String get shelfLifeMonthsLabel;

  /// No description provided for @saveItem.
  ///
  /// In en, this message translates to:
  /// **'Save to Inventory'**
  String get saveItem;

  /// No description provided for @emptyInventory.
  ///
  /// In en, this message translates to:
  /// **'No supplies registered in this mode yet.'**
  String get emptyInventory;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @presetRamyeon.
  ///
  /// In en, this message translates to:
  /// **'Instant Noodles (+6m)'**
  String get presetRamyeon;

  /// No description provided for @presetWater.
  ///
  /// In en, this message translates to:
  /// **'Water (+12m)'**
  String get presetWater;

  /// No description provided for @presetFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First Aid (+24m)'**
  String get presetFirstAid;

  /// No description provided for @presetCanned.
  ///
  /// In en, this message translates to:
  /// **'Canned Goods (+36m)'**
  String get presetCanned;

  /// No description provided for @presetFreezeDried.
  ///
  /// In en, this message translates to:
  /// **'Freeze-Dried Rice (+60m)'**
  String get presetFreezeDried;

  /// No description provided for @presetBatteries.
  ///
  /// In en, this message translates to:
  /// **'Alkaline Batteries (+36m)'**
  String get presetBatteries;

  /// No description provided for @catBagFoodWater.
  ///
  /// In en, this message translates to:
  /// **'Food & Water'**
  String get catBagFoodWater;

  /// No description provided for @catBagFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First Aid & Hygiene'**
  String get catBagFirstAid;

  /// No description provided for @catBagWarmth.
  ///
  /// In en, this message translates to:
  /// **'Warmth & Protective Gear'**
  String get catBagWarmth;

  /// No description provided for @catBagLightComm.
  ///
  /// In en, this message translates to:
  /// **'Light & Comm'**
  String get catBagLightComm;

  /// No description provided for @catBagTools.
  ///
  /// In en, this message translates to:
  /// **'Tools & Safety'**
  String get catBagTools;

  /// No description provided for @catShelterFoodWater.
  ///
  /// In en, this message translates to:
  /// **'Bulk Food & Water'**
  String get catShelterFoodWater;

  /// No description provided for @catShelterEnergy.
  ///
  /// In en, this message translates to:
  /// **'Emergency Energy & Cooking'**
  String get catShelterEnergy;

  /// No description provided for @catShelterSanitation.
  ///
  /// In en, this message translates to:
  /// **'Sanitation & Waste'**
  String get catShelterSanitation;

  /// No description provided for @catShelterMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical & Care'**
  String get catShelterMedical;

  /// No description provided for @catShelterDefense.
  ///
  /// In en, this message translates to:
  /// **'Home Defense & Repair'**
  String get catShelterDefense;

  /// No description provided for @selectYearMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Expiry Year & Month'**
  String get selectYearMonth;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @expiredBadge.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get expiredBadge;

  /// No description provided for @d30Badge.
  ///
  /// In en, this message translates to:
  /// **'D-30 URGENT'**
  String get d30Badge;

  /// No description provided for @d60Badge.
  ///
  /// In en, this message translates to:
  /// **'D-60 SOON'**
  String get d60Badge;

  /// No description provided for @safeBadge.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get safeBadge;
}

class _GeneratedAppLocalizationsDelegate
    extends LocalizationsDelegate<GeneratedAppLocalizations> {
  const _GeneratedAppLocalizationsDelegate();

  @override
  Future<GeneratedAppLocalizations> load(Locale locale) {
    return SynchronousFuture<GeneratedAppLocalizations>(
        lookupGeneratedAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_GeneratedAppLocalizationsDelegate old) => false;
}

GeneratedAppLocalizations lookupGeneratedAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return GeneratedAppLocalizationsEn();
    case 'ja':
      return GeneratedAppLocalizationsJa();
    case 'ko':
      return GeneratedAppLocalizationsKo();
  }

  throw FlutterError(
      'GeneratedAppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
