import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('======================================================');
  print('Generating 5 Google Play Store Marketing Screenshots');
  print('Target resolution: 1080 x 2400 px (9:20 Portrait)');
  print('Output directory: builds/playstore/screenshots/');
  print('======================================================');

  final outDir = Directory('builds/playstore/screenshots');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // Load app emblem icon for compositing inside phone mockup
  final iconFile = File('assets/icons/app_icon.png');
  final img.Image? brandIcon = iconFile.existsSync()
      ? img.decodePng(iconFile.readAsBytesSync())
      : null;

  final screenshots = [
    _ScreenshotSpec(
      filename: 'screenshot_1_home_intelligence.png',
      tag: 'REAL-TIME SECTOR FEED',
      tagColor: img.ColorRgb8(16, 185, 129), // Emerald
      headline: 'POWER & ENERGY INTELLIGENCE',
      subtitle: 'Real-time updates across Thermal, Solar, Wind & Grid networks',
      screenType: _ScreenType.homeFeed,
    ),
    _ScreenshotSpec(
      filename: 'screenshot_2_ai_briefings.png',
      tag: '60-WORD EXECUTIVE SUMMARIES',
      tagColor: img.ColorRgb8(59, 130, 246), // Blue
      headline: 'AI-CURATED BRIEFINGS',
      subtitle: 'Zero fluff. Key takeaways, impact metrics & source links',
      screenType: _ScreenType.articleDetail,
    ),
    _ScreenshotSpec(
      filename: 'screenshot_3_state_utilities.png',
      tag: 'STATE UTILITIES DIRECTORY',
      tagColor: img.ColorRgb8(245, 158, 11), // Amber
      headline: 'STATE DISCOMS & TARIFFS',
      subtitle: 'Instant tracking for regional utilities, CERC & state grids',
      screenType: _ScreenType.stateUtilities,
    ),
    _ScreenshotSpec(
      filename: 'screenshot_4_audio_digest.png',
      tag: 'AI AUDIO PODCAST',
      tagColor: img.ColorRgb8(139, 92, 246), // Purple
      headline: 'AUDIO BRIEFINGS ON THE GO',
      subtitle: 'Listen to curated energy digests during your morning commute',
      screenType: _ScreenType.audioDigest,
    ),
    _ScreenshotSpec(
      filename: 'screenshot_5_executive_profile.png',
      tag: 'EXECUTIVE PROFILE & OFFLINE',
      tagColor: img.ColorRgb8(2, 132, 199), // Cyan
      headline: 'OFFLINE ACCESS & PREFERENCES',
      subtitle: 'High-contrast dark mode, zero-latency caching & personal stats',
      screenType: _ScreenType.profileView,
    ),
  ];

  for (int i = 0; i < screenshots.length; i++) {
    final spec = screenshots[i];
    print('Generating [${i + 1}/5] ${spec.filename}...');
    final canvas = _renderScreenshot(spec, brandIcon);
    final outFile = File('builds/playstore/screenshots/${spec.filename}');
    outFile.writeAsBytesSync(img.encodePng(canvas));
    final kb = (outFile.lengthSync() / 1024).toStringAsFixed(1);
    print('  -> Saved ${outFile.path} ($kb KB)');
  }

  print('\nAll 5 Google Play Store screenshots generated successfully in builds/playstore/screenshots/!');
}

enum _ScreenType {
  homeFeed,
  articleDetail,
  stateUtilities,
  audioDigest,
  profileView,
}

class _ScreenshotSpec {
  final String filename;
  final String tag;
  final img.ColorRgb8 tagColor;
  final String headline;
  final String subtitle;
  final _ScreenType screenType;

  _ScreenshotSpec({
    required this.filename,
    required this.tag,
    required this.tagColor,
    required this.headline,
    required this.subtitle,
    required this.screenType,
  });
}

img.Image _renderScreenshot(_ScreenshotSpec spec, img.Image? brandIcon) {
  const width = 1080;
  const height = 2400;

  final canvas = img.Image(width: width, height: height, numChannels: 3);

  // 1. Draw premium background gradient: Top deep sapphire (#0B132B) -> Mid slate (#172554) -> Bottom dark navy (#0B0F19)
  for (int y = 0; y < height; y++) {
    final t = y / height.toDouble();
    int r, g, b;
    if (t < 0.5) {
      final t1 = t / 0.5;
      r = (11 + (23 - 11) * t1).round();
      g = (19 + (37 - 19) * t1).round();
      b = (43 + (84 - 43) * t1).round();
    } else {
      final t2 = (t - 0.5) / 0.5;
      r = (23 + (11 - 23) * t2).round();
      g = (37 + (15 - 37) * t2).round();
      b = (84 + (25 - 84) * t2).round();
    }
    final rowColor = img.ColorRgb8(r, g, b);
    for (int x = 0; x < width; x++) {
      canvas.setPixel(x, y, rowColor);
    }
  }

  // 2. Draw Top Value Proposition Banner
  // A. Tag Pill at top (Y = 120)
  _drawPill(
    canvas,
    centerX: width ~/ 2,
    topY: 120,
    text: spec.tag,
    bgColor: spec.tagColor,
    textColor: img.ColorRgb8(255, 255, 255),
  );

  // B. Major Headline (Y = 220)
  _drawCenteredString(
    canvas,
    font: img.arial48,
    y: 220,
    text: spec.headline,
    color: img.ColorRgb8(255, 255, 255),
  );

  // C. Subtitle (Y = 300)
  _drawCenteredString(
    canvas,
    font: img.arial24,
    y: 300,
    text: spec.subtitle,
    color: img.ColorRgb8(148, 163, 184), // Slate-400
  );

  // 3. Draw Realistic Smartphone Frame (Bezel + Screen)
  const phoneLeft = 100;
  const phoneTop = 420;
  const phoneWidth = 880;
  const phoneHeight = 1940;
  const bezel = 18;

  // Phone Outer Bezel (Sleek dark titanium border with metallic sheen)
  _fillRoundedRect(
    canvas,
    x: phoneLeft,
    y: phoneTop,
    w: phoneWidth,
    h: phoneHeight,
    radius: 64,
    color: img.ColorRgb8(30, 41, 59), // Slate 800
  );
  _fillRoundedRect(
    canvas,
    x: phoneLeft + 4,
    y: phoneTop + 4,
    w: phoneWidth - 8,
    h: phoneHeight - 8,
    radius: 60,
    color: img.ColorRgb8(15, 23, 42), // Slate 900
  );

  // Inner Phone Screen Canvas (Width 844, Height 1904)
  const screenLeft = phoneLeft + bezel;
  const screenTop = phoneTop + bezel;
  const screenWidth = phoneWidth - (bezel * 2);
  const screenHeight = phoneHeight - (bezel * 2);

  // Screen background: Executive dark theme (#0B1120)
  _fillRoundedRect(
    canvas,
    x: screenLeft,
    y: screenTop,
    w: screenWidth,
    h: screenHeight,
    radius: 46,
    color: img.ColorRgb8(11, 17, 32),
  );

  // Dynamic Island / Speaker Pill at Top of Screen
  _fillRoundedRect(
    canvas,
    x: screenLeft + (screenWidth ~/ 2) - 90,
    y: screenTop + 14,
    w: 180,
    h: 32,
    radius: 16,
    color: img.ColorRgb8(0, 0, 0),
  );

  // Status Bar Time & Indicators
  img.drawString(
    canvas,
    '09:41',
    font: img.arial14,
    x: screenLeft + 48,
    y: screenTop + 20,
    color: img.ColorRgb8(241, 245, 249),
  );
  img.drawString(
    canvas,
    '5G  100%',
    font: img.arial14,
    x: screenLeft + screenWidth - 110,
    y: screenTop + 20,
    color: img.ColorRgb8(241, 245, 249),
  );

  // Render App Top Bar (Logo, App Title "PowerNews", Actions)
  _renderAppHeader(canvas, screenLeft, screenTop + 65, screenWidth, brandIcon);

  // Render Screen Content based on Spec
  final contentTop = screenTop + 155;
  final contentHeight = screenHeight - 240;

  switch (spec.screenType) {
    case _ScreenType.homeFeed:
      _renderHomeFeedUI(canvas, screenLeft, contentTop, screenWidth, contentHeight, brandIcon);
      break;
    case _ScreenType.articleDetail:
      _renderArticleDetailUI(canvas, screenLeft, contentTop, screenWidth, contentHeight);
      break;
    case _ScreenType.stateUtilities:
      _renderStateUtilitiesUI(canvas, screenLeft, contentTop, screenWidth, contentHeight);
      break;
    case _ScreenType.audioDigest:
      _renderAudioDigestUI(canvas, screenLeft, contentTop, screenWidth, contentHeight, brandIcon);
      break;
    case _ScreenType.profileView:
      _renderProfileViewUI(canvas, screenLeft, contentTop, screenWidth, contentHeight);
      break;
  }

  // Bottom Navigation Bar
  _renderBottomNav(canvas, screenLeft, screenTop + screenHeight - 90, screenWidth, spec.screenType);

  return canvas;
}

// -----------------------------------------------------------------------------
// UI SCREEN MOCKUPS
// -----------------------------------------------------------------------------

void _renderAppHeader(img.Image canvas, int x, int y, int w, img.Image? brandIcon) {
  // App Header Bar background
  img.fillRect(canvas, x1: x, y1: y, x2: x + w, y2: y + 65, color: img.ColorRgb8(15, 23, 42));

  // Brand Icon Emblem
  if (brandIcon != null) {
    final iconSmall = img.copyResize(brandIcon, width: 44, height: 44);
    img.compositeImage(canvas, iconSmall, dstX: x + 24, dstY: y + 10);
  }

  // App Title
  img.drawString(
    canvas,
    'PowerNews',
    font: img.arial24,
    x: x + 78,
    y: y + 12,
    color: img.ColorRgb8(255, 255, 255),
  );
  img.drawString(
    canvas,
    'ENERGY INTELLIGENCE',
    font: img.arial14,
    x: x + 80,
    y: y + 40,
    color: img.ColorRgb8(56, 189, 248), // Sky-400
  );

  // Search & Notification icons (draw stylized squares/icons)
  _fillRoundedRect(canvas, x: x + w - 100, y: y + 16, w: 34, h: 34, radius: 8, color: img.ColorRgb8(30, 41, 59));
  img.drawString(canvas, 'Q', font: img.arial14, x: x + w - 89, y: y + 25, color: img.ColorRgb8(148, 163, 184));

  _fillRoundedRect(canvas, x: x + w - 54, y: y + 16, w: 34, h: 34, radius: 8, color: img.ColorRgb8(30, 41, 59));
  img.drawString(canvas, '!', font: img.arial14, x: x + w - 43, y: y + 25, color: img.ColorRgb8(16, 185, 129));
}

void _renderHomeFeedUI(img.Image canvas, int x, int y, int w, int h, img.Image? brandIcon) {
  // Sector Pills row
  final sectors = ['All', 'Renewables', 'Transmission', 'Thermal', 'Nuclear'];
  int curX = x + 24;
  for (int i = 0; i < sectors.length; i++) {
    final isSelected = i == 0;
    final pillW = sectors[i].length * 13 + 30;
    _fillRoundedRect(
      canvas,
      x: curX,
      y: y + 10,
      w: pillW,
      h: 36,
      radius: 12,
      color: isSelected ? img.ColorRgb8(37, 99, 235) : img.ColorRgb8(30, 41, 59),
    );
    img.drawString(
      canvas,
      sectors[i],
      font: img.arial14,
      x: curX + 15,
      y: y + 20,
      color: isSelected ? img.ColorRgb8(255, 255, 255) : img.ColorRgb8(148, 163, 184),
    );
    curX += pillW + 12;
  }

  // Hero Breaking News Card
  final cardY = y + 65;
  _fillRoundedRect(canvas, x: x + 20, y: cardY, w: w - 40, h: 480, radius: 20, color: img.ColorRgb8(22, 27, 34));
  // Card Image Hero Banner
  _fillRoundedRect(canvas, x: x + 20, y: cardY, w: w - 40, h: 220, radius: 20, color: img.ColorRgb8(30, 58, 138)); // Cobalt image area
  // Overlay breaking badge
  _fillRoundedRect(canvas, x: x + 36, y: cardY + 16, w: 140, h: 28, radius: 6, color: img.ColorRgb8(220, 38, 38));
  img.drawString(canvas, 'BREAKING NEWS', font: img.arial14, x: x + 44, y: cardY + 22, color: img.ColorRgb8(255, 255, 255));

  // Sector Badge
  _fillRoundedRect(canvas, x: x + 36, y: cardY + 236, w: 130, h: 24, radius: 6, color: img.ColorRgb8(16, 185, 129));
  img.drawString(canvas, 'TRANSMISSION', font: img.arial14, x: x + 42, y: cardY + 241, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, '•  CEA National Grid  •  25m ago', font: img.arial14, x: x + 180, y: cardY + 241, color: img.ColorRgb8(148, 163, 184));

  // Title
  img.drawString(
    canvas,
    'National Grid Touches Record 242 GW Peak Demand',
    font: img.arial24,
    x: x + 36,
    y: cardY + 276,
    color: img.ColorRgb8(241, 245, 249),
  );

  // Summary snippet
  img.drawString(
    canvas,
    'India recorded all-time high electricity demand supported by 18% surge',
    font: img.arial14,
    x: x + 36,
    y: cardY + 325,
    color: img.ColorRgb8(148, 163, 184),
  );
  img.drawString(
    canvas,
    'in solar output and regional 765 kV inter-state transmission corridors.',
    font: img.arial14,
    x: x + 36,
    y: cardY + 348,
    color: img.ColorRgb8(148, 163, 184),
  );

  // Action chips
  _fillRoundedRect(canvas, x: x + 36, y: cardY + 395, w: 160, h: 40, radius: 10, color: img.ColorRgb8(37, 99, 235));
  img.drawString(canvas, 'Listen Audio (2m)', font: img.arial14, x: x + 50, y: cardY + 408, color: img.ColorRgb8(255, 255, 255));

  _fillRoundedRect(canvas, x: x + 210, y: cardY + 395, w: 140, h: 40, radius: 10, color: img.ColorRgb8(30, 41, 59));
  img.drawString(canvas, 'Bookmark Story', font: img.arial14, x: x + 224, y: cardY + 408, color: img.ColorRgb8(226, 232, 240));

  // Second Story Card (Feed item 2)
  final card2Y = cardY + 510;
  _fillRoundedRect(canvas, x: x + 20, y: card2Y, w: w - 40, h: 320, radius: 20, color: img.ColorRgb8(22, 27, 34));
  _fillRoundedRect(canvas, x: x + 36, y: card2Y + 20, w: 100, h: 24, radius: 6, color: img.ColorRgb8(245, 158, 11));
  img.drawString(canvas, 'SOLAR EPC', font: img.arial14, x: x + 44, y: card2Y + 25, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, '•  SECI Tender  •  1h ago', font: img.arial14, x: x + 150, y: card2Y + 25, color: img.ColorRgb8(148, 163, 184));

  img.drawString(
    canvas,
    'SECI Announces 1,200 MW Hybrid Wind-Solar Auction',
    font: img.arial24,
    x: x + 36,
    y: card2Y + 60,
    color: img.ColorRgb8(241, 245, 249),
  );
  img.drawString(
    canvas,
    'Tariff discovery expected below Rs 2.90/kWh with storage mandate.',
    font: img.arial14,
    x: x + 36,
    y: card2Y + 105,
    color: img.ColorRgb8(148, 163, 184),
  );

  // Third Story Card (Feed item 3)
  final card3Y = card2Y + 160;
  _fillRoundedRect(canvas, x: x + 20, y: card3Y, w: w - 40, h: 300, radius: 20, color: img.ColorRgb8(22, 27, 34));
  _fillRoundedRect(canvas, x: x + 36, y: card3Y + 20, w: 110, h: 24, radius: 6, color: img.ColorRgb8(59, 130, 246));
  img.drawString(canvas, 'REGULATION', font: img.arial14, x: x + 44, y: card3Y + 25, color: img.ColorRgb8(255, 255, 255));
  img.drawString(
    canvas,
    'CERC Issues Draft Open Access Connectivity Norms',
    font: img.arial24,
    x: x + 36,
    y: card3Y + 60,
    color: img.ColorRgb8(241, 245, 249),
  );
}

void _renderArticleDetailUI(img.Image canvas, int x, int y, int w, int h) {
  // Detail Container
  _fillRoundedRect(canvas, x: x + 20, y: y + 10, w: w - 40, h: h - 20, radius: 20, color: img.ColorRgb8(22, 27, 34));

  // Category Tag & Read Time
  _fillRoundedRect(canvas, x: x + 40, y: y + 36, w: 120, h: 26, radius: 6, color: img.ColorRgb8(37, 99, 235));
  img.drawString(canvas, 'CLEAN ENERGY', font: img.arial14, x: x + 48, y: y + 42, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, '60-Word Executive Brief • 1 min read', font: img.arial14, x: x + 175, y: y + 42, color: img.ColorRgb8(148, 163, 184));

  // Headline
  img.drawString(
    canvas,
    'NTPC Green Energy Commissions 300 MW',
    font: img.arial24,
    x: x + 40,
    y: y + 80,
    color: img.ColorRgb8(255, 255, 255),
  );
  img.drawString(
    canvas,
    'Solar Project in Khavda Renewable Park',
    font: img.arial24,
    x: x + 40,
    y: y + 115,
    color: img.ColorRgb8(255, 255, 255),
  );

  // Divider
  img.fillRect(canvas, x1: x + 40, y1: y + 160, x2: x + w - 40, y2: y + 162, color: img.ColorRgb8(38, 48, 64));

  // AI Summary Card Box
  _fillRoundedRect(canvas, x: x + 40, y: y + 180, w: w - 80, h: 480, radius: 16, color: img.ColorRgb8(15, 23, 42));

  // AI Badge Header
  _fillRoundedRect(canvas, x: x + 60, y: y + 200, w: 130, h: 28, radius: 6, color: img.ColorRgb8(16, 185, 129));
  img.drawString(canvas, 'AI SUMMARY', font: img.arial14, x: x + 75, y: y + 206, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'Verified against CERC filings', font: img.arial14, x: x + 210, y: y + 206, color: img.ColorRgb8(148, 163, 184));

  // Key Bullet points
  final bullets = [
    '• Project commissioned under CPSU Scheme Phase-II with domestic cells.',
    '• Expected annual generation of 650 million units of green power.',
    '• Supplies power directly to Gujarat GUVNL at levelized Rs 2.54/kWh.',
    '• Enhances NTPC total commercial renewable capacity to 3,600 MW.',
    '• Part of the larger 45 GW Khavda Hybrid Renewable Energy Park.',
  ];

  int curY = y + 250;
  for (final b in bullets) {
    img.drawString(canvas, b, font: img.arial14, x: x + 60, y: curY, color: img.ColorRgb8(226, 232, 240));
    curY += 45;
  }

  // Source attribution & verification card
  _fillRoundedRect(canvas, x: x + 40, y: y + 690, w: w - 80, h: 120, radius: 14, color: img.ColorRgb8(30, 41, 59));
  img.drawString(canvas, 'OFFICIAL SOURCE ATTRIBUTION', font: img.arial14, x: x + 60, y: y + 710, color: img.ColorRgb8(56, 189, 248));
  img.drawString(canvas, 'Source: Press Information Bureau (PIB) / Ministry of Power', font: img.arial14, x: x + 60, y: y + 740, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'Published: 10 October 2026 • Verified by PowerNews ML Engine', font: img.arial14, x: x + 60, y: y + 770, color: img.ColorRgb8(148, 163, 184));
}

void _renderStateUtilitiesUI(img.Image canvas, int x, int y, int w, int h) {
  // Title row
  img.drawString(canvas, 'National Discom & Tariff Explorer', font: img.arial24, x: x + 30, y: y + 10, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'Select state to view utility tariffs, solar policies & outages', font: img.arial14, x: x + 30, y: y + 45, color: img.ColorRgb8(148, 163, 184));

  // State Chips
  final states = ['All India', 'Gujarat', 'Maharashtra', 'Rajasthan', 'Karnataka'];
  int curX = x + 24;
  for (int i = 0; i < states.length; i++) {
    final isSelected = i == 1; // Gujarat selected
    final pillW = states[i].length * 13 + 32;
    _fillRoundedRect(
      canvas,
      x: curX,
      y: y + 80,
      w: pillW,
      h: 36,
      radius: 12,
      color: isSelected ? img.ColorRgb8(245, 158, 11) : img.ColorRgb8(30, 41, 59),
    );
    img.drawString(
      canvas,
      states[i],
      font: img.arial14,
      x: curX + 16,
      y: y + 90,
      color: isSelected ? img.ColorRgb8(255, 255, 255) : img.ColorRgb8(148, 163, 184),
    );
    curX += pillW + 10;
  }

  // Discom Cards
  final discoms = [
    {
      'name': 'GUVNL (Gujarat Urja Vikas Nigam)',
      'zone': 'State Transmission & Bulk Power',
      'tariff': 'Avg Tariff: Rs 5.85 / kWh',
      'status': 'OPERATIONAL • LOW AT&C LOSS (11.2%)',
      'color': img.ColorRgb8(16, 185, 129),
    },
    {
      'name': 'MGVCL (Madhya Gujarat Vij Company)',
      'zone': 'Central Distribution Zone',
      'tariff': 'Residential: Rs 4.10 / kWh (Base)',
      'status': 'SOLAR ROOFTOP NET METERING ACTIVE',
      'color': img.ColorRgb8(59, 130, 246),
    },
    {
      'name': 'DGVCL (Dakshin Gujarat Vij Company)',
      'zone': 'Industrial & Coastal Corridor',
      'tariff': 'Commercial HT: Rs 6.45 / kWh',
      'status': 'PEAK DEMAND: 4,850 MW STABLE',
      'color': img.ColorRgb8(245, 158, 11),
    },
    {
      'name': 'Torrent Power (Ahmedabad & Surat)',
      'zone': 'Private Urban Distribution Franchisee',
      'tariff': 'Green Energy Open Access: Rs 3.95/kWh',
      'status': '100% SMART METER COMPLIANT',
      'color': img.ColorRgb8(139, 92, 246),
    },
  ];

  int cardY = y + 140;
  for (final d in discoms) {
    _fillRoundedRect(canvas, x: x + 20, y: cardY, w: w - 40, h: 170, radius: 18, color: img.ColorRgb8(22, 27, 34));

    // Status pill
    _fillRoundedRect(canvas, x: x + 40, y: cardY + 18, w: 260, h: 22, radius: 6, color: d['color'] as img.ColorRgb8);
    img.drawString(canvas, d['status'] as String, font: img.arial14, x: x + 48, y: cardY + 22, color: img.ColorRgb8(255, 255, 255));

    img.drawString(canvas, d['name'] as String, font: img.arial24, x: x + 40, y: cardY + 52, color: img.ColorRgb8(255, 255, 255));
    img.drawString(canvas, d['zone'] as String, font: img.arial14, x: x + 40, y: cardY + 92, color: img.ColorRgb8(148, 163, 184));
    img.drawString(canvas, d['tariff'] as String, font: img.arial14, x: x + 40, y: cardY + 122, color: img.ColorRgb8(56, 189, 248));

    cardY += 190;
  }
}

void _renderAudioDigestUI(img.Image canvas, int x, int y, int w, int h, img.Image? brandIcon) {
  // Main Player Card
  _fillRoundedRect(canvas, x: x + 20, y: y + 20, w: w - 40, h: 560, radius: 24, color: img.ColorRgb8(22, 27, 34));

  // Audio Badge
  _fillRoundedRect(canvas, x: x + 40, y: y + 44, w: 160, h: 28, radius: 6, color: img.ColorRgb8(139, 92, 246));
  img.drawString(canvas, 'NOW STREAMING', font: img.arial14, x: x + 52, y: y + 50, color: img.ColorRgb8(255, 255, 255));

  img.drawString(canvas, 'Morning Energy Briefing (Ep. 42)', font: img.arial24, x: x + 40, y: y + 90, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, '5-minute AI-curated audio digest for power executives', font: img.arial14, x: x + 40, y: y + 130, color: img.ColorRgb8(148, 163, 184));

  // Stylized Waveform representation
  final waveY = y + 180;
  final barHeights = [20, 45, 60, 35, 75, 90, 40, 65, 80, 50, 95, 70, 45, 85, 30, 60, 75, 40, 25];
  int barX = x + 60;
  for (int i = 0; i < barHeights.length; i++) {
    final bh = barHeights[i];
    final isPlayed = i < 9;
    img.fillRect(
      canvas,
      x1: barX,
      y1: waveY + (50 - bh ~/ 2),
      x2: barX + 16,
      y2: waveY + (50 + bh ~/ 2),
      color: isPlayed ? img.ColorRgb8(139, 92, 246) : img.ColorRgb8(51, 65, 85),
    );
    barX += 36;
  }

  // Scrubber & Times
  img.fillRect(canvas, x1: x + 40, y1: y + 310, x2: x + w - 40, y2: y + 316, color: img.ColorRgb8(30, 41, 59));
  img.fillRect(canvas, x1: x + 40, y1: y + 310, x2: x + 340, y2: y + 316, color: img.ColorRgb8(139, 92, 246));
  _fillRoundedRect(canvas, x: x + 330, y: y + 304, w: 20, h: 20, radius: 10, color: img.ColorRgb8(255, 255, 255));

  img.drawString(canvas, '02:18', font: img.arial14, x: x + 40, y: y + 330, color: img.ColorRgb8(148, 163, 184));
  img.drawString(canvas, '05:00', font: img.arial14, x: x + w - 85, y: y + 330, color: img.ColorRgb8(148, 163, 184));

  // Big Play/Pause Button in Center
  _fillRoundedRect(canvas, x: x + (w ~/ 2) - 40, y: y + 380, w: 80, h: 80, radius: 40, color: img.ColorRgb8(139, 92, 246));
  img.drawString(canvas, '||', font: img.arial24, x: x + (w ~/ 2) - 10, y: y + 405, color: img.ColorRgb8(255, 255, 255));

  // Speed and Narration pill
  _fillRoundedRect(canvas, x: x + 60, y: y + 400, w: 70, h: 40, radius: 10, color: img.ColorRgb8(30, 41, 59));
  img.drawString(canvas, '1.2x', font: img.arial14, x: x + 80, y: y + 412, color: img.ColorRgb8(255, 255, 255));

  _fillRoundedRect(canvas, x: x + w - 170, y: y + 400, w: 110, h: 40, radius: 10, color: img.ColorRgb8(30, 41, 59));
  img.drawString(canvas, 'AI Voice', font: img.arial14, x: x + w - 150, y: y + 412, color: img.ColorRgb8(255, 255, 255));

  // Upcoming in playlist
  final queueY = y + 610;
  img.drawString(canvas, 'Next in Queue', font: img.arial24, x: x + 30, y: queueY, color: img.ColorRgb8(255, 255, 255));

  _fillRoundedRect(canvas, x: x + 20, y: queueY + 40, w: w - 40, h: 90, radius: 16, color: img.ColorRgb8(22, 27, 34));
  img.drawString(canvas, 'Solar Rooftop Policy Changes (3 min)', font: img.arial14, x: x + 40, y: queueY + 60, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'Coverage of Delhi Solar Policy 2026 and consumer subsidies', font: img.arial14, x: x + 40, y: queueY + 85, color: img.ColorRgb8(148, 163, 184));
}

void _renderProfileViewUI(img.Image canvas, int x, int y, int w, int h) {
  // Identity Card (New Redesigned Layout)
  _fillRoundedRect(canvas, x: x + 20, y: y + 10, w: w - 40, h: 220, radius: 20, color: img.ColorRgb8(22, 27, 34));

  // Avatar Circle
  _fillRoundedRect(canvas, x: x + 40, y: y + 30, w: 70, h: 70, radius: 35, color: img.ColorRgb8(37, 99, 235));
  img.drawString(canvas, 'A', font: img.arial24, x: x + 65, y: y + 50, color: img.ColorRgb8(255, 255, 255));

  // Name & Email
  img.drawString(canvas, 'Arun B.', font: img.arial24, x: x + 130, y: y + 36, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'arunbsssbars@gmail.com', font: img.arial14, x: x + 130, y: y + 68, color: img.ColorRgb8(148, 163, 184));

  // Tier Badges
  _fillRoundedRect(canvas, x: x + 130, y: y + 94, w: 100, h: 22, radius: 6, color: img.ColorRgb8(16, 185, 129));
  img.drawString(canvas, 'ROOT ADMIN', font: img.arial14, x: x + 140, y: y + 98, color: img.ColorRgb8(255, 255, 255));

  _fillRoundedRect(canvas, x: x + 240, y: y + 94, w: 80, h: 22, radius: 6, color: img.ColorRgb8(2, 132, 199));
  img.drawString(canvas, 'VERIFIED', font: img.arial14, x: x + 250, y: y + 98, color: img.ColorRgb8(255, 255, 255));

  // Divider
  img.fillRect(canvas, x1: x + 40, y1: y + 135, x2: x + w - 40, y2: y + 136, color: img.ColorRgb8(38, 48, 64));

  // Meta pills: PROVIDER & STATUS
  _fillRoundedRect(canvas, x: x + 40, y: y + 150, w: (w - 100) ~/ 2, h: 60, radius: 10, color: img.ColorRgb8(15, 23, 42));
  img.drawString(canvas, 'PROVIDER', font: img.arial14, x: x + 54, y: y + 160, color: img.ColorRgb8(37, 99, 235));
  img.drawString(canvas, 'Google Account', font: img.arial14, x: x + 54, y: y + 180, color: img.ColorRgb8(255, 255, 255));

  _fillRoundedRect(canvas, x: x + 50 + (w - 100) ~/ 2, y: y + 150, w: (w - 100) ~/ 2, h: 60, radius: 10, color: img.ColorRgb8(15, 23, 42));
  img.drawString(canvas, 'STATUS', font: img.arial14, x: x + 64 + (w - 100) ~/ 2, y: y + 160, color: img.ColorRgb8(16, 185, 129));
  img.drawString(canvas, 'Active Session', font: img.arial14, x: x + 64 + (w - 100) ~/ 2, y: y + 180, color: img.ColorRgb8(255, 255, 255));

  // Personal Reading Activity Card
  final actY = y + 250;
  _fillRoundedRect(canvas, x: x + 20, y: actY, w: w - 40, h: 180, radius: 20, color: img.ColorRgb8(22, 27, 34));
  img.drawString(canvas, 'Reading Intelligence & Activity', font: img.arial14, x: x + 40, y: actY + 20, color: img.ColorRgb8(255, 255, 255));

  // Metric 1: Articles Read
  _fillRoundedRect(canvas, x: x + 40, y: actY + 54, w: (w - 100) ~/ 2, h: 100, radius: 14, color: img.ColorRgb8(15, 23, 42));
  _fillRoundedRect(canvas, x: x + 56, y: actY + 68, w: 28, h: 28, radius: 8, color: img.ColorRgb8(16, 185, 129));
  img.drawString(canvas, '42', font: img.arial24, x: x + 56, y: actY + 104, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'Articles Read', font: img.arial14, x: x + 56, y: actY + 130, color: img.ColorRgb8(148, 163, 184));

  // Metric 2: Saved Bookmarks
  _fillRoundedRect(canvas, x: x + 50 + (w - 100) ~/ 2, y: actY + 54, w: (w - 100) ~/ 2, h: 100, radius: 14, color: img.ColorRgb8(15, 23, 42));
  _fillRoundedRect(canvas, x: x + 66 + (w - 100) ~/ 2, y: actY + 68, w: 28, h: 28, radius: 8, color: img.ColorRgb8(245, 158, 11));
  img.drawString(canvas, '15', font: img.arial24, x: x + 66 + (w - 100) ~/ 2, y: actY + 104, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'Saved Bookmarks', font: img.arial14, x: x + 66 + (w - 100) ~/ 2, y: actY + 130, color: img.ColorRgb8(148, 163, 184));

  // Preferences Card
  final prefY = actY + 200;
  _fillRoundedRect(canvas, x: x + 20, y: prefY, w: w - 40, h: 260, radius: 20, color: img.ColorRgb8(22, 27, 34));

  // Setting 1: Dark Mode
  _fillRoundedRect(canvas, x: x + 40, y: prefY + 20, w: 36, h: 36, radius: 10, color: img.ColorRgb8(245, 158, 11));
  img.drawString(canvas, 'Dark Mode', font: img.arial14, x: x + 90, y: prefY + 24, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'High-contrast executive theme (Active)', font: img.arial14, x: x + 90, y: prefY + 44, color: img.ColorRgb8(148, 163, 184));
  _fillRoundedRect(canvas, x: x + w - 90, y: prefY + 24, w: 45, h: 24, radius: 12, color: img.ColorRgb8(37, 99, 235));

  // Setting 2: Tour & Gesture Guide
  _fillRoundedRect(canvas, x: x + 40, y: prefY + 80, w: 36, h: 36, radius: 10, color: img.ColorRgb8(2, 132, 199));
  img.drawString(canvas, 'Tour & Gesture Guide', font: img.arial14, x: x + 90, y: prefY + 84, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'Review swipe gestures & shortcuts', font: img.arial14, x: x + 90, y: prefY + 104, color: img.ColorRgb8(148, 163, 184));

  // Setting 3: Offline Reading Cache
  _fillRoundedRect(canvas, x: x + 40, y: prefY + 140, w: 36, h: 36, radius: 10, color: img.ColorRgb8(99, 102, 241));
  img.drawString(canvas, 'Offline Reading Cache', font: img.arial14, x: x + 90, y: prefY + 144, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, '42 offline articles cached locally', font: img.arial14, x: x + 90, y: prefY + 164, color: img.ColorRgb8(148, 163, 184));
  _fillRoundedRect(canvas, x: x + w - 120, y: prefY + 144, w: 75, h: 28, radius: 8, color: img.ColorRgb8(30, 41, 59));
  img.drawString(canvas, 'Optimize', font: img.arial14, x: x + w - 110, y: prefY + 151, color: img.ColorRgb8(99, 102, 241));

  // Privacy Policy Tile
  _fillRoundedRect(canvas, x: x + 40, y: prefY + 200, w: 36, h: 36, radius: 10, color: img.ColorRgb8(59, 130, 246));
  img.drawString(canvas, 'Privacy Policy', font: img.arial14, x: x + 90, y: prefY + 204, color: img.ColorRgb8(255, 255, 255));
  img.drawString(canvas, 'Review data handling & disclosures', font: img.arial14, x: x + 90, y: prefY + 224, color: img.ColorRgb8(148, 163, 184));
}

void _renderBottomNav(img.Image canvas, int x, int y, int w, _ScreenType activeType) {
  // Bottom Bar Surface
  img.fillRect(canvas, x1: x, y1: y, x2: x + w, y2: y + 90, color: img.ColorRgb8(15, 23, 42));
  img.fillRect(canvas, x1: x, y1: y, x2: x + w, y2: y + 1, color: img.ColorRgb8(30, 41, 59));

  final tabs = [
    {'label': 'Feed', 'type': _ScreenType.homeFeed},
    {'label': 'Digest', 'type': _ScreenType.articleDetail},
    {'label': 'Utilities', 'type': _ScreenType.stateUtilities},
    {'label': 'Audio', 'type': _ScreenType.audioDigest},
    {'label': 'Profile', 'type': _ScreenType.profileView},
  ];

  final tabW = w ~/ tabs.length;
  for (int i = 0; i < tabs.length; i++) {
    final t = tabs[i];
    final isActive = t['type'] == activeType;
    final tabCenterX = x + (i * tabW) + (tabW ~/ 2);
    final color = isActive ? img.ColorRgb8(37, 99, 235) : img.ColorRgb8(148, 163, 184);

    // Pill highlight for active tab
    if (isActive) {
      _fillRoundedRect(
        canvas,
        x: tabCenterX - 24,
        y: y + 14,
        w: 48,
        h: 24,
        radius: 12,
        color: img.ColorRgb8(37, 99, 235),
      );
    }

    img.drawString(
      canvas,
      t['label'] as String,
      font: img.arial14,
      x: tabCenterX - ((t['label'] as String).length * 4),
      y: y + 46,
      color: color,
    );
  }
}

// -----------------------------------------------------------------------------
// DRAWING UTILITIES
// -----------------------------------------------------------------------------

void _drawPill(
  img.Image canvas, {
  required int centerX,
  required int topY,
  required String text,
  required img.ColorRgb8 bgColor,
  required img.ColorRgb8 textColor,
}) {
  final pillWidth = text.length * 14 + 48;
  const pillHeight = 44;
  final pillLeft = centerX - (pillWidth ~/ 2);

  _fillRoundedRect(
    canvas,
    x: pillLeft,
    y: topY,
    w: pillWidth,
    h: pillHeight,
    radius: 22,
    color: bgColor,
  );

  img.drawString(
    canvas,
    text,
    font: img.arial24,
    x: pillLeft + 24,
    y: topY + 10,
    color: textColor,
  );
}

void _drawCenteredString(
  img.Image canvas, {
  required img.BitmapFont font,
  required int y,
  required String text,
  required img.ColorRgb8 color,
}) {
  // Approximate character width for built-in bitmap fonts
  final charWidth = font == img.arial48 ? 26 : (font == img.arial24 ? 13 : 8);
  final textWidth = text.length * charWidth;
  final x = (canvas.width - textWidth) ~/ 2;
  img.drawString(canvas, text, font: font, x: x > 20 ? x : 20, y: y, color: color);
}

void _fillRoundedRect(
  img.Image canvas, {
  required int x,
  required int y,
  required int w,
  required int h,
  required int radius,
  required img.ColorRgb8 color,
}) {
  final r = radius.clamp(0, (w ~/ 2)).clamp(0, (h ~/ 2));
  final rSq = r * r;

  for (int py = 0; py < h; py++) {
    for (int px = 0; px < w; px++) {
      final actualX = x + px;
      final actualY = y + py;
      if (actualX < 0 || actualX >= canvas.width || actualY < 0 || actualY >= canvas.height) {
        continue;
      }

      bool inside = true;
      if (px < r && py < r) {
        // Top-left corner
        final dx = r - px;
        final dy = r - py;
        if (dx * dx + dy * dy > rSq) inside = false;
      } else if (px >= w - r && py < r) {
        // Top-right corner
        final dx = px - (w - r - 1);
        final dy = r - py;
        if (dx * dx + dy * dy > rSq) inside = false;
      } else if (px < r && py >= h - r) {
        // Bottom-left corner
        final dx = r - px;
        final dy = py - (h - r - 1);
        if (dx * dx + dy * dy > rSq) inside = false;
      } else if (px >= w - r && py >= h - r) {
        // Bottom-right corner
        final dx = px - (w - r - 1);
        final dy = py - (h - r - 1);
        if (dx * dx + dy * dy > rSq) inside = false;
      }

      if (inside) {
        canvas.setPixel(actualX, actualY, color);
      }
    }
  }
}
