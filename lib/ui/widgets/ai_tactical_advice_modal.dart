import 'package:flutter/material.dart';
import '../../core/theme/tactical_theme.dart';
import '../../models/item.dart';
import '../../models/survival_mode.dart';

class AiAdviceResult {
  final String headline;
  final String statusAssessment;
  final List<String> priorityActionPoints;
  final String tacticalTip;

  const AiAdviceResult({
    required this.headline,
    required this.statusAssessment,
    required this.priorityActionPoints,
    required this.tacticalTip,
  });
}

class AiTacticalAnalyzer {
  static AiAdviceResult analyze({
    required List<Item> items,
    required int householdCount,
    required bool isKo,
    SurvivalMode? mode,
  }) {
    final now = DateTime.now();
    final total = items.length;
    final owned = items.where((e) => e.isOwned).toList();
    final missing = items.where((e) => !e.isOwned).toList();
    final expiringSoon =
        owned.where((e) => e.hasExpiry && e.daysUntilExpiry(now) <= 60).toList();
    final percent = total == 0 ? 0 : ((owned.length / total) * 100).round();

    // Check critical missing categories
    final missingWaterOrFood = missing
        .where((e) =>
            e.category.contains('Food') || e.category.contains('Bulk Food'))
        .toList();
    final missingMedical = missing
        .where((e) =>
            e.category.contains('First Aid') || e.category.contains('Medical'))
        .toList();
    final missingSanitation =
        missing.where((e) => e.category.contains('Sanitation')).toList();
    final missingPowerOrLight = missing
        .where((e) =>
            e.category.contains('Light') || e.category.contains('Energy'))
        .toList();

    // 1. Build 1-Line Headline
    String headline;
    if (missingWaterOrFood.isNotEmpty) {
      final firstItem = missingWaterOrFood.first.displayName(isKo);
      headline = isKo
          ? '$householdCount인 기준 식량·식수($firstItem 등) 우선 확보가 필요합니다'
          : 'Priority: Secure water & food ($firstItem) for $householdCount people';
    } else if (missingSanitation.isNotEmpty) {
      headline = isKo
          ? '단수 시 가장 취약한 위생·간이변기 물자 보강이 시급합니다'
          : 'Urgent: Sanitation & emergency toilet supplies are missing';
    } else if (missingMedical.isNotEmpty) {
      final firstMed = missingMedical.first.displayName(isKo);
      headline = isKo
          ? '응급 상황에 대비해 [$firstMed] 구비를 권장합니다'
          : 'Recommended: Pack [$firstMed] for medical emergencies';
    } else if (expiringSoon.isNotEmpty) {
      headline = isKo
          ? '60일 내 만료 예정 품목 ${expiringSoon.length}건의 순환 소비(롤링스톡)가 필요합니다'
          : '${expiringSoon.length} items expire within 60 days — rotate stock soon';
    } else if (percent < 70) {
      headline = isKo
          ? '현재 준비율 $percent% — 통신·보온 등 미보유 장비 ${missing.length}종을 점검하세요'
          : 'Readiness at $percent% — review ${missing.length} remaining gear items';
    } else {
      headline = isKo
          ? '비축 상태 우수($percent%)! 가방 무게 배분과 배터리 방전 상태만 유지하세요'
          : 'Excellent readiness ($percent%)! Maintain battery charge & weight balance';
    }

    // 2. Build Status Assessment Paragraph
    final modeTitle = mode == null
        ? (isKo ? '전체 생존·재택 비축' : 'overall emergency inventory')
        : (mode == SurvivalMode.survivalBag
            ? (isKo ? '72시간 생존가방' : '72h Survival Bag')
            : (isKo ? '30일 재택 고립 비축' : '30d Shelter-in-Place'));

    final statusAssessment = isKo
        ? '현재 [$householdCount인 가족/대피 기준] $modeTitle 준비율은 $percent% (총 $total종 중 ${owned.length}종 확보, ${missing.length}종 미보유)입니다. '
            '${percent >= 75 ? "핵심 생존 물자가 안정적으로 확보되어 있습니다." : "초기 골든타임을 버티기 위해 아래 우선순위 품목부터 단계적으로 채워 넣는 것이 좋습니다."}'
        : 'Based on a household of $householdCount, your $modeTitle readiness is $percent% (${owned.length} of $total items packed, ${missing.length} missing). '
            '${percent >= 75 ? "Your core survival baseline is well-established." : "Focus on acquiring the top-priority missing items below to secure your golden-hour survival."}';

    // 3. Build Priority Action Points
    final actions = <String>[];
    if (missingWaterOrFood.isNotEmpty) {
      final names =
          missingWaterOrFood.take(2).map((e) => e.displayName(isKo)).join(', ');
      actions.add(isKo
          ? '💧 [식수·식량 보충] $names 품목이 미보유 상태입니다. $householdCount인 기준 최소 수량을 가장 먼저 확보하세요.'
          : '💧 [Water & Food] Missing: $names. Secure baseline quantities for $householdCount people first.');
    }
    if (missingSanitation.isNotEmpty) {
      actions.add(isKo
          ? '🚽 [단수 대비 위생] 아파트·주택 고립 시 정전보다 무서운 것이 단수로 인한 화장실 마비입니다. 간이변기 응고제(${householdCount * 60}회분 권장)를 꼭 구비하세요.'
          : '🚽 [Water Outage Sanitation] Loss of plumbing is critical indoors. Stock coagulant toilet bags (${householdCount * 60} uses recommended).');
    }
    if (missingMedical.isNotEmpty) {
      final names =
          missingMedical.take(2).map((e) => e.displayName(isKo)).join(', ');
      actions.add(isKo
          ? '🩹 [응급·상비약] $names 등 의료 물자를 챙기세요. 평소 복용하는 개인 처방약은 최소 7일분을 별도 지퍼백에 넣어야 합니다.'
          : '🩹 [Medical Care] Pack $names and at least 7 days of personal prescription medications.');
    }
    if (missingPowerOrLight.isNotEmpty) {
      final names = missingPowerOrLight
          .take(2)
          .map((e) => e.displayName(isKo))
          .join(', ');
      actions.add(isKo
          ? '🔦 [조명·통신·에너지] 정전 및 통신 두절에 대비해 $names 품목을 보강하세요.'
          : '🔦 [Power & Comm] Add $names to prepare for blackouts and grid failure.');
    }
    if (expiringSoon.isNotEmpty) {
      final expNames = expiringSoon
          .take(2)
          .map((e) => '${e.displayName(isKo)}(${e.formattedExpiryMonth})')
          .join(', ');
      actions.add(isKo
          ? '🔄 [롤링스톡 순환] $expNames 등 ${expiringSoon.length}개 품목의 교체 주기가 도래했습니다. 일상 식사로 소비하고 새 제품으로 교체하세요.'
          : '🔄 [Rolling Stock] ${expiringSoon.length} items ($expNames) expire within 60 days. Consume and restock.');
    }
    if (actions.isEmpty) {
      actions.add(isKo
          ? '✅ 모든 핵심 카테고리 품목이 골고루 구비되어 있습니다. 6개월 주기로 보조배터리 잔량과 건전지 누액 여부만 점검하세요.'
          : '✅ All critical categories are well stocked. Perform semi-annual checks on power banks and batteries.');
    }

    // 4. Build Tactical Tip
    final tacticalTip = mode == SurvivalMode.shelterInPlace
        ? (isKo
            ? '💡 실전 팁: 30일 재택 비축 시 생수 페트병은 직사광선이 닿지 않는 서늘한 바닥에 보관하고, 부탄가스는 녹이 슬지 않도록 습기 제거제와 함께 보관하세요.'
            : '💡 Pro Tip: Store 2L water bottles away from direct sunlight on a cool floor, and keep butane canisters in a dry cabinet to prevent rust.')
        : (isKo
            ? '💡 실전 팁: 72시간 생존가방은 전체 무게가 체중의 15~20%를 넘지 않아야 도보 대피가 가능합니다. 무거운 생수와 식량은 등판 위쪽에, 구급함과 랜턴은 가장 바깥 포켓에 넣으세요.'
            : '💡 Pro Tip: Keep your 72h bug-out bag under 15–20% of your body weight. Pack heavy water close to your upper back and keep flashlights and first-aid in outer pockets.');

    return AiAdviceResult(
      headline: headline,
      statusAssessment: statusAssessment,
      priorityActionPoints: actions,
      tacticalTip: tacticalTip,
    );
  }
}

/// Compact 1-Line AI Advice Banner displayed right below the Readiness Progress Card.
/// Tapping opens the full `AiTacticalAdviceModal`.
class AiAdviceCompactBanner extends StatelessWidget {
  final List<Item> items;
  final int householdCount;
  final bool isKo;
  final SurvivalMode? mode;

  const AiAdviceCompactBanner({
    super.key,
    required this.items,
    required this.householdCount,
    required this.isKo,
    this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final advice = AiTacticalAnalyzer.analyze(
      items: items,
      householdCount: householdCount,
      isKo: isKo,
      mode: mode,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => AiTacticalAdviceModal.show(
        context,
        advice: advice,
        isKo: isKo,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF172554).withOpacity(0.55), // Deep tactical indigo
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF38BDF8).withOpacity(0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isKo ? 'AI 조언' : 'AI Tip',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                advice.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 18,
              color: Color(0xFF38BDF8),
            ),
          ],
        ),
      ),
    );
  }
}

class AiTacticalAdviceModal extends StatelessWidget {
  final AiAdviceResult advice;
  final bool isKo;

  const AiTacticalAdviceModal({
    super.key,
    required this.advice,
    required this.isKo,
  });

  static Future<void> show(
    BuildContext context, {
    required AiAdviceResult advice,
    required bool isKo,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TacticalTheme.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AiTacticalAdviceModal(advice: advice, isKo: isKo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TacticalTheme.slate700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF38BDF8),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isKo ? 'AI 생존 비축 정밀 분석 리포트' : 'AI Tactical Readiness Analysis',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Headline Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF172554).withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF38BDF8).withOpacity(0.5),
              ),
            ),
            child: Text(
              advice.headline,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status Assessment
          Text(
            advice.statusAssessment,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Priority Action Points
          Text(
            isKo ? '📌 맞춤형 핵심 조치 사항' : '📌 Priority Action Items',
            style: const TextStyle(
              color: TacticalTheme.amber500,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...advice.priorityActionPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: TacticalTheme.slate900,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: TacticalTheme.slate700),
                ),
                child: Text(
                  point,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Tactical Pro Tip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TacticalTheme.amber500.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: TacticalTheme.amber500.withOpacity(0.4),
              ),
            ),
            child: Text(
              advice.tacticalTip,
              style: const TextStyle(
                color: TacticalTheme.amber500,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TacticalTheme.amber500,
                foregroundColor: TacticalTheme.slate900,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isKo ? '확인 완료' : 'Got It',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
