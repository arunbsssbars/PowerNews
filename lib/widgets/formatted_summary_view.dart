import 'package:flutter/material.dart';
import '../models/news_article.dart';

class FormattedSummaryView extends StatelessWidget {
  final String summary;
  final bool isDark;
  final String? player;
  final String? city;
  final String? state;
  final String? title;
  final double fontSize;
  final String? fontFamily;
  final double lineHeight;
  final bool isScrollable;
  final VoidCallback? onReadMore;

  const FormattedSummaryView({
    super.key,
    required this.summary,
    required this.isDark,
    this.player,
    this.city,
    this.state,
    this.title,
    this.fontSize = 16.5,
    this.fontFamily,
    this.lineHeight = 1.54,
    this.isScrollable = false,
    this.onReadMore,
  });

  // Highlights quantitative power sector metrics (MW, GW, kV, Capex, Tariffs, etc.)
  static final RegExp _metricRegex = RegExp(
    r'(\b(?:Rs\.?|₹)\s*[\d,]+(?:\.\d+)?(?:\s*(?:crore|cr|lakh|billion|million|kwh|unit|per\s+unit))?\b|\b[\d,]+(?:\.\d+)?\s*(?:MW|GW|kW|kV|MU|BUs|GWh|MWh|TWh|km)\b|\b\d+(?:\.\d+)?%\b|\b\d+\s*-(?:year|month|day)\b|\b\d+\s*(?:years|months|days)\b)',
    caseSensitive: false,
  );

  List<TextSpan> _buildHighlightedSpans(String text, TextStyle baseStyle, TextStyle highlightStyle) {
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in _metricRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start), style: baseStyle));
      }
      spans.add(TextSpan(text: match.group(0), style: highlightStyle));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    return spans;
  }

  double _calculateFittingFontSize({
    required String text,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
    required double preferredFontSize,
    required double minFontSize,
    required double maxFontSize,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (!maxHeight.isFinite || maxHeight <= 0 || maxWidth <= 0) return preferredFontSize;
    final bufferMaxHeight = maxHeight - 2.0; // Minimal buffer for edge safety

    // Scan downward from maxFontSize to minFontSize in 0.5 decrements
    // to discover the largest legible font size that snugly fits within container height
    for (double size = maxFontSize; size >= minFontSize; size -= 0.5) {
      final curBase = baseStyle.copyWith(fontSize: size);
      final curHighlight = highlightStyle.copyWith(fontSize: size);
      final spans = _buildHighlightedSpans(text, curBase, curHighlight);

      final painter = TextPainter(
        text: TextSpan(children: spans),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.justify,
      )..layout(maxWidth: maxWidth);

      if (painter.size.height <= bufferMaxHeight) {
        return size;
      }
    }
    return minFontSize;
  }

  @override
  Widget build(BuildContext context) {
    final cleanSummary = NewsArticle.cleanHtmlAndEntities(summary);
    final normSummary = cleanSummary.trim().toLowerCase();
    final normTitle = (title ?? '').trim().toLowerCase();
    final isHeadlineDuplicate = normSummary.isEmpty ||
        (normTitle.isNotEmpty &&
            (normSummary == normTitle ||
                normSummary.startsWith(normTitle) && (normSummary.length - normTitle.length < 50) ||
                normTitle.startsWith(normSummary))) ||
        cleanSummary.length < 45;

    final textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1E293B);
    final highlightColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1D4ED8);

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      height: lineHeight,
      fontWeight: FontWeight.w400,
      color: textColor,
      letterSpacing: 0.1,
    );
    final highlightStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: highlightColor,
    );

    if (cleanSummary.isEmpty || isHeadlineDuplicate) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF22324C) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Text(
                  'EXECUTIVE INTELLIGENCE IN PROCESS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A structured 50-word power sector intelligence brief is being generated for this update. Read the full live dispatch directly via the publisher button above.',
              style: baseStyle.copyWith(
                fontSize: 13,
                height: 1.45,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      );
    }

    // Check if the summary is explicitly formatted as multiple lines/bullets
    final rawLines = cleanSummary
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final bool hasExplicitBullets = rawLines.length > 1 &&
        rawLines.any((l) => RegExp(r'^(?:📌|⚡|🏢|🔹|🔸|•|\*|-|\d+[\.\)])\s*').hasMatch(l));

    if (hasExplicitBullets) {
      // Multi-Beat Bullet Presentation
      final points = rawLines.map((l) {
        return l
            .replaceFirst(RegExp(r'^(📌|⚡|🏢|🔹|🔸|•|\*|-|\d+[\.\)])\s*'), '')
            .replaceFirst(RegExp(r'^(Key Action|Metrics & Scope|Grid & Utility Impact|Action|Metrics|Scope|Impact|Overview|Key Focus|Operating Entity|Geographic Impact):\s*', caseSensitive: false), '')
            .replaceAll(RegExp(r'[•●▪▫]\s*'), '')
            .replaceAll(RegExp(r'\.{2,}'), '.')
            .replaceAll(RegExp(r'\s*\.\s*\.'), '.')
            .trim();
      }).where((l) => l.length > 5).toList();

      return LayoutBuilder(
        builder: (context, constraints) {
          final double maxAllowedFontSize = (fontSize + 1.5).clamp(15.0, 18.0);
          final double effectiveFontSize = _calculateFittingFontSize(
            text: points.join(' '),
            baseStyle: baseStyle,
            highlightStyle: highlightStyle,
            preferredFontSize: fontSize,
            minFontSize: 11.0,
            maxFontSize: maxAllowedFontSize,
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          );

          final effectiveBaseStyle = baseStyle.copyWith(fontSize: effectiveFontSize);
          final effectiveHighlightStyle = effectiveBaseStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: highlightColor,
          );

          final bulletsWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: points.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: effectiveFontSize * 0.45, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: _buildHighlightedSpans(point, effectiveBaseStyle, effectiveHighlightStyle),
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );

          if (isScrollable) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: bulletsWidget,
            );
          }

          return SizedBox(
            width: double.infinity,
            child: bulletsWidget,
          );
        },
      );
    }

    // Single Paragraph Continuous Executive Narrative Prose (50–100 Words Story)
    final cleanProse = cleanSummary
        .replaceAll(RegExp(r'[•●▪▫]\s*'), '')
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .replaceAll(RegExp(r'\s*\.\s*\.'), '.')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxAllowedFontSize = (fontSize + 2.0).clamp(16.0, 18.5);
        final double effectiveFontSize = _calculateFittingFontSize(
          text: cleanProse,
          baseStyle: baseStyle,
          highlightStyle: highlightStyle,
          preferredFontSize: fontSize,
          minFontSize: 11.5,
          maxFontSize: maxAllowedFontSize,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );

        final effectiveBaseStyle = baseStyle.copyWith(fontSize: effectiveFontSize);
        final effectiveHighlightStyle = effectiveBaseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: highlightColor,
        );

        final textPainter = TextPainter(
          text: TextSpan(
            children: _buildHighlightedSpans(cleanProse, effectiveBaseStyle, effectiveHighlightStyle),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.justify,
        )..layout(maxWidth: constraints.maxWidth);

        final bool fitsCompletely = textPainter.size.height <= (constraints.maxHeight + 1.0);

        final proseWidget = SizedBox(
          width: double.infinity,
          child: Text.rich(
            TextSpan(
              children: _buildHighlightedSpans(cleanProse, effectiveBaseStyle, effectiveHighlightStyle),
            ),
            textAlign: TextAlign.justify,
          ),
        );

        if (isScrollable) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: proseWidget,
          );
        }

        if (fitsCompletely) {
          return SizedBox(
            width: double.infinity,
            child: proseWidget,
          );
        }

        // If summary is not completely accommodated on summary card:
        // Show ... dots and read button thereafter as requested
        final double reservedActionHeight = onReadMore != null ? 36.0 : 0.0;
        final double availableTextHeight = (constraints.maxHeight - reservedActionHeight - 4.0).clamp(20.0, constraints.maxHeight);
        final double singleLineHeight = effectiveFontSize * lineHeight;
        final int computedMaxLines = (availableTextHeight / singleLineHeight).floor().clamp(2, 20);
        final int actualLines = textPainter.computeLineMetrics().length;
        // Never allocate more lines than the actual text lines to prevent empty trailing line
        final int maxLines = actualLines > 0 ? computedMaxLines.clamp(1, actualLines) : computedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: _buildHighlightedSpans(cleanProse, effectiveBaseStyle, effectiveHighlightStyle),
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.justify,
              ),
            ),
            if (onReadMore != null) ...[
              const SizedBox(height: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onReadMore,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '... Read full story',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
