import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asset_sum/main.dart';

void main() {
  testWidgets('App renders with bottom navigation', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AssetSumApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Assets'), findsWidgets);
  });
}
