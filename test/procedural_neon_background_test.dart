// test/procedural_neon_background_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameflix/shared/widgets/procedural_neon_background.dart';

void main() {
  group('ProceduralNeonBackground Tests', () {
    testWidgets('affiche l\'arrière-plan procédural et son enfant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProceduralNeonBackground(
              child: Text('Contenu du Hub'),
            ),
          ),
        ),
      );

      expect(find.byType(ProceduralNeonBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Contenu du Hub'), findsOneWidget);
    });

    testWidgets('s\'adapte aux dimensions de l\'écran sans déborder ni lancer d\'exception', (WidgetTester tester) async {
      // Test avec format mobile standard
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProceduralNeonBackground(
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ProceduralNeonBackground), findsOneWidget);
    });
  });
}
