import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/features/shipments/presentation/providers/shipment_providers.dart';
import 'package:kargom_nerede/src/features/shipments/presentation/screens/add_shipment_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Finder trackingField() => find.byType(TextFormField).first;
  Finder trackingTextField() => find.byType(TextField).first;

  Future<void> pumpAddScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('home'))),
        ),
        GoRoute(
          path: '/add',
          builder: (context, state) => const AddShipmentScreen(),
        ),
        GoRoute(
          path: '/detail/:id',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('detail:${state.pathParameters['id']}'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
    router.push('/add');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Waits for the debounce (400ms) plus the local lookups to finish.
  Future<void> settleDetection(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 500));
  }

  FocusNode trackingFocusNode(WidgetTester tester) =>
      tester.widget<TextField>(trackingTextField()).focusNode!;

  String trackingText(WidgetTester tester) =>
      tester.widget<TextFormField>(trackingField()).controller!.text;

  /// Scrolls the form to the bottom so the save/open button (which sits
  /// below the fold) is built and visible.
  Future<void> scrollFormToEnd(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();
  }

  /// Reads the repository through real async. Kept for the very end of a
  /// test: mixing `runAsync` with the fake clock in the middle of a test
  /// leaves pending widget futures unresolved.
  Future<List<String>> storedTrackingNumbers(WidgetTester tester) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    final repository = container.read(mockShipmentRepositoryProvider);
    final shipments = await tester.runAsync(
      () async => (await repository.getAllShipments()).toList(),
    );
    return shipments?.map((s) => s.trackingNumber.normalizeTrackingNumber()).toList() ??
        const [];
  }

  testWidgets('tracking field keeps focus while carrier detection runs',
      (tester) async {
    await pumpAddScreen(tester);

    // 5, 13 and 15 characters: focus, keyboard and the typed value must
    // survive every rebuild caused by carrier detection. All three resolve
    // locally (no match / unique formats) so no network call is involved.
    for (final value in ['12345', 'AR12345678901', '123456789012345']) {
      await tester.enterText(trackingField(), value);
      expect(trackingFocusNode(tester).hasFocus, isTrue,
          reason: 'field was not focused after typing "$value"');

      await settleDetection(tester);

      expect(trackingFocusNode(tester).hasFocus, isTrue,
          reason: 'keyboard/focus lost after typing "$value"');
      expect(trackingText(tester), value,
          reason: 'typed value was reset after typing "$value"');
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'detection must not leave a spinner behind');
    }

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('shows the previously tracked record instead of a new form',
      (tester) async {
    await pumpAddScreen(tester);

    await tester.enterText(trackingField(), '1234567890123');
    await settleDetection(tester);

    expect(find.text('Bu kargo daha önce takip edilmiş.'), findsOneWidget);
    expect(find.text('Yurtiçi Kargo'), findsOneWidget);
    expect(find.text('Önceki kayıttan alındı'), findsOneWidget);
    expect(find.text('✓ Otomatik algılandı'), findsNothing);

    await scrollFormToEnd(tester);
    expect(find.text('Mevcut Kargoyu Aç'), findsOneWidget);
    expect(find.text('Detayı Aç'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('finds a previously delivered shipment with its status',
      (tester) async {
    await pumpAddScreen(tester);

    await tester.enterText(trackingField(), '9876543210');
    await settleDetection(tester);

    expect(find.text('Bu kargo daha önce takip edilmiş.'), findsOneWidget);
    expect(find.text('Teslim Edildi'), findsOneWidget);
    expect(find.text('Geçmiş kaydınız korunuyor, tekrar eklemeniz gerekmez.'),
        findsOneWidget);

    await scrollFormToEnd(tester);
    expect(find.text('Mevcut Kargoyu Aç'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('detects HepsiJet automatically', (tester) async {
    await pumpAddScreen(tester);

    await tester.enterText(trackingField(), 'HJ123456789012');
    await settleDetection(tester);

    expect(find.text('HepsiJet'), findsOneWidget);
    expect(find.text('✓ Otomatik algılandı'), findsOneWidget);
    expect(find.text('Kargo firması algılanamadı'), findsNothing);
    expect(find.text('Bu kargo daha önce takip edilmiş.'), findsNothing);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets(
      'unknown number shows "Kargo firması algılanamadı" with the real list, '
      'without Diğer / Listede yok and without a random carrier', (tester) async {
    await pumpAddScreen(tester);

    await tester.enterText(trackingField(), 'AB1234');
    await settleDetection(tester);

    expect(find.text('Kargo firması algılanamadı'), findsOneWidget);
    expect(find.text('Diğer / Listede yok'), findsNothing);
    expect(find.textContaining('Listede yok'), findsNothing);
    expect(find.text('✓ Otomatik algılandı'), findsNothing);
    expect(find.text('Bu kargo daha önce takip edilmiş.'), findsNothing);

    // The real carrier list (incl. HepsiJet) is offered for a manual pick.
    expect(find.text('HepsiJet'), findsOneWidget);
    expect(find.text('Yurtiçi Kargo'), findsOneWidget);

    await scrollFormToEnd(tester);
    expect(find.text('Kargoyu Ekle'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('does not create a second shipment for an existing number',
      (tester) async {
    await pumpAddScreen(tester);

    await tester.enterText(trackingField(), '9876543210');
    await settleDetection(tester);

    expect(find.text('Teslim Edildi'), findsOneWidget);

    final openButton = find.widgetWithText(OutlinedButton, 'Detayı Aç');
    await tester.ensureVisible(openButton);
    await tester.pump();
    await tester.tap(openButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('detail:shipment_2'), findsOneWidget);
    expect(find.byType(AddShipmentScreen), findsNothing,
        reason: 'the duplicate form must be replaced, not kept');

    await tester.pump(const Duration(seconds: 6));

    final stored = await storedTrackingNumbers(tester);
    expect(stored.where((t) => t == '9876543210'), hasLength(1),
        reason: 'duplicate shipment must not be created');
    expect(stored, hasLength(2),
        reason: 'only the two demo records may exist, nothing may be added');
  });

  testWidgets('auto detects an unambiguous carrier without asking the backend',
      (tester) async {
    await pumpAddScreen(tester);

    // AR + 11 digits matches only Aras, so the app resolves it locally.
    await tester.enterText(trackingField(), 'AR12345678901');
    await settleDetection(tester);

    expect(find.text('Aras Kargo'), findsOneWidget);
    expect(find.text('✓ Otomatik algılandı'), findsOneWidget);
    expect(find.text('Bu kargo daha önce takip edilmiş.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await scrollFormToEnd(tester);
    expect(find.text('Kargoyu Ekle'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets(
      'adding without a known carrier asks the user to pick one and saves '
      'nothing', (tester) async {
    await pumpAddScreen(tester);

    await tester.enterText(trackingField(), 'AB1234');
    await settleDetection(tester);

    await scrollFormToEnd(tester);
    final addButton = find.widgetWithText(ElevatedButton, 'Kargoyu Ekle');
    await tester.ensureVisible(addButton);
    await tester.pump();
    await tester.tap(addButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    // No carrier is guessed: the picker opens with a clear message.
    expect(find.text('Kargo firması algılanamadı, lütfen firma seçin'),
        findsOneWidget);
    expect(find.byType(AddShipmentScreen), findsOneWidget,
        reason: 'the screen must stay open until a carrier is chosen');
    expect(find.text('HepsiJet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6)); // flush snackbar timer

    final stored = await storedTrackingNumbers(tester);
    expect(stored, hasLength(2),
        reason: 'nothing may be stored before a real tracking result exists');
  });
}
