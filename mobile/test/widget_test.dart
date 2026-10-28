import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/main.dart';

void main() {
  testWidgets('App smoke loads login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MsUpperLimbsApp()));
    await tester.pump();
    expect(find.text('MS Upper Limbs'), findsOneWidget);
  });
}
