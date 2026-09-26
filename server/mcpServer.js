const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js');
const { SSEServerTransport } = require('@modelcontextprotocol/sdk/server/sse.js');
const { z } = require('zod');

// MCP Server Initialization
const mcp = new McpServer({
  name: "PowerNews MCP Server",
  version: "1.0.0"
});

// A global reference to articleStore passed from Express
let storeRef = null;

// Tool: get_latest_news
mcp.tool("get_latest_news", 
  "Retrieve the latest Indian power sector news.",
  {
    limit: z.number().optional().describe("Number of articles to return (max 20)"),
    category: z.string().optional().describe("Filter by category (e.g. transmission, renewables, policy)"),
    state: z.string().optional().describe("Filter by state (e.g. UP, Maharashtra)")
  }, 
  async ({ limit = 5, category, state }) => {
    if (!storeRef) return { content: [{ type: "text", text: "Article store not initialized." }] };
    
    let articles = storeRef.getArticles() || [];
    
    if (category) {
      articles = articles.filter(a => a.primaryCategory?.toLowerCase() === category.toLowerCase());
    }
    if (state) {
      articles = articles.filter(a => a.state?.toLowerCase() === state.toLowerCase());
    }
    
    const maxLimit = Math.min(limit, 20);
    const sliced = articles.slice(0, maxLimit);
    
    const formatted = sliced.map(a => 
      `Title: ${a.title}\nSource: ${a.publisher}\nCategory: ${a.primaryCategory}\nSummary:\n${a.summary}`
    ).join("\n\n---\n\n");

    return {
      content: [{
        type: "text",
        text: formatted || "No articles found matching the criteria."
      }]
    };
  }
);

// Tool: search_news
mcp.tool("search_news",
  "Search the PowerNews database for specific keywords or companies.",
  {
    query: z.string().describe("Search query (e.g., 'Adani', 'solar tariff', '765kV')")
  },
  async ({ query }) => {
    if (!storeRef) return { content: [{ type: "text", text: "Article store not initialized." }] };
    
    const articles = storeRef.getArticles() || [];
    const lowerQuery = query.toLowerCase();
    
    const matched = articles.filter(a => 
      a.title.toLowerCase().includes(lowerQuery) || 
      (a.summary && a.summary.toLowerCase().includes(lowerQuery)) ||
      (a.player && a.player.toLowerCase().includes(lowerQuery))
    ).slice(0, 10);
    
    const formatted = matched.map(a => 
      `Title: ${a.title}\nSource: ${a.publisher}\nDate: ${a.pubDate}\nSummary:\n${a.summary}`
    ).join("\n\n---\n\n");

    return {
      content: [{
        type: "text",
        text: formatted || `No recent news found for '${query}'.`
      }]
    };
  }
);

// Global transport mappings to support multiple concurrent SSE clients
const transports = new Map();

function setupMcp(app, articleStore) {
  storeRef = articleStore;

  // Endpoint to establish SSE connection
  app.get('/mcp/sse', async (req, res) => {
    const transport = new SSEServerTransport('/mcp/message', res);
    const sessionId = Math.random().toString(36).substring(7);
    transports.set(sessionId, transport);
    
    res.on('close', () => {
      transports.delete(sessionId);
    });

    await mcp.connect(transport);
  });

  // Endpoint to handle incoming JSON-RPC POST messages
  app.post('/mcp/message', async (req, res) => {
    const sessionId = req.query.sessionId;
    
    // SSEServerTransport expects handling via its dedicated handler or we can loop through active
    // However, the @modelcontextprotocol/sdk SSEServerTransport actually binds to the res of the SSE request,
    // and exposes a handler for POST requests.
    // The correct pattern for the SDK is to locate the transport.
    
    // Instead of custom maps, since express req/res are specific to each endpoint hit,
    // The @modelcontextprotocol/sdk SSEServerTransport requires routing the POST req/res to `transport.handlePostMessage(req, res)`
    // Let's iterate and try to handle it. A safer way for single-server is getting the transport from query if possible, 
    // but the SDK uses a session ID internally in the endpoint URL.
    
    let handled = false;
    for (const [id, transport] of transports.entries()) {
      if (transport.sessionId === req.query.sessionId) {
        await transport.handlePostMessage(req, res);
        handled = true;
        break;
      }
    }
    
    if (!handled) {
      res.status(404).send('Session not found');
    }
  });

  console.log('[MCP] Model Context Protocol Server initialized at /mcp/sse');
}

module.exports = { setupMcp };
