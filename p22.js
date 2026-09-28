const fs = require('fs');

// 1. firestoreService.js
let fss = fs.readFileSync('server/services/firestoreService.js', 'utf8');

const feedbackCode = `
async function saveFeedback(feedbackData) {
  const database = initFirestore();
  if (!database) return { success: true, offline: true };
  const docRef = await database.collection('feedbacks').add({
    ...feedbackData,
    timestamp: new Date().toISOString()
  });
  return { success: true, id: docRef.id };
}

async function getFeedbacks() {
  const database = initFirestore();
  if (!database) return [];
  const snapshot = await database.collection('feedbacks').orderBy('timestamp', 'desc').get();
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

module.exports = {
`;
fss = fss.replace(/module\.exports = {/, feedbackCode);
fss = fss.replace(/module\.exports = {/, "module.exports = {\n  saveFeedback,\n  getFeedbacks,");
fs.writeFileSync('server/services/firestoreService.js', fss);

// 2. apiRoutes.js
let api = fs.readFileSync('server/routes/apiRoutes.js', 'utf8');

api = api.replace(/const { getArticleContentById } = require\('\.\.\/services\/firestoreService'\);/, 
  "const { getArticleContentById, saveFeedback, getFeedbacks } = require('../services/firestoreService');");

const feedbackRoutes = `
// --- FEEDBACK ROUTES ---
router.post('/feedbacks', async (req, res) => {
  try {
    const { email, message, type } = req.body;
    if (!message) return res.status(400).json({ error: 'Message is required' });
    const result = await saveFeedback({ email, message, type: type || 'suggestion' });
    res.json(result);
  } catch (error) {
    console.error('[API] Error saving feedback:', error.message);
    res.status(500).json({ error: 'Failed to save feedback' });
  }
});

router.get('/feedbacks', async (req, res) => {
  try {
    const feedbacks = await getFeedbacks();
    res.json(feedbacks);
  } catch (error) {
    console.error('[API] Error fetching feedbacks:', error.message);
    res.status(500).json({ error: 'Failed to fetch feedbacks' });
  }
});

module.exports = router;
`;
api = api.replace(/module\.exports = router;/, feedbackRoutes);
fs.writeFileSync('server/routes/apiRoutes.js', api);
console.log('Backend feedback routes added.');
