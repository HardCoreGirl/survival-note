import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/tactical_theme.dart';
import '../../core/utils/url_opener.dart';
import '../../models/item.dart';

/// 쿠팡 파트너스 및 아마존 어소시에이트 링크 관리 설정
class AffiliateConfig {
  /// 아마존 어소시에이트 트래킹 태그 (발급 후 본인 태그로 교체하세요. 예: 'survivalnote-20')
  static const String amazonAssociateTag = 'survivalnote-20';

  /// 품목 ID별 쿠팡 파트너스 전용 단축 링크 (발급받은 https://link.coupang.com/... 링크를 등록하면 우선 적용됩니다)
  static const Map<String, String> customCoupangLinks = {
    // 예시: 'bag_water_2l': 'https://link.coupang.com/a/bXXXXXX',
  };

  /// 품목 ID별 아마존 전용 어소시에이트 링크 (특정 상품 직링크가 있을 경우 등록)
  static const Map<String, String> customAmazonLinks = {
    // 예시: 'bag_water_2l': 'https://amzn.to/XXXXXXX',
  };

  /// 한국어 모드용 쿠팡 이동 URL 생성
  static String buildCoupangUrl(Item item) {
    if (item.affiliateUrlKr != null && item.affiliateUrlKr!.trim().isNotEmpty) {
      return item.affiliateUrlKr!.trim();
    }
    final customUrl = customCoupangLinks[item.id];
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    // 괄호 안 부가 설명을 제거하여 깔끔한 검색어 추출 (예: "비상용 생수 (500ml 소분)" -> "비상용 생수 500ml")
    final rawName = item.displayName(true);
    final cleanKeyword = rawName
        .replaceAll(RegExp(r'[\(\)]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final encoded = Uri.encodeQueryComponent(cleanKeyword);
    return 'https://www.coupang.com/np/search?component=&q=$encoded';
  }

  /// 영어 모드용 아마존 이동 URL 생성 (Amazon OneLink를 통해 접속 국가 아마존으로 자동 연결됨)
  static String buildAmazonUrl(Item item) {
    if (item.affiliateUrlEn != null && item.affiliateUrlEn!.trim().isNotEmpty) {
      return item.affiliateUrlEn!.trim();
    }
    final customUrl = customAmazonLinks[item.id];
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    final rawName = item.name;
    final cleanKeyword = rawName
        .replaceAll(RegExp(r'[\(\)]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final encoded = Uri.encodeQueryComponent(cleanKeyword);
    return 'https://www.amazon.com/s?k=$encoded&tag=$amazonAssociateTag';
  }
}

class AffiliatePurchaseDialog extends StatelessWidget {
  final Item item;
  final int householdCount;
  final bool isKo;

  const AffiliatePurchaseDialog({
    super.key,
    required this.item,
    required this.householdCount,
    required this.isKo,
  });

  static Future<void> show(
    BuildContext context, {
    required Item item,
    required int householdCount,
    required bool isKo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AffiliatePurchaseDialog(
        item: item,
        householdCount: householdCount,
        isKo: isKo,
      ),
    );
  }

  String _buyingTip() {
    if (item.hasExpiry) {
      return isKo
          ? '💡 팁: 비상 비축용 식품·의약품은 제조일자가 최근이고 유통기한이 최소 1년 이상 넉넉한 상품을 선택하세요.'
          : '💡 Tip: For emergency food & medical supplies, choose products with the longest remaining shelf life.';
    }
    return isKo
        ? '💡 팁: 재난 시 즉시 사용할 수 있도록 내구성이 검증된 제품과 호환 건전지/충전 케이블 구성을 함께 확인하세요.'
        : '💡 Tip: Choose durable, field-tested gear and verify compatible batteries or charging cables.';
  }

  @override
  Widget build(BuildContext context) {
    final Color priorityColor;
    final String priorityText;
    if (item.importance >= 3) {
      priorityColor = const Color(0xFFF43F5E);
      priorityText = isKo ? '필수 품목' : 'ESSENTIAL';
    } else if (item.importance == 2) {
      priorityColor = const Color(0xFF0EA5E9);
      priorityText = isKo ? '권장 품목' : 'RECOMMENDED';
    } else {
      priorityColor = const Color(0xFF64748B);
      priorityText = isKo ? '선택 품목' : 'OPTIONAL';
    }

    final targetUrl = isKo
        ? AffiliateConfig.buildCoupangUrl(item)
        : AffiliateConfig.buildAmazonUrl(item);

    final storeColor = isKo
        ? const Color(0xFFE62E2D) // Coupang Red
        : const Color(0xFFFF9900); // Amazon Orange/Gold

    final storeButtonLabel = isKo
        ? '쿠팡에서 최저가 검색 / 구매하기'
        : 'Search & Buy on Amazon';

    final disclosureText = isKo
        ? '이 서비스는 쿠팡 파트너스 활동의 일환으로, 이에 따른 일정액의 수수료를 제공받습니다. (구매자에게 추가 비용이 발생하지 않습니다.)'
        : 'As an Amazon Associate, we earn from qualifying purchases at no additional cost to you.';

    return Dialog(
      backgroundColor: TacticalTheme.slate800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TacticalTheme.slate700, width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TacticalTheme.amber500.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TacticalTheme.amber500.withOpacity(0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: TacticalTheme.amber500,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priorityText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.displayName(isKo),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: TacticalTheme.slate400,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Household Recommended Quantity Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TacticalTheme.slate900.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TacticalTheme.slate700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.groups_rounded,
                              size: 16,
                              color: TacticalTheme.amber500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isKo
                                  ? '우리 가족 ($householdCount명) 권장 준비량'
                                  : 'Recommended for $householdCount ${householdCount == 1 ? "Person" : "People"}',
                              style: const TextStyle(
                                color: TacticalTheme.slate400,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TacticalTheme.amber500.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: TacticalTheme.amber500),
                          ),
                          child: Text(
                            item.formattedRecommendedQuantity(
                              householdCount,
                              isKo,
                            ),
                            style: const TextStyle(
                              color: TacticalTheme.amber500,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _buyingTip(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Primary Store Action Button (KO -> Coupang ONLY / EN -> Amazon ONLY)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: storeColor,
                  foregroundColor: isKo ? Colors.white : TacticalTheme.slate900,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final opened = await openExternalUrl(targetUrl);
                  if (!opened && context.mounted) {
                    await Clipboard.setData(ClipboardData(text: targetUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isKo
                                ? '구매 링크가 클립보드에 복사되었습니다: $targetUrl'
                                : 'Store link copied to clipboard: $targetUrl',
                          ),
                        ),
                      );
                    }
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(
                  isKo ? Icons.rocket_launch_rounded : Icons.shopping_bag_rounded,
                  size: 19,
                ),
                label: Text(
                  storeButtonLabel,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Mandatory Affiliate Disclosure Notice Box (FTC / Coupang / Amazon Policy Compliant)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: TacticalTheme.slate900.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TacticalTheme.slate700.withOpacity(0.7),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: TacticalTheme.slate400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        disclosureText,
                        style: const TextStyle(
                          color: TacticalTheme.slate400,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
