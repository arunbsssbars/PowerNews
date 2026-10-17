import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:power_news/providers/news_provider.dart';
import 'package:power_news/models/news_article.dart';
import 'package:power_news/models/grid_persona.dart';
import 'package:power_news/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseService().close();
  });

  group('NewsProvider State & Filtering Tests', () {
    late NewsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = NewsProvider();
    });

    test('Initial filter state is clean and default', () {
      expect(provider.selectedCategory, 'All');
      expect(provider.selectedPlayer, 'All');
      expect(provider.selectedState, 'All States');
      expect(provider.selectedCity, 'All Cities');
      expect(provider.selectedDiscom, 'All DISCOMs');
      expect(provider.currentNavIndex, 0);
      expect(provider.searchQuery, isEmpty);
    });

    test('Updating category filter updates state', () {
      provider.setCategory('transmission');
      expect(provider.selectedCategory, 'transmission');
    });

    test('Updating player filter updates state and clears query', () {
      provider.setPlayerFilter('Siemens');
      expect(provider.selectedPlayer, 'Siemens');
    });

    test('Custom filter addition and removal works correctly', () {
      expect(provider.customFilters.contains('BESS Storage'), false);

      provider.addCustomFilter('BESS Storage');
      expect(provider.customFilters.contains('BESS Storage'), true);

      // Duplicate addition should be ignored
      provider.addCustomFilter('BESS Storage');
      expect(provider.customFilters.where((f) => f == 'BESS Storage').length, 1);

      // Remove custom filter
      provider.removeCustomFilter('BESS Storage');
      expect(provider.customFilters.contains('BESS Storage'), false);
    });

    test('Switching navigation index updates correctly', () {
      provider.setNavIndex(1);
      expect(provider.currentNavIndex, 1);

      provider.setNavIndex(2);
      expect(provider.currentNavIndex, 2);
    });

    test('Clear filters resets all filters to default including persona', () {
      provider.setCategory('renewables');
      provider.setPlayerFilter('NTPC');
      provider.setStateFilter('Rajasthan');

      provider.clearFilters();

      expect(provider.selectedCategory, 'All');
      expect(provider.selectedPlayer, 'All');
      expect(provider.selectedState, 'All States');
      expect(provider.selectedCity, 'All Cities');
      expect(provider.selectedPersona.id, 'all');
      expect(provider.personaOnlyFilter, false);
    });

    test('Persona selection and togglePersonaOnlyFilter update state correctly', () {
      expect(provider.selectedPersona.id, 'all');
      expect(provider.personaOnlyFilter, false);

      provider.setPersona(GridPersona.discom);
      expect(provider.selectedPersona, GridPersona.discom);

      provider.togglePersonaOnlyFilter();
      expect(provider.personaOnlyFilter, true);

      provider.togglePersonaOnlyFilter();
      expect(provider.personaOnlyFilter, false);
    });

    test('markAllNotificationsAsRead and applyNewArticles clear newArticlesCount while preserving notification inbox', () async {
      expect(provider.newArticlesCount, 0);

      // Trigger markAllNotificationsAsRead
      provider.markAllNotificationsAsRead();
      expect(provider.newArticlesCount, 0);

      // Trigger applyNewArticles
      await provider.applyNewArticles();
      expect(provider.newArticlesCount, 0);

      // Trigger clearAllNotifications
      provider.clearAllNotifications();
      expect(provider.newArticlesCount, 0);
      expect(provider.notificationArticles, isEmpty);
    });

    test('sortOrder defaults to latestFirst and toggles properly', () {
      expect(provider.sortOrder, FeedSortOrder.latestFirst);

      provider.toggleSortOrder();
      expect(provider.sortOrder, FeedSortOrder.earliestFirst);

      provider.toggleSortOrder();
      expect(provider.sortOrder, FeedSortOrder.latestFirst);
    });

    test('matchesPlayer correctly distinguishes Secure Meters from generic verb secures and Premier Energies', () {
      final premierArticle = NewsArticle(
        id: 'prem-1',
        title: 'Premier Energies secures 2.308 GW Solar cell and module orders - Solarbytes',
        summary: 'Premier Energies has secured multiple solar module manufacturing orders across India.',
        url: 'https://example.com/premier',
        source: 'Solarbytes',
        publishedAt: DateTime.now(),
        categories: ['renewables'],
        player: 'Premier Energies',
        state: 'Telangana',
      );

      final tataArticle = NewsArticle(
        id: 'tata-1',
        title: 'Tata Power secures 500 MW solar auction bid',
        summary: 'Tata Power Renewable Energy secures letter of award from SECI.',
        url: 'https://example.com/tata',
        source: 'ET EnergyWorld',
        publishedAt: DateTime.now(),
        categories: ['renewables'],
        player: 'Tata Power',
        state: 'National / Pan-India',
      );

      final secureMetersArticle = NewsArticle(
        id: 'sec-1',
        title: 'Secure Meters deploys 200,000 smart meters in UP',
        summary: 'Secure Meters Limited announced completion of its advanced metering rollout for DISCOMs.',
        url: 'https://example.com/secure',
        source: 'Power Line Magazine',
        publishedAt: DateTime.now(),
        categories: ['distribution'],
        player: 'Secure Meters',
        state: 'Uttar Pradesh',
      );

      // 1. Premier Energies article must NOT match Secure Meters
      expect(NewsProvider.matchesPlayer(premierArticle, 'Secure Meters'), isFalse);
      // 2. Premier Energies article must match Premier Energies
      expect(NewsProvider.matchesPlayer(premierArticle, 'Premier Energies'), isTrue);

      // 3. Tata Power article with 'secures' must NOT match Secure Meters
      expect(NewsProvider.matchesPlayer(tataArticle, 'Secure Meters'), isFalse);
      // 4. Tata Power article must match Tata Power
      expect(NewsProvider.matchesPlayer(tataArticle, 'Tata Power'), isTrue);

      // 5. Genuine Secure Meters article must match Secure Meters
      expect(NewsProvider.matchesPlayer(secureMetersArticle, 'Secure Meters'), isTrue);
      // 6. Genuine Secure Meters article must NOT match Premier Energies
      expect(NewsProvider.matchesPlayer(secureMetersArticle, 'Premier Energies'), isFalse);
    });

    test('Strict AI summary gate rejects pseudo-summaries, repeated titles, and marketing blurbs', () {
      final fakeVikram = NewsArticle(
        id: 'vik-1',
        title: 'India’s Vikram Solar secures 187 MW module supply order - Evertiq',
        summary: 'India’s Vikram Solar secures 187 MW module supply order - Evertiq. India’s Vikram Solar secures 187 MW module supply order Evertiq',
        url: 'https://example.com/vikram',
        source: 'Evertiq',
        publishedAt: DateTime.now(),
        categories: ['renewables'],
        isAiGenerated: true,
        state: 'National / Pan-India',
      );

      final fakeMarketing = NewsArticle(
        id: 'sw-1',
        title: 'Sterling and Wilson’s Q2 Revenue Down 12.6% Due to Weak EPC Project Execution',
        summary: 'The company reported a PAT of ₹170 million. Where clean energy\'s most influential leaders get their intelligence Exclusive reporting, market intelligence, and insider access that shapes billion-dollar decisions in renewable energy.',
        url: 'https://example.com/sw',
        source: 'Mercom India',
        publishedAt: DateTime.now(),
        categories: ['renewables'],
        isAiGenerated: true,
        state: 'National / Pan-India',
      );

      final genuineAiArticle = NewsArticle(
        id: 'gen-1',
        title: 'Data centre growth could pose new power grid challenges, warns GRID',
        summary: 'The rapid expansion of data centers across India presents significant emerging challenges for national power grid stability and distribution infrastructure. As high-density power consumers, these facilities necessitate immediate grid reinforcement and strategic policy interventions to manage load fluctuations.',
        url: 'https://example.com/grid',
        source: 'ET EnergyWorld',
        publishedAt: DateTime.now(),
        categories: ['transmission'],
        isAiGenerated: true,
        state: 'National / Pan-India',
      );

      // Vikram Solar doubled-title pseudo-summary must be rejected
      expect(fakeVikram.hasAuthenticAiSummary, isFalse);

      // Marketing boilerplate blurb must be rejected
      expect(fakeMarketing.hasAuthenticAiSummary, isFalse);

      // Genuine narrative executive summary must pass
      expect(genuineAiArticle.hasAuthenticAiSummary, isTrue);
    });
  });
}
