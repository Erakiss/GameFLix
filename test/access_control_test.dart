// test/access_control_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gameflix/state/access_control_provider.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';

void main() {
  group('AccessControlProvider Unit Tests', () {
    final access = AccessControlProvider.instance;

    setUp(() {
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
    testWidgets('affiche les deux options de déblocage (Pub 1 partie et Pass VIP)', (WidgetTester tester) async {
      final access = AccessControlProvider.instance;

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
      expect(find.text('DÉBLOQUER 1 PARTIE'), findsOneWidget);
      expect(find.text('PASS VIP ILLIMITÉ'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);
    });
  });
}
