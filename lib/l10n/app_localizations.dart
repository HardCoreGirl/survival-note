import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Localization delegate supporting `en`, `ko`, and ready for `ja` expansion.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
  ];

  bool get _isKo => locale.languageCode == 'ko';

  String get appTitle =>
      _isKo ? '생존가방 & 피난처 비축 관리기' : 'Survival & Shelter Manager';
  String get modeSurvivalBag => _isKo ? '72시간 생존가방' : '72h Survival Bag';
  String get modeShelterInPlace =>
      _isKo ? '30일 재택 고립 비축' : '30d Shelter-in-Place';

  // Bottom Navigation Tabs (5 Tabs: Home, 72h Bag, 30d Shelter, Board, Settings)
  String get navHome => _isKo ? '홈' : 'Home';
  String get navBag => _isKo ? '72h 가방' : '72h Bag';
  String get navShelter => _isKo ? '30일 비축' : '30d Shelter';
  String get navBoard => _isKo ? '게시판' : 'Board';
  String get navSettings => _isKo ? '설정' : 'Settings';

  // Dashboard Home Strings
  String get dashboardOverallTitle =>
      _isKo ? '종합 재난 대비 브리핑' : 'Overall Preparedness Briefing';
  String dashboardOverallStatus(int percent) => _isKo
      ? '전체 평균 준비율 $percent%'
      : 'Total Readiness $percent%';
  String get dashboardTapToManage =>
      _isKo ? '탭하여 체크리스트 관리 →' : 'Tap to manage checklist →';
  String dashboardPackedVsMissing(int owned, int missing) => _isKo
      ? '보유 $owned건 • 미보유 $missing건'
      : '$owned Packed • $missing Missing';
  String get dashboardRollingStockOk => _isKo
      ? '60일 내 유통기한 만료 예정인 품목이 없습니다.'
      : 'No owned supplies expiring within 60 days.';

  // Home Warning Banners (Unlinked Account & Unconfigured Household)
  String homeWarnAccountUnlinked(String guestId) => _isKo
      ? '현재 게스트 모드($guestId)입니다. 기기 변경 시 데이터 보호를 위해 계정을 연동하세요.'
      : 'Running in Guest Mode ($guestId). Link your Google account to back up data.';
  String get homeWarnHouseholdUnset => _isKo
      ? '가족/대피 인원수가 아직 설정되지 않았습니다. 인원에 맞는 비축량 계산을 위해 설정해 주세요.'
      : 'Household headcount is not configured yet. Tap to set your family size.';
  String get homeWarnTapToSettings =>
      _isKo ? '설정으로 이동 ▸' : 'Go to Settings ▸';

  // Account & Guest ID Settings
  String get accountSectionTitle =>
      _isKo ? '계정 및 클라우드 기기 연동' : 'Account & Cloud Device Sync';
  String get guestBadge =>
      _isKo ? '게스트 모드 (로컬 저장)' : 'Guest Mode (Local Only)';
  String get googleLinkedBadge =>
      _isKo ? '✓ Google 연동 완료' : '✓ Google Linked';
  String get guestIdLabel =>
      _isKo ? '발급된 게스트 ID' : 'Assigned Guest ID';
  String get accountGuestDesc => _isKo
      ? '현재 이 기기(브라우저)에만 기록이 저장되고 있습니다. PC와 스마트폰을 연동하거나 데이터를 안전하게 보관하려면 Google 계정을 연결하세요.'
      : 'Data is currently stored only on this device. Link your Google account to sync across PC and mobile.';
  String accountLinkedDesc(String guestId) => _isKo
      ? '기존 게스트 데이터($guestId)가 Google 클라우드 계정에 안전하게 연결되어 모든 기기에서 동기화됩니다.'
      : 'Your guest data ($guestId) is linked and synced with your Google account.';
  String get linkGoogleButton =>
      _isKo ? 'Google 계정으로 기기 연동하기' : 'Link with Google Account';
  String get unlinkGoogleButton =>
      _isKo ? '연동 해제 (게스트 전환 테스트)' : 'Unlink Account (Test)';
  String get googleLinkedToast => _isKo
      ? 'Google 계정 연동이 완료되었습니다! 게스트 데이터가 유지됩니다.'
      : 'Successfully linked with Google account!';
  String get confirmHouseholdBtn =>
      _isKo ? '인원 설정 완료' : 'Confirm Headcount';
  String get householdConfirmedBadge =>
      _isKo ? '✓ 설정됨' : '✓ Configured';

  // Household / Evacuee Count Settings
  String get householdLabel =>
      _isKo ? '가족 / 대피 인원 설정' : 'Household / Evacuee Count';
  String get householdDescription => _isKo
      ? '설정된 인원수에 맞춰 체크리스트의 모든 식량·식수·구호품 권장 수량이 자동으로 계산됩니다.'
      : 'Recommended quantities for all food, water, and supplies automatically scale by this headcount.';
  String householdPeopleCount(int count) =>
      _isKo ? '$count인 기준' : '$count ${count == 1 ? "Person" : "People"}';
  String bagSupplySummary(int count) => _isKo
      ? '72시간 필수 목표량: 생수 ${count * 3}L (${count * 6}병) • 비상식량 ${count * 9}끼'
      : '72h Target for $count: Water ${count * 3}L (${count * 6} btls) • Food ${count * 9} meals';
  String shelterSupplySummary(int count) => _isKo
      ? '30일 필수 목표량: 생수 ${count * 60}L (2L×${count * 30}병) • 식량 ${count * 65}끼'
      : '30d Target for $count: Water ${count * 60}L (2L×${count * 30} btls) • Food ${count * 65} meals';
  String get qtyPerPersonLabel =>
      _isKo ? '기본 권장 수량' : 'Base Qty';

  // Settings Sections
  String get settingsLanguageTitle => _isKo ? '언어 설정 (Language)' : 'Language';
  String get settingsNotificationTitle =>
      _isKo ? '피로도 제로 스마트 알림 설정' : 'Anti-Fatigue Smart Notifications';
  String get settingsMonthlyDigestToggle =>
      _isKo ? '매월 1일 오전 10시 롤링스톡 요약 알림' : 'Monthly 1st 10:00 AM Rolling Stock Digest';
  String get settingsMonthlyDigestDesc => _isKo
      ? '개별 품목 알림 스팸 대신, 60일 내 만료 예정 품목을 묶어 한 달에 딱 한 번 알려줍니다.'
      : 'Groups items expiring within 60 days into a single monthly notification.';

  // Community Board
  String get boardTitle =>
      _isKo ? '생존 정보 & 비축 커뮤니티' : 'Survival Tips & Community';
  String get boardSubtitle => _isKo
      ? '재난 대비 노하우, 생존가방 세팅 인증, 롤링스톡 레시피를 공유하세요.'
      : 'Share emergency preparedness tips, bag setups, and rolling stock recipes.';
  String get boardWritePost => _isKo ? '글쓰기' : 'Write Post';
  String get boardCatAll => _isKo ? '전체' : 'All';
  String get boardCatTip => _isKo ? '생존 노하우' : 'Survival Tips';
  String get boardCatShowcase => _isKo ? '가방/비축 인증' : 'Gear Showcase';
  String get boardCatRecipe => _isKo ? '롤링스톡 요리' : 'Rolling Stock Recipes';
  String get boardCatQna => _isKo ? '질문/답변' : 'Q&A';
  String get postTitleLabel => _isKo ? '제목' : 'Title';
  String get postContentLabel => _isKo ? '내용' : 'Content';
  String get publishPost => _isKo ? '게시글 등록' : 'Publish';

  // Readiness & Checklist Filters
  String readinessTitle(int owned, int total, int percent) => _isKo
      ? '비축 준비율 $percent% ($owned / $total 품목 구비됨)'
      : 'Readiness $percent% ($owned / $total items packed)';
  String get readinessHint => _isKo
      ? '보유 중인 품목은 왼쪽 체크박스를 눌러 [보유중]으로 표시하세요.'
      : 'Check items you already have to track what is packed vs. missing.';
  String filterAll(int count) => _isKo ? '전체 ($count)' : 'All ($count)';
  String filterOwned(int count) =>
      _isKo ? '✓ 보유중 ($count)' : '✓ Have ($count)';
  String filterMissing(int count) =>
      _isKo ? '☐ 미보유 ($count)' : '☐ Missing ($count)';
  String get missingBadge => _isKo ? '미보유 (구비 필요)' : 'MISSING';
  String get permanentGearBadge => _isKo ? '장비 (반영구)' : 'GEAR (NO EXPIRY)';
  String get tapToSetExpiry => _isKo ? '유통기한 변경' : 'Change Expiry';
  String get tracksExpiryLabel =>
      _isKo ? '유통기한 관리 품목 (식량/약/배터리 등)' : 'Track Expiration Date';

  String get inspectionTitle =>
      _isKo ? '6개월 정기 점검' : '6-Month Periodic Inspection';
  String get inspectionSubtitle => _isKo
      ? '건전지 누액, 보조배터리 방전, 계절 의류 교체 점검'
      : 'Check battery leakage, power bank charge & seasonal gear';
  String inspectionDueInDays(int days) =>
      _isKo ? '다음 점검까지 $days일 남음' : 'Next check in $days days';
  String get inspectionOverdue =>
      _isKo ? '정기 점검 기한 경과!' : 'Inspection Overdue!';
  String get completeInspection =>
      _isKo ? '점검 완료 (6개월 연장)' : 'Complete Inspection';
  String get inspectionResetToast => _isKo
      ? '정기 점검 완료! 6개월 뒤 다시 알림을 보냅니다.'
      : 'Inspection completed! Next check scheduled in 6 months.';
  String monthlyDigestBanner(int count) => _isKo
      ? '보유 품목 중 60일 내 교체 필요 $count건 (탭하여 확인)'
      : '$count owned items expiring within 60 days. Tap to review.';
  String get monthlyDigestTitle =>
      _isKo ? '월간 롤링스톡(순환 비축) 리포트' : 'Monthly Rolling Stock Digest';
  String get monthlyDigestSubtitle => _isKo
      ? '유통기한 만료 전에 일상에서 소비하고 새 제품으로 보충하세요.'
      : 'Consume and replace these items before expiration to maintain readiness.';
  String get notificationMonthlyTitle => _isKo
      ? '[생존 알림] 월간 비축품 교체 점검'
      : '[Survival Alert] Monthly Rolling Stock Check';
  String notificationMonthlyBody(int count) => _isKo
      ? '[생존 알림] 이번 달 교체가 필요한 품목이 $count개 있습니다. 유통기한 전에 소비하세요!'
      : '[Survival Alert] $count items need replacement this month. Consume them before expiration!';
  String get notificationInspectionTitle => _isKo
      ? '[생존 알림] 6개월 정기 장비 점검일'
      : '[Survival Alert] 6-Month Gear Inspection Due';
  String get notificationInspectionBody => _isKo
      ? '건전지 누액, 보조배터리 충전 상태, 계절별 생존 장비를 점검할 시간입니다.'
      : 'Time to inspect battery leakage, power bank charge, and seasonal survival gear.';
  String consumeAndRestock(int months) =>
      _isKo ? '소비 후 재비축 (+$months개월)' : 'Consume & Restock (+${months}m)';
  String restockedToast(String name, int months) => _isKo
      ? '$name 재비축 완료! 유통기한이 $months개월 연장되었습니다.'
      : '$name restocked! Expiry extended by $months months.';
  String get addItem => _isKo ? '직접 품목 추가' : 'Add Custom Item';
  String get editItem => _isKo ? '품목 정보 및 메모 수정' : 'Edit Item & Memo';
  String get saveChanges => _isKo ? '수정 내용 저장' : 'Save Changes';
  String get deleteItem => _isKo ? '품목 삭제' : 'Delete';
  String get memoLabel => _isKo ? '간단 메모 (선택)' : 'Memo / Note (Optional)';
  String get memoHint => _isKo
      ? '예: 타이레놀 2통 + 어린이 해열제, 제주삼다수 묶음'
      : 'e.g., Brand name, specific details, family notes';
  String get importanceLabel => _isKo ? '중요도 등급' : 'Priority Level';
  String get priorityEssential => _isKo ? '필수' : 'ESSENTIAL';
  String get priorityRecommended => _isKo ? '권장' : 'RECOMMENDED';
  String get priorityOptional => _isKo ? '선택' : 'OPTIONAL';
  String get quickPresets => _isKo ? '원탭 유통기한 프리셋' : '1-Tap Expiry Presets';
  String get itemNameLabel =>
      _isKo ? '품목명 또는 파우치/묶음 이름' : 'Item or Pouch/Batch Name';
  String get itemNameHint => _isKo
      ? '예: 비상식량 파우치 1호, 생수 2L 묶음'
      : 'e.g., Snack Pouch #1, Bottled Water';
  String get categoryLabel => _isKo ? '카테고리' : 'Category';
  String get storageLocationLabel =>
      _isKo ? '보관 위치 (선택)' : 'Storage Location (Optional)';
  String get storageLocationHint =>
      _isKo ? '예: 가방 상단 포켓, 팬트리 2단' : 'e.g., Top Pouch, Pantry Tier 2';
  String get expiryMonthLabel =>
      _isKo ? '유통기한 연-월 (YYYY-MM)' : 'Expiry Year-Month (YYYY-MM)';
  String get shelfLifeMonthsLabel =>
      _isKo ? '기본 교체 주기 (개월)' : 'Default Shelf Life (Months)';
  String get saveItem => _isKo ? '체크리스트에 추가' : 'Save to Checklist';
  String get emptyInventory => _isKo
      ? '해당 조건에 맞는 품목이 없습니다.'
      : 'No supplies match the selected filter.';
  String get allCategories => _isKo ? '전체 카테고리' : 'All Categories';

  // Presets
  String get presetRamyeon => _isKo ? '라면 (+6개월)' : 'Instant Noodles (+6m)';
  String get presetWater => _isKo ? '생수 (+12개월)' : 'Water (+12m)';
  String get presetFirstAid => _isKo ? '구급약 (+24개월)' : 'First Aid (+24m)';
  String get presetCanned => _isKo ? '통조림 (+36개월)' : 'Canned Goods (+36m)';
  String get presetFreezeDried =>
      _isKo ? '동결건조밥 (+60개월)' : 'Freeze-Dried Rice (+60m)';
  String get presetBatteries =>
      _isKo ? '알카라인 건전지 (+36개월)' : 'Alkaline Batteries (+36m)';

  // Categories
  String get catBagFoodWater => _isKo ? '식량 & 식수' : 'Food & Water';
  String get catBagFirstAid => _isKo ? '구급 & 위생' : 'First Aid & Hygiene';
  String get catBagWarmth =>
      _isKo ? '보온 & 보호장구' : 'Warmth & Protective Gear';
  String get catBagLightComm => _isKo ? '조명 & 통신' : 'Light & Comm';
  String get catBagTools => _isKo ? '도구 & 안전' : 'Tools & Safety';

  String get catShelterFoodWater =>
      _isKo ? '대용량 식량 & 식수' : 'Bulk Food & Water';
  String get catShelterEnergy =>
      _isKo ? '비상 에너지 & 취사' : 'Emergency Energy & Cooking';
  String get catShelterSanitation =>
      _isKo ? '위생 & 오물 처리' : 'Sanitation & Waste';
  String get catShelterMedical => _isKo ? '상비약 & 돌봄' : 'Medical & Care';
  String get catShelterDefense =>
      _isKo ? '가택 방어 & 보수' : 'Home Defense & Repair';

  String get selectYearMonth =>
      _isKo ? '유통기한 연/월 선택' : 'Select Expiry Year & Month';
  String get cancel => _isKo ? '취소' : 'Cancel';
  String get confirm => _isKo ? '확인' : 'Confirm';
  String get expiredBadge => _isKo ? '만료됨' : 'EXPIRED';
  String get d30Badge => _isKo ? 'D-30 임박' : 'D-30 URGENT';
  String get d60Badge => _isKo ? 'D-60 주의' : 'D-60 SOON';
  String get safeBadge => _isKo ? '보유중 (양호)' : 'READY';

  String localizeCategory(String categoryKey) {
    switch (categoryKey) {
      case 'Food & Water':
        return catBagFoodWater;
      case 'First Aid & Hygiene':
        return catBagFirstAid;
      case 'Warmth & Protective Gear':
      case 'Warmth & Shelter':
        return catBagWarmth;
      case 'Light & Comm':
      case 'Communication & Admin':
        return catBagLightComm;
      case 'Tools & Safety':
      case 'Light & Tools':
        return catBagTools;
      case 'Bulk Food & Water':
      case 'Pantry & Sustenance':
        return catShelterFoodWater;
      case 'Emergency Energy & Cooking':
      case 'Cooking & Fuel':
        return catShelterEnergy;
      case 'Sanitation & Waste':
        return catShelterSanitation;
      case 'Medical & Care':
        return catShelterMedical;
      case 'Home Defense & Repair':
        return catShelterDefense;
      default:
        return categoryKey;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ko', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
