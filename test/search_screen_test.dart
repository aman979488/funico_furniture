import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/features/search/views/search_screen.dart';

void main() {
  testWidgets('searching for sofa shows every sofa product', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'sofa');
    await tester.pumpAndSettle();

    expect(find.text('9 products found'), findsOneWidget);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final childCount =
        (grid.childrenDelegate as SliverChildBuilderDelegate).childCount;
    expect(childCount, 9);
  });
}
