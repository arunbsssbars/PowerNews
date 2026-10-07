/**
 * In-memory article store and state management
 */
let cachedArticles = [];
let lastRefreshedAt = null;

module.exports = {
  getArticles: () => cachedArticles,
  setArticles: (articles) => {
    cachedArticles = articles;
    lastRefreshedAt = new Date().toISOString();
  },
  getLastRefreshedAt: () => lastRefreshedAt,
  mergeArticles: (articles = []) => {
    if (!articles || articles.length === 0) return;
    const existingMap = new Map(cachedArticles.map(a => [a.id, a]));
    const existingTitleMap = new Map(
      cachedArticles.map(a => [(a.title || '').toLowerCase().replace(/[^a-z0-9]/g, ''), a.id])
    );

    for (const a of articles) {
      if (!a) continue;
      const titleKey = (a.title || '').toLowerCase().replace(/[^a-z0-9]/g, '');
      const existingIdByTitle = titleKey ? existingTitleMap.get(titleKey) : null;
      const targetId = existingMap.has(a.id) ? a.id : existingIdByTitle;

      if (!targetId || !existingMap.has(targetId)) {
        if (a.id) {
          existingMap.set(a.id, a);
          if (titleKey) existingTitleMap.set(titleKey, a.id);
        }
      } else {
        const current = existingMap.get(targetId);
        existingMap.set(targetId, {
          ...a,
          ...current,
          summary: (current.summary && current.summary.length >= 75 && !current.summary.startsWith('• '))
            ? current.summary
            : (a.summary || current.summary),
          sources: (current.sources && current.sources.length > 0) ? current.sources : a.sources,
          sourceLinks: (current.sourceLinks && current.sourceLinks.length > 0) ? current.sourceLinks : a.sourceLinks,
        });
      }
    }
    cachedArticles = Array.from(existingMap.values());
    cachedArticles.sort((a, b) => new Date(b.publishedAt || 0) - new Date(a.publishedAt || 0));
    if (!lastRefreshedAt) {
      lastRefreshedAt = new Date().toISOString();
    }
  },
  removeArticle: (id) => {
    if (!id) return;
    cachedArticles = cachedArticles.filter(a => a.id !== id);
  },
};
