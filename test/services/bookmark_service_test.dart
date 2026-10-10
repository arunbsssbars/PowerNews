import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:power_news/models/news_article.dart';
import 'package:power_news/services/bookmark_service.dart';
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

  group('BookmarkService Tests', () {
    late BookmarkService bookmarkService;

    final testArticle = NewsArticle(
      id: 'bm-1',
      title: 'Siemens Energy wins HVDC contract',
      summary: 'Siemens Energy bags major transmission contract.',
      url: 'https://powerline.net.in/siemens-hvdc',
      source: 'Power Line Magazine',
      publishedAt: DateTime.now(),
      categories: ['transmission'],
      player: 'Siemens',
      state: 'National / Pan-India',
    );

    setUp(() async {
      bookmarkService = BookmarkService();
      await DatabaseService().clearUnbookmarkedCache();
      final existing = await bookmarkService.isBookmarked('bm-1');
      if (existing) {
        await bookmarkService.toggleBookmark(testArticle);
      }
    });

    test('Toggling adds and removes bookmark', () async {
      expect(await bookmarkService.isBookmarked('bm-1'), false);

      // Add bookmark
      await bookmarkService.toggleBookmark(testArticle);
      expect(await bookmarkService.isBookmarked('bm-1'), true);

      final bookmarks = await bookmarkService.getBookmarks();
      expect(bookmarks.length, 1);
      expect(bookmarks.first.title, 'Siemens Energy wins HVDC contract');

      // Remove bookmark
      await bookmarkService.toggleBookmark(testArticle);
      expect(await bookmarkService.isBookmarked('bm-1'), false);
      expect((await bookmarkService.getBookmarks()).length, 0);
    });
  });
}
