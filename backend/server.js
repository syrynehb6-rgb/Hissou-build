// Minimal proxy that keeps the Gemini API key off the device.
// Run: GEMINI_API_KEY=... node server.js   (Node 18+, no dependencies)
const http = require('http');

const KEY = process.env.GEMINI_API_KEY;
const MODELS = process.env.GEMINI_MODEL
  ? [process.env.GEMINI_MODEL]
  : ['gemini-3.6-flash', 'gemini-3.5-flash', 'gemini-3.5-flash-lite'];
const PORT = process.env.PORT || 8080;
const LANGS = { en: 'English', fr: 'French', ar: 'Arabic' };

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (c) => {
      size += c.length;
      if (size > 12 * 1024 * 1024) { reject(new Error('too large')); req.destroy(); }
      chunks.push(c);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString()));
    req.on('error', reject);
  });
}

async function callGemini(payload) {
  let lastErr = 'upstream error';
  for (const model of MODELS) {
    try {
      const r = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': KEY },
          body: JSON.stringify(payload),
          signal: AbortSignal.timeout(15000),
        }
      );
      const data = await r.json();
      if (r.ok) {
        const parts = data.candidates?.[0]?.content?.parts || [];
        const textPart = parts.find((p) => p.text && !p.thought) || parts[parts.length - 1];
        return JSON.parse(textPart?.text || '{}');
      }
      lastErr = data.error?.message || `HTTP ${r.status}`;
    } catch (e) {
      lastErr = String(e.message || e);
    }
  }
  throw new Error(lastErr);
}

http.createServer(async (req, res) => {
  const send = (code, obj) => {
    res.writeHead(code, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(obj));
  };
  if (req.method !== 'POST' || req.url !== '/interpret') return send(404, { error: 'not found' });
  if (!KEY) return send(500, { error: 'GEMINI_API_KEY not set' });

  try {
    const { audioBase64, mimeType, species, name, context, language, soundClass } =
      JSON.parse(await readBody(req));
    if (!audioBase64) return send(400, { error: 'audioBase64 required' });
    const lang = LANGS[language] || 'English';

    const prompt =
      `You are a playful, warm pet-communication assistant. Listen to this ${species || 'animal'} sound` +
      (name ? ` from a pet named ${name}` : '') + '.' +
      (soundClass ? ` An on-device classifier labelled it "${soundClass}".` : '') +
      (context ? ` Situation: ${context}.` : '') +
      ` Infer the most likely mood/need (e.g. hungry, playful, anxious, in pain, alert) from the vocalization.` +
      ` Reply ONLY with JSON: {"mood": short label, "message": 1-3 sentences in first person as the animal,` +
      ` "advice": 1 short sentence of practical advice for the owner, "confidence": 0-1}.` +
      ` Write all text values in ${lang}. If no animal sound is audible, say so in "message" with confidence 0.`;

    const result = await callGemini({
      contents: [{ parts: [
        { text: prompt },
        { inline_data: { mime_type: mimeType || 'audio/wav', data: audioBase64 } },
      ] }],
      generationConfig: {
        responseMimeType: 'application/json',
      },
    });
    send(200, result);
  } catch (e) {
    send(502, { error: String(e.message || e) });
  }
}).listen(PORT, () => console.log(`Hissou proxy on :${PORT}`));
