import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PokeCenter/screens/healing_machine_screen.dart';

void main() {
  Future<void> mount(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HealingMachineScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> place(WidgetTester tester, int id, int slot) async {
    final source = find.byKey(ValueKey('healing-pokemon-$id'));
    final target = find.byKey(ValueKey('healing-slot-$slot'));
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Drag, reject occupied slot, heal in steps and remove healed balls',
    (tester) async {
      await mount(tester, const Size(390, 844));
      final button = find.byKey(const Key('healing-machine-button'));
      expect(tester.widget<IconButton>(button).onPressed, isNull);
      await place(tester, 1, 0);
      expect(find.byKey(const ValueKey('healing-pokemon-1')), findsNothing);
      await place(tester, 2, 0);
      expect(find.byKey(const ValueKey('healing-pokemon-2')), findsOneWidget);
      await place(tester, 2, 1);
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<IconButton>(button).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('healing-slot-0')));
      expect(find.byKey(const ValueKey('healing-pokemon-1')), findsNothing);
      for (final progress in [25, 50, 75, 100]) {
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('$progress%'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byKey(const Key('healing-progress-bar')),
              )
              .value,
          progress / 100,
        );
      }
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byKey(const ValueKey('healing-pokemon-1')), findsNothing);
      expect(find.byKey(const ValueKey('healing-pokemon-2')), findsNothing);
      expect(tester.widget<IconButton>(button).onPressed, isNull);
      for (var slot = 0; slot < 6; slot++) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('healing-slot-$slot')),
            matching: find.byType(CustomPaint),
          ),
          findsNothing,
        );
      }
      await place(tester, 3, 0);
      expect(find.text('0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 568), const Size(768, 1024)]) {
    testWidgets('Layout, scrolling and disposal at $size', (tester) async {
      await mount(tester, size);
      await place(tester, 1, 0);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('healing-pokemon-36')),
        150,
        scrollable: find.descendant(
          of: find.byKey(const Key('healing-pokemon-grid')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('healing-pokemon-36')), findsOneWidget);
      await tester.tap(find.byKey(const Key('healing-machine-button')));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });
  }
}
