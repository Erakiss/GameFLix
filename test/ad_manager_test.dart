// test/ad_manager_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameflix/services/ad_manager.dart';
import 'package:gameflix/shared/widgets/hub_banner_ad.dart';

void main() {
  group('AdManager Unit Tests', () {
    final adManager = AdManager.instance;

    test('initialisation et cooldown par défaut de 4 minutes', () async {
      await adManager.init();
      expect(adManager.isInitialized, isTrue);
      expect(adManager.cooldownDuration, equals(const Duration(minutes: 4)));
    });

    test('respect strict du cooldown de 4 minutes pour les interstitiels', () {
      final baseTime = DateTime(2026, 1, 1, 20, 0, 0);
      adManager.setLastInterstitialShownAtForTest(baseTime);

      // 1. Immédiatement après : pas d'interstitiel autorisé
      expect(adManager.canShowInterstitial(now: baseTime), isFalse);

      // 2. Après 2 minutes : toujours bloqué
      final twoMinutesLater = baseTime.add(const Duration(minutes: 2));
      expect(adManager.canShowInterstitial(now: twoMinutesLater), isFalse);

      // 3. Après 3 minutes et 59 secondes : toujours bloqué
      final justBefore = baseTime.add(const Duration(minutes: 3, seconds: 59));
      expect(adManager.canShowInterstitial(now: justBefore), isFalse);

      // 4. Après exactement 4 minutes : autorisé
      final exactCooldown = baseTime.add(const Duration(minutes: 4));
      expect(adManager.canShowInterstitial(now: exactCooldown), isTrue);

      // 5. Après 10 minutes : autorisé
      final tenMinutesLater = baseTime.add(const Duration(minutes: 10));
      expect(adManager.canShowInterstitial(now: tenMinutesLater), isTrue);
    });

    test('résilience hors-ligne : showInterstitialIfAllowed ne plante pas sans ad chargée', () {
      final baseTime = DateTime(2026, 1, 1, 20, 0, 0);
      adManager.setLastInterstitialShownAtForTest(baseTime);

      final tenMinutesLater = baseTime.add(const Duration(minutes: 10));
      final result = adManager.showInterstitialIfAllowed(now: tenMinutesLater);

      // En mode test / hors-ligne sans pub chargée, retourne false sans crash
      expect(result, isFalse);
    });

    test('résilience Rewarded Ad : gère l\'absence de pub via onAdFailed sans crash', () {
      bool failedCalled = false;
      bool rewardEarned = false;

      adManager.showRewardedAd(
        onUserEarnedReward: () {
          rewardEarned = true;
        },
        onAdFailed: () {
          failedCalled = true;
        },
      );

      expect(failedCalled, isTrue);
      expect(rewardEarned, isFalse);
    });
  });

  group('HubBannerAd Widget Tests', () {
    testWidgets('HubBannerAd se replie gracieusement en environnement test sans crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HubBannerAd(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // En environnement de test, isSupportedPlatform est false -> SizedBox.shrink()
      expect(find.byType(HubBannerAd), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
