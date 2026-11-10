// test/access_control_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gameflix/state/access_control_provider.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessControlProvider Unit Tests', () {
    final access = AccessControlProvider.instance;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      access.clearForTest();
    });

    test('packs gratuits toujours accessibles', () {
      expect(access.canAccess('tod_classic', isPremium: false), isTrue);
      expect(access.canAccess('nhie_classic', isPremium: false), isTrue);
    });

    test('packs premium verrouillés par défaut', () {
      expect(access.canAccess('tod_hot', isPremium: true), isFalse);
      expect(access.canAccess('nhie_hot', isPremium: true), isFalse);
    });

    test('abonnement VIP débloque tous les packs de façon illimitée', () {
      access.setSubscribedForTest(true);

      expect(access.isSubscribed, isTrue);
      expect(access.canAccess('tod_hot', isPremium: true), isTrue);
      expect(access.canAccess('nhie_hot', isPremium: true), isTrue);
    });

    test('déblocage temporaire via Rewarded Ad pour la session active', () {
      expect(access.canAccess('nhie_hot', isPremium: true), isFalse);

      // Visionnage de pub récompensée
      access.unlockTemporarily('nhie_hot');

      // nhie_hot est débloqué
      expect(access.isTemporarilyUnlocked('nhie_hot'), isTrue);
      expect(access.canAccess('nhie_hot', isPremium: true), isTrue);

      // Mais un autre pack premium reste verrouillé
      expect(access.canAccess('tod_hot', isPremium: true), isFalse);
    });

    test('resetTemporaryUnlocks reverrouille les packs lors du retour au Hub', () {
      access.unlockTemporarily('nhie_hot');
      access.unlockTemporarily('tod_hot');

      expect(access.canAccess('nhie_hot', isPremium: true), isTrue);
      expect(access.canAccess('tod_hot', isPremium: true), isTrue);

      // Simulation du retour au Hub
      access.resetTemporaryUnlocks();

      expect(access.canAccess('nhie_hot', isPremium: true), isFalse);
      expect(access.canAccess('tod_hot', isPremium: true), isFalse);
      expect(access.temporarilyUnlockedPacks, isEmpty);
    });

    test('activateOneHourPass active le pass 1H et respecte la règle d\'unicité par appareil', () async {
      expect(access.isPass1hActive, isFalse);
      expect(access.hasUsedOneHourTrial, isFalse);
      expect(access.canAccess('tod_hot', isPremium: true), isFalse);

      // 1. Activation initiale du pass 1H
      final bool activated = await access.activateOneHourPass();
      expect(activated, isTrue);
      expect(access.isPass1hActive, isTrue);
      expect(access.hasUsedOneHourTrial, isTrue);
      expect(access.canAccess('tod_hot', isPremium: true), isTrue);
      expect(access.canAccess('nhie_hot', isPremium: true), isTrue);

      // 2. Simulation de l'expiration du pass
      access.setPass1hForTest(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        hasUsed: true,
      );
      expect(access.isPass1hActive, isFalse);
      expect(access.hasUsedOneHourTrial, isTrue);
      expect(access.canAccess('tod_hot', isPremium: true), isFalse);

      // 3. Tentative de réactivation sur le même appareil : doit échouer
      final bool secondAttempt = await access.activateOneHourPass();
      expect(secondAttempt, isFalse);
      expect(access.isPass1hActive, isFalse);
    });

    test('purchasePlan simule l\'abonnement en environnement de test', () async {
      expect(access.isSubscribed, isFalse);
      final success = await access.purchasePlan(isAnnual: true);
      expect(success, isTrue);
      expect(access.isSubscribed, isTrue);
    });

    test('redeemPromoCode avec ErakissLeBon débloque le mode pro éternellement', () async {
      expect(access.isSubscribed, isFalse);

      // 1. Code invalide
      final bool failed = await access.redeemPromoCode('MauvaisCode');
      expect(failed, isFalse);
      expect(access.isSubscribed, isFalse);

      // 2. Code valide (insensible à la casse)
      final bool success = await access.redeemPromoCode('ErakissLeBon');
      expect(success, isTrue);
      expect(access.isSubscribed, isTrue);
      expect(access.isPromoUnlocked, isTrue);
      expect(access.canAccess('tod_hot', isPremium: true), isTrue);
    });
  });

  group('NeonCategorySwitch Widget Tests', () {
    testWidgets('affiche le badge SPICY et le cadenas quand isLocked = true', (WidgetTester tester) async {
      bool lockedTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonCategorySwitch(
              title: 'HOT',
              color: Colors.redAccent,
              value: false,
              isLocked: true,
              onLockedTap: () {
                lockedTapped = true;
              },
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('HOT'), findsOneWidget);
      expect(find.text('SPICY'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      // Taper sur le widget déclenche onLockedTap
      await tester.tap(find.text('HOT'));
      expect(lockedTapped, isTrue);
    });
  });

  group('UnlockPackSheet Widget Tests', () {
    testWidgets('affiche les options Duo VIP (Annuel -70% et Hebdo), Pass 1H et Restaurer mes achats', (WidgetTester tester) async {
      final access = AccessControlProvider.instance;
      access.clearForTest();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: access,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UnlockPackSheet.show(
                      context,
                      packId: 'nhie_hot',
                      packTitle: 'Pack Hot & Piquant',
                      onUnlocked: () {},
                    );
                  },
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );

      // Clic pour ouvrir la modale
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('DÉBLOQUER PACK HOT & PIQUANT'), findsOneWidget);
      expect(find.text('PASS SOIRÉE 1H GRATUIT'), findsOneWidget);
      expect(find.text('PASS ANNUEL CLUB'), findsOneWidget);
      expect(find.text('-70%'), findsOneWidget);
      expect(find.text('PASS HEBDOMADAIRE'), findsOneWidget);
      expect(find.text('Restaurer mes achats'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);
    });

    testWidgets('affiche le statut ESSAI 1H DÉJÀ UTILISÉ quand l\'essai a déjà été consommé', (WidgetTester tester) async {
      final access = AccessControlProvider.instance;
      access.clearForTest();
      access.setPass1hForTest(
        expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
        hasUsed: true,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: access,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UnlockPackSheet.show(
                      context,
                      packId: 'nhie_hot',
                      packTitle: 'Pack Hot & Piquant',
                      onUnlocked: () {},
                    );
                  },
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('ESSAI 1H DÉJÀ UTILISÉ'), findsOneWidget);
      expect(find.text('PASS ANNUEL CLUB'), findsOneWidget);
      expect(find.text('PASS HEBDOMADAIRE'), findsOneWidget);
    });
  });
}
