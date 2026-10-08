import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_news/widgets/formatted_summary_view.dart';

void main() {
  group('FormattedSummaryView Verification', () {
    testWidgets('Renders full text when space is sufficient', (tester) async {
      bool readMoreCalled = false;
      const testSummary = 'NTPC Renewable Energy invites bids for 2,000 MW pumped storage project to supply clean peaking power to the grid.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 250,
              child: FormattedSummaryView(
                summary: testSummary,
                isDark: false,
                fontSize: 16.0,
                onReadMore: () {
                  readMoreCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('pumped storage project'), findsOneWidget);
      // Because it fits in 250dp, no read button is needed
      expect(find.text('... Read full story'), findsNothing);
      expect(readMoreCalled, isFalse);
    });

    testWidgets('Shows ellipsis and Read button when text cannot be accommodated', (tester) async {
      bool readMoreCalled = false;
      const longSummary =
          'NTPC Renewable Energy Limited (NTPC REL) has issued a global competitive bidding tender for the procurement '
          'of 2,000 MW / 12,000 MWh of Inter-State Transmission System connected Pumped Hydro Energy Storage capacity '
          'under an Energy Storage as a Service model for a period of 25 years on an annual fixed-charge basis. '
          'The project requires developers to establish minimum 500 MW single-location discharge capacity over 6 hours '
          'with completion mandated within 48 months to support peak grid reliability and renewable dispatch.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 60, // Constrained container that cannot accommodate full 60-word brief
              child: FormattedSummaryView(
                summary: longSummary,
                isDark: false,
                fontSize: 16.0,
                onReadMore: () {
                  readMoreCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Should show the read button thereafter
      expect(find.text('... Read full story'), findsOneWidget);

      await tester.tap(find.text('... Read full story'));
      await tester.pumpAndSettle();
      expect(readMoreCalled, isTrue);
    });
  });
}
