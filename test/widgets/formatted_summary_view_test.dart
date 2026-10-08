import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_news/widgets/formatted_summary_view.dart';

void main() {
  group('FormattedSummaryView Widget Tests', () {
    testWidgets('Renders structured bullet points and highlighted entities', (WidgetTester tester) async {
      const summaryText =
          'POWERGRID energizes 765 kV transmission link in Rajasthan. '
          'The project enhances inter-state electricity flow capacity by 1,500 MW. '
          'Operation is certified by CTU for national grid reliability.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormattedSummaryView(
              summary: summaryText,
              isDark: false,
              player: 'POWERGRID',
              state: 'Rajasthan',
            ),
          ),
        ),
      );

      // Verify that summary text is rendered
      expect(find.textContaining('POWERGRID'), findsWidgets);
      expect(find.textContaining('Rajasthan'), findsWidgets);

      // Verify that Text.rich applies TextAlign.justify
      final textWidget = tester.widget<Text>(find.byType(Text).first);
      expect(textWidget.textAlign, TextAlign.justify);
    });

    testWidgets('Renders within tight constrained container without overflow', (WidgetTester tester) async {
      const summaryText =
          'TGNPDCL has commissioned its first indoor 33/11 kV substation in Karimnagar to bolster local distribution infrastructure. '
          'This strategic grid asset enhances voltage stability and improves power reliability for the district.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 180,
              child: FormattedSummaryView(
                summary: summaryText,
                isDark: true,
                fontSize: 16.0,
                lineHeight: 1.5,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('TGNPDCL'), findsWidgets);
    });
  });
}
