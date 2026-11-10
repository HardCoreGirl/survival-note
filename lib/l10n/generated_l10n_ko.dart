// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'generated_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class GeneratedAppLocalizationsKo extends GeneratedAppLocalizations {
  GeneratedAppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '생존가방 & 피난처 비축 관리기';

  @override
  String get modeSurvivalBag => '72시간 생존가방';

  @override
  String get modeShelterInPlace => '30일 재택 고립 비축';

  @override
  String get inspectionTitle => '6개월 정기 점검';

  @override
  String get inspectionSubtitle => '건전지 누액, 보조배터리 방전, 계절 의류 교체 점검';

  @override
  String inspectionDueInDays(int days) {
    return '다음 점검까지 $days일 남음';
  }

  @override
  String get inspectionOverdue => '정기 점검 기한 경과!';

  @override
  String get completeInspection => '점검 완료 (6개월 연장)';

  @override
  String get inspectionResetToast => '정기 점검 완료! 6개월 뒤 다시 알림을 보냅니다.';

  @override
  String monthlyDigestBanner(int count) {
    return '60일 내 교체 필요 품목 $count건 (탭하여 확인)';
  }

  @override
  String get monthlyDigestTitle => '월간 롤링스톡(순환 비축) 리포트';

  @override
  String get monthlyDigestSubtitle => '유통기한 만료 전에 일상에서 소비하고 새 제품으로 보충하세요.';

  @override
  String get notificationMonthlyTitle => '[생존 알림] 월간 비축품 교체 점검';

  @override
  String notificationMonthlyBody(int count) {
    return '[생존 알림] 이번 달 교체가 필요한 품목이 $count개 있습니다. 유통기한 전에 소비하세요!';
  }

  @override
  String get notificationInspectionTitle => '[생존 알림] 6개월 정기 장비 점검일';

  @override
  String get notificationInspectionBody =>
      '건전지 누액, 보조배터리 충전 상태, 계절별 생존 장비를 점검할 시간입니다.';

  @override
  String consumeAndRestock(int months) {
    return '소비 후 재비축 (+$months개월)';
  }

  @override
  String restockedToast(String name, int months) {
    return '$name 재비축 완료! 유통기한이 $months개월 연장되었습니다.';
  }

  @override
  String get addItem => '비축품 등록';

  @override
  String get quickPresets => '원탭 유통기한 프리셋';

  @override
  String get itemNameLabel => '품목명 또는 파우치/묶음 이름';

  @override
  String get itemNameHint => '예: 비상식량 파우치 1호, 생수 2L 묶음';

  @override
  String get categoryLabel => '카테고리';

  @override
  String get storageLocationLabel => '보관 위치 (선택)';

  @override
  String get storageLocationHint => '예: 가방 상단 포켓, 팬트리 2단';

  @override
  String get expiryMonthLabel => '유통기한 연-월 (YYYY-MM)';

  @override
  String get shelfLifeMonthsLabel => '기본 교체 주기 (개월)';

  @override
  String get saveItem => '비축 목록에 저장';

  @override
  String get emptyInventory => '이 모드에 등록된 비축품이 없습니다.';

  @override
  String get allCategories => '전체';

  @override
  String get presetRamyeon => '라면 (+6개월)';

  @override
  String get presetWater => '생수 (+12개월)';

  @override
  String get presetFirstAid => '구급약 (+24개월)';

  @override
  String get presetCanned => '통조림 (+36개월)';

  @override
  String get presetFreezeDried => '동결건조밥 (+60개월)';

  @override
  String get presetBatteries => '알카라인 건전지 (+36개월)';

  @override
  String get catBagFoodWater => '식량 & 식수';

  @override
  String get catBagFirstAid => '구급 & 위생';

  @override
  String get catBagWarmth => '보온 & 보호장구';

  @override
  String get catBagLightComm => '조명 & 통신';

  @override
  String get catBagTools => '도구 & 안전';

  @override
  String get catShelterFoodWater => '대용량 식량 & 식수';

  @override
  String get catShelterEnergy => '비상 에너지 & 취사';

  @override
  String get catShelterSanitation => '위생 & 오물 처리';

  @override
  String get catShelterMedical => '상비약 & 돌봄';

  @override
  String get catShelterDefense => '가택 방어 & 보수';

  @override
  String get selectYearMonth => '유통기한 연/월 선택';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get expiredBadge => '만료됨';

  @override
  String get d30Badge => 'D-30 임박';

  @override
  String get d60Badge => 'D-60 주의';

  @override
  String get safeBadge => '양호';
}
