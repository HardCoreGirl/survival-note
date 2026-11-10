// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'generated_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class GeneratedAppLocalizationsJa extends GeneratedAppLocalizations {
  GeneratedAppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '防災バッグ＆備蓄マネージャー';

  @override
  String get modeSurvivalBag => '72時間 非常用持出袋';

  @override
  String get modeShelterInPlace => '30日間 在宅避難備蓄';

  @override
  String get inspectionTitle => '6ヶ月定期点検';

  @override
  String get inspectionSubtitle => '電池の液漏れ・モバイルバッテリー残量・季節用品の点検';

  @override
  String inspectionDueInDays(int days) {
    return '次回点検まであと$days日';
  }

  @override
  String get inspectionOverdue => '定期点検期限超過！';

  @override
  String get completeInspection => '点検完了（6ヶ月延長）';

  @override
  String get inspectionResetToast => '定期点検完了！6ヶ月後に再通知します。';

  @override
  String monthlyDigestBanner(int count) {
    return '60日以内に交換が必要な備蓄品が$count件あります';
  }

  @override
  String get monthlyDigestTitle => '月次ローリングストックレポート';

  @override
  String get monthlyDigestSubtitle => '賞味期限・使用期限が切れる前に消費し、新しいものを補充しましょう。';

  @override
  String get notificationMonthlyTitle => '[防災アラート] 月次備蓄品チェック';

  @override
  String notificationMonthlyBody(int count) {
    return '[防災アラート] 今月交換が必要な品目が$count個あります。期限前に消費しましょう！';
  }

  @override
  String get notificationInspectionTitle => '[防災アラート] 6ヶ月定期点検日';

  @override
  String get notificationInspectionBody => '電池の液漏れやモバイルバッテリーの充電状態を点検してください。';

  @override
  String consumeAndRestock(int months) {
    return '消費して補充 (+$monthsヶ月)';
  }

  @override
  String restockedToast(String name, int months) {
    return '$nameを補充しました！期限が$monthsヶ月延長されました。';
  }

  @override
  String get addItem => '備蓄品を追加';

  @override
  String get quickPresets => 'ワンタップ期限プリセット';

  @override
  String get itemNameLabel => '品目名またはポーチ・セット名';

  @override
  String get itemNameHint => '例：非常食ポーチ#1、保存水2L箱';

  @override
  String get categoryLabel => 'カテゴリー';

  @override
  String get storageLocationLabel => '保管場所（任意）';

  @override
  String get storageLocationHint => '例：バッグ上部ポケット、パントリー2段目';

  @override
  String get expiryMonthLabel => '期限 年-月 (YYYY-MM)';

  @override
  String get shelfLifeMonthsLabel => '基本交換周期（ヶ月）';

  @override
  String get saveItem => '備蓄リストに保存';

  @override
  String get emptyInventory => 'このモードに登録された備蓄品はありません。';

  @override
  String get allCategories => 'すべて';

  @override
  String get presetRamyeon => '即席麺 (+6m)';

  @override
  String get presetWater => '保存水 (+12m)';

  @override
  String get presetFirstAid => '救急用品 (+24m)';

  @override
  String get presetCanned => '缶詰 (+36m)';

  @override
  String get presetFreezeDried => 'アルファ米 (+60m)';

  @override
  String get presetBatteries => 'アルカリ乾電池 (+36m)';

  @override
  String get catBagFoodWater => '食料＆水';

  @override
  String get catBagFirstAid => '救急＆衛生';

  @override
  String get catBagWarmth => '防寒＆保護具';

  @override
  String get catBagLightComm => '照明＆通信';

  @override
  String get catBagTools => 'ツール＆安全';

  @override
  String get catShelterFoodWater => '大容量食料＆水';

  @override
  String get catShelterEnergy => '非常用電源＆調理';

  @override
  String get catShelterSanitation => '衛生＆汚物処理';

  @override
  String get catShelterMedical => '常備薬＆ケア';

  @override
  String get catShelterDefense => '自宅防衛＆補修';

  @override
  String get selectYearMonth => '期限の年月を選択';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get expiredBadge => '期限切れ';

  @override
  String get d30Badge => 'D-30 緊急';

  @override
  String get d60Badge => 'D-60 注意';

  @override
  String get safeBadge => '良好';
}
