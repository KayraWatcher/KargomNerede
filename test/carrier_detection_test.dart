import 'package:flutter_test/flutter_test.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/core/utils/app_utils.dart';
import 'package:kargom_nerede/src/shared/models/carrier.dart';

void main() {
  group('tracking number normalization', () {
    test('trims, removes inner whitespace and upper-cases', () {
      expect('  1234 567890 '.normalizeTrackingNumber(), '1234567890');
      expect(' hj1234 56789012 '.normalizeTrackingNumber(), 'HJ123456789012');
      expect('1234567890'.normalizeTrackingNumber(), '1234567890');
    });
  });

  group('carrier detection', () {
    test('detects a carrier when exactly one format matches', () {
      expect(AppUtils.detectCarrier('YT12345678901'), 'yurtici');
      expect(AppUtils.detectCarrier('HB123456789012'), 'hepsiburada');
      expect(AppUtils.detectCarrier('1ZABCDEFGH12345678'), 'ups');
      expect(AppUtils.detectCarrier('HJ123456789012'), 'hepsijet');
    });

    test('does not guess between carriers sharing the same digit format', () {
      // Plain digit numbers match several carriers at once:
      //   13 digits -> yurtici + aras + ptt + fedex
      //   10 digits -> mng + aras + surat + dhl
      // The format alone cannot say who the sender is, so these must come
      // back as null (backend/provider detection or manual choice follows).
      expect(AppUtils.detectCarrier('1234567890123'), isNull);
      expect(AppUtils.detectCarrier('1234567890'), isNull);
      expect(AppUtils.detectCarrier('6441915431716'), isNull);
    });

    test('detects HepsiJet', () {
      expect(AppUtils.detectCarrier('HJ123456789012'), 'hepsijet');
      expect(AppUtils.detectCarrier('hj123456789012'), 'hepsijet');
      expect(AppUtils.detectCarrier('HEPSIJET12345678'), 'hepsijet');
    });

    test('does not guess when the number is unknown', () {
      expect(AppUtils.detectCarrier('AB1234'), isNull);
      expect(AppUtils.detectCarrier(''), isNull);
      expect(AppUtils.detectCarrier('12'), isNull);
      expect(AppUtils.detectCarrier('   '), isNull);
    });

    test('normalizes before matching', () {
      expect(AppUtils.detectCarrier('  yt12345678901 '), 'yurtici');
    });

    test('every detection code maps to a registered carrier', () {
      for (final code in AppConstants.carrierPatterns.keys) {
        expect(
          CarrierRegistry.byCode(code),
          isNotNull,
          reason: "detection code '$code' has no registered carrier",
        );
      }
    });
  });

  group('carrier registry', () {
    test('contains HepsiJet', () {
      final hepisiJet = CarrierRegistry.byCode('hepsijet');
      expect(hepisiJet, isNotNull);
      expect(hepisiJet!.name, 'HepsiJet');
    });

    test('has no placeholder carrier such as Diğer / Other / Unknown', () {
      final names = CarrierRegistry.carriers
          .map((c) => c.name.toLowerCase())
          .toList(growable: false);
      final codes = CarrierRegistry.carriers
          .map((c) => c.code.toLowerCase())
          .toList(growable: false);

      for (final placeholder in ['diğer', 'listede yok', 'other', 'unknown']) {
        expect(names, isNot(contains(placeholder)));
        expect(codes, isNot(contains(placeholder)));
      }
    });
  });
}
