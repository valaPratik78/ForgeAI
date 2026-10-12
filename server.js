const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const BACKEND_URL = 'http://localhost:8080';
const PUBLIC_DIR = path.join(__dirname, 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2'
};

// Built-in preview templates for the Template Gallery
const TEMPLATES = {
  'startup': {
    title: 'NovaPulse - AI Infrastructure',
    tagline: 'Scale Your AI Workloads at the Speed of Thought',
    desc: 'The next-generation distributed runtime engine with ultra-low latency, instant elasticity, and automated multi-cloud failover.',
    accent: '#00F0FF',
    secondary: '#7000FF',
    cards: [
      { icon: '⚡', title: 'Sub-Millisecond Execution', text: 'Distributed global edge nodes ensure prompt latency below 5ms.' },
      { icon: '🛡️', title: 'Enterprise Cryptography', text: 'End-to-end homomorphic encryption protects proprietary weights.' },
      { icon: '📈', title: 'Predictive Auto-Scaling', text: 'Automated cluster scaling responds dynamically to request spikes.' }
    ]
  },
  'portfolio': {
    title: 'Elena Vance - Principal Creative Technologist',
    tagline: 'Crafting Immersive Digital Frontiers',
    desc: 'Specializing in generative aesthetics, spatial computing, and next-generation design systems.',
    accent: '#FF007A',
    secondary: '#7928CA',
    cards: [
      { icon: '🔮', title: 'Spatial Interfaces', text: 'Pioneered mixed-reality frameworks selected for award exhibitions.' },
      { icon: '✨', title: 'Generative Typography', text: 'Dynamic algorithmic type engines featured on Type Trends 2026.' },
      { icon: '🌐', title: 'Global Installations', text: 'Interactive audiovisual exhibits installed across Tokyo and Berlin.' }
    ]
  },
  'business': {
    title: 'Apex Capital Advisors',
    tagline: 'Strategic Governance & Institutional Stewardship',
    desc: 'Delivering precision advisory services, mergers & acquisitions guidance, and global asset management.',
    accent: '#38BDF8',
    secondary: '#1E40AF',
    cards: [
      { icon: '🏛️', title: 'Global Asset Allocation', text: 'Over $4.2B in advisory management across prime international markets.' },
      { icon: '📊', title: 'Algorithmic Risk Modeling', text: 'Multi-factor quantitative stress-testing under extreme macro conditions.' },
      { icon: '🤝', title: 'Cross-Border M&A', text: 'Unmatched legal and fiscal execution for cross-continental transactions.' }
    ]
  },
  'landing-page': {
    title: 'ConvertPeak - High-Velocity Funnels',
    tagline: 'Turn Clicks Into Committed Customers',
    desc: 'The highest-converting landing page framework ever engineered. Built for viral launches and frictionless checkouts.',
    accent: '#10B981',
    secondary: '#059669',
    cards: [
      { icon: '🎯', title: 'AI Copy Testing', text: 'Automated headline permutation testing yielding up to +42% lift.' },
      { icon: '⚡', title: 'Instant Load Speeds', text: 'Zero bundle bloat with 99+ Lighthouse performance scores.' },
      { icon: '💳', title: 'One-Click Checkout', text: 'Native Apple Pay and Google Pay integrations built directly into CTA.' }
    ]
  },
  'product-page': {
    title: 'AeroSync Earbuds Pro',
    tagline: 'Acoustic Perfection in Ultra-Titanium',
    desc: 'Beryllium acoustic drivers, true spatial head-tracking, and 48-hour continuous battery life.',
    accent: '#F59E0B',
    secondary: '#D97706',
    cards: [
      { icon: '🎧', title: 'Beryllium Drivers', text: 'Lab-tuned frequency response from 10Hz to 45kHz with zero distortion.' },
      { icon: '🔋', title: '48h Battery Life', text: 'Supercharged graphene cells deliver 8 hours on a 5-minute charge.' },
      { icon: '🌊', title: 'IPX8 Waterproof', text: 'Hermetically sealed acoustic chambers withstand submersible immersion.' }
    ]
  },
  'blog': {
    title: 'The Modern Synthesist',
    tagline: 'Dispatches on Technology, Architecture, and Artificial Minds',
    desc: 'An independent journal exploring the convergence of deep learning, systems software, and digital culture.',
    accent: '#EC4899',
    secondary: '#8B5CF6',
    cards: [
      { icon: '📖', title: 'The Post-Cloud Era', text: 'Why local silicon and edge mesh architectures will replace monolithic clusters.' },
      { icon: '🧠', title: 'Cognitive Compilers', text: 'How code generation models are altering compiler design primitives.' },
      { icon: '🎨', title: 'Design in the AI Age', text: 'The renewed importance of hand-crafted craftsmanship in automated eras.' }
    ]
  }
};

function generateTemplateHtml(id) {
  const t = TEMPLATES[id] || TEMPLATES['startup'];
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${t.title}</title>
  <style>
    :root {
      --bg: #0B0F19;
      --card-bg: rgba(30, 41, 59, 0.7);
      --text: #F8FAFC;
      --muted: #94A3B8;
      --accent: ${t.accent};
      --secondary: ${t.secondary};
    }
    * { margin: 0; padding: 0; box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    body { background: var(--bg); color: var(--text); min-height: 100vh; overflow-x: hidden; line-height: 1.6; }
    header { position: sticky; top: 0; z-index: 100; backdrop-filter: blur(12px); background: rgba(11, 15, 25, 0.8); border-bottom: 1px solid rgba(255, 255, 255, 0.08); padding: 1rem 2rem; display: flex; justify-content: space-between; align-items: center; }
    .brand { font-size: 1.25rem; font-weight: 800; background: linear-gradient(135deg, var(--accent), var(--secondary)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; letter-spacing: -0.5px; }
    .nav-btn { background: var(--accent); color: #000; font-weight: 700; border: none; padding: 0.6rem 1.4rem; border-radius: 999px; cursor: pointer; transition: transform 0.2s, box-shadow 0.2s; }
    .nav-btn:hover { transform: translateY(-2px); box-shadow: 0 0 20px var(--accent); }
    .hero { padding: 6rem 2rem 4rem; text-align: center; max-width: 900px; margin: 0 auto; }
    .badge { display: inline-block; padding: 0.4rem 1rem; border-radius: 999px; background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.1); color: var(--accent); font-size: 0.85rem; font-weight: 600; margin-bottom: 1.5rem; }
    h1 { font-size: clamp(2.5rem, 5vw, 4rem); font-weight: 800; line-height: 1.15; margin-bottom: 1.5rem; letter-spacing: -1px; }
    h1 span { background: linear-gradient(135deg, var(--accent), var(--secondary)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    p.subtitle { font-size: 1.2rem; color: var(--muted); margin-bottom: 2.5rem; max-width: 650px; margin-left: auto; margin-right: auto; }
    .cta-group { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; margin-bottom: 4rem; }
    .btn-main { background: linear-gradient(135deg, var(--accent), var(--secondary)); color: #fff; font-weight: 700; border: none; padding: 0.9rem 2.2rem; border-radius: 12px; font-size: 1rem; cursor: pointer; transition: all 0.2s; box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3); }
    .btn-main:hover { transform: translateY(-3px); box-shadow: 0 12px 30px rgba(0, 240, 255, 0.25); }
    .btn-outline { background: transparent; color: var(--text); border: 1px solid rgba(255, 255, 255, 0.2); font-weight: 600; padding: 0.9rem 2.2rem; border-radius: 12px; font-size: 1rem; cursor: pointer; transition: all 0.2s; }
    .btn-outline:hover { background: rgba(255, 255, 255, 0.05); border-color: rgba(255, 255, 255, 0.4); }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 1.5rem; max-width: 1100px; margin: 0 auto; padding: 2rem; }
    .card { background: var(--card-bg); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 16px; padding: 2rem; text-align: left; transition: transform 0.2s, border-color 0.2s; }
    .card:hover { transform: translateY(-4px); border-color: var(--accent); }
    .card .icon { font-size: 2rem; margin-bottom: 1rem; }
    .card h3 { font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem; }
    .card p { color: var(--muted); font-size: 0.95rem; }
    footer { border-top: 1px solid rgba(255, 255, 255, 0.08); padding: 3rem 2rem; text-align: center; color: var(--muted); font-size: 0.9rem; margin-top: 4rem; }
  </style>
</head>
<body>
  <header>
    <div class="brand">${t.title.split(' - ')[0]}</div>
    <button class="nav-btn">Get Started</button>
  </header>
  <main class="hero">
    <div class="badge">🔥 ForgeAI Verified Template</div>
    <h1>${t.tagline.split(' ').slice(0, -2).join(' ')} <span>${t.tagline.split(' ').slice(-2).join(' ')}</span></h1>
    <p class="subtitle">${t.desc}</p>
    <div class="cta-group">
      <button class="btn-main">Explore Interactive Demo</button>
      <button class="btn-outline">Documentation</button>
    </div>
  </main>
  <section class="grid">
    ${t.cards.map(c => `
      <div class="card">
        <div class="icon">${c.icon}</div>
        <h3>${c.title}</h3>
        <p>${c.text}</p>
      </div>
    `).join('')}
  </section>
  <footer>
    <p>&copy; 2026 ${t.title.split(' - ')[0]}. Generated & Optimized by ForgeAI Engine.</p>
  </footer>
</body>
</html>`;
}

const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Disable Caching for all development files
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Intercept template preview requests
  const templatePreviewMatch = req.url.match(/^\/api\/templates\/([^/]+)\/preview\/index\.html/);
  if (templatePreviewMatch) {
    const templateId = templatePreviewMatch[1];
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(generateTemplateHtml(templateId));
    return;
  }

  // Intercept template list request if backend doesn't handle it
  if (req.url === '/api/templates') {
    const templateList = Object.keys(TEMPLATES).map(id => ({
      id,
      name: TEMPLATES[id].title,
      description: TEMPLATES[id].desc,
      category: id.charAt(0).toUpperCase() + id.slice(1),
      availablePages: ['index.html'],
      tags: ['Verified', 'Responsive', 'Modern'],
      previewUrl: `/api/templates/${id}/preview/index.html`
    }));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(templateList));
    return;
  }

  // Check if it is an API request -> Proxy to Spring Boot Backend
  if (req.url.startsWith('/api/')) {
    let parsedUrl;
    try {
      parsedUrl = new URL(req.url, BACKEND_URL);
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'text/plain' });
      res.end('Bad Request: Invalid URL');
      return;
    }

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || 80,
      path: parsedUrl.pathname + parsedUrl.search,
      method: req.method,
      headers: {
        ...req.headers,
        host: parsedUrl.host
      }
    };

    const proxyReq = http.request(options, (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res, { end: true });
    });

    proxyReq.on('error', (err) => {
      console.error(`[Proxy Error] ${err.message}`);
      res.writeHead(502, { 'Content-Type': 'text/plain' });
      res.end(`Bad Gateway: Could not connect to backend at ${BACKEND_URL}`);
    });

    req.pipe(proxyReq, { end: true });
    return;
  }

  // Static file serving for Flutter Web
  let cleanUrl = req.url.split('?')[0];
  let filePath = path.join(PUBLIC_DIR, cleanUrl === '/' ? 'index.html' : cleanUrl);

  // Prevent directory traversal
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end('403 Forbidden');
    return;
  }

  const ext = path.extname(filePath);
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        // SPA Fallback: Flutter handles routing client-side
        fs.readFile(path.join(PUBLIC_DIR, 'index.html'), (err2, indexContent) => {
          if (err2) {
            res.writeHead(404);
            res.end('404 Not Found');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
            res.end(indexContent);
          }
        });
      } else {
        res.writeHead(500);
        res.end(`500 Internal Server Error: ${err.code}`);
      }
      return;
    }

    res.writeHead(200, { 'Content-Type': contentType });

    // Dynamic replacement in main.dart.js:
    // Replaces production Koyeb URL with local absolute URL http://localhost:3000
    // so API and preview calls route through this server cleanly without CORS issues.
    if (path.basename(filePath) === 'main.dart.js') {
      let jsText = content.toString('utf8');
      const targetUrl = 'https://breakable-hedwig-bb121-194c7ef8.koyeb.app';
      const replacementUrl = 'http://localhost:3000';
      if (jsText.includes(targetUrl)) {
        console.log(`[Server] Routing API requests through localhost:3000 proxy`);
        jsText = jsText.split(targetUrl).join(replacementUrl);
      }
      res.end(Buffer.from(jsText, 'utf8'));
    } else {
      res.end(content);
    }
  });
});

server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`  🚀 ForgeAI Web Client & API Gateway Active!`);
  console.log(`  🌐 Frontend URL:  http://localhost:${PORT}`);
  console.log(`  🔌 Backend Proxy: ${BACKEND_URL}`);
  console.log(`====================================================`);
});
