// Kept on purpose: `flutter create .` would otherwise generate a default
// widget test that doesn't match this app. The real tests are in
// surprise_engine_test.dart.
import 'package:dawnbox/surprise/surprise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every surprise type has a label', () {
    for (final t in SurpriseType.values) {
      expect(t.label, isNotEmpty);
    }
  });
}
