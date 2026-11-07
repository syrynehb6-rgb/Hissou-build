const fs = require('fs');
const path = require('path');

const API_URL = process.env.API_URL || 'http://127.0.0.1:8080/interpret';
const fixturesDir = path.join(__dirname, '..', 'test', 'fixtures');

const testSuite = [
  {
    id: 'E2E-1',
    title: 'Dog Barking (English)',
    file: 'dog_bark.wav',
    species: 'dog',
    name: 'Rex',
    context: 'Standing by the front door',
    language: 'en',
    soundClass: 'Dog (0.88); Bark (0.81)',
  },
  {
    id: 'E2E-2',
    title: 'Cat Meowing (French)',
    file: 'cat_meow.wav',
    species: 'cat',
    name: 'Mimi',
    context: 'Devant son bol vide le matin',
    language: 'fr',
    soundClass: 'Cat (0.85); Meow (0.79)',
  },
  {
    id: 'E2E-3',
    title: 'Birds Chirping (Arabic)',
    file: 'chirping_birds.wav',
    species: 'bird',
    name: 'Coco',
    context: 'في الصباح قرب النافذة',
    language: 'ar',
    soundClass: 'Bird (0.91); Chirp, tweet (0.84)',
  },
  {
    id: 'E2E-4',
    title: 'Rooster / Bird Calling (English)',
    file: 'rooster_bird.wav',
    species: 'bird',
    name: 'Sunny',
    context: 'Sunrise in the yard',
    language: 'en',
    soundClass: 'Bird (0.89); Crowing, cock-a-doodle-doo (0.86)',
  },
  {
    id: 'E2E-5',
    title: 'Farm / Horse & Livestock Vocalization (French)',
    file: 'cow_horse_farm.wav',
    species: 'horse',
    name: 'ornado',
    context: 'Dans le pré avant le repas',
    language: 'fr',
    soundClass: 'Livestock, farm animals, working animals (0.76)',
  },
  {
    id: 'E2E-6',
    title: 'Silence / No Animal Sound Gate (English)',
    file: 'silence.wav',
    species: 'dog',
    name: 'Rex',
    context: 'Quiet room',
    language: 'en',
    soundClass: 'No clear animal vocalization detected',
  },
];

async function runTests() {
  console.log('=== Hissou E2E Voice Interpretation Test Suite ===\n');
  let passed = 0;
  let failed = 0;

  for (const t of testSuite) {
    const filePath = path.join(fixturesDir, t.file);
    const bytes = fs.readFileSync(filePath);
    const payload = {
      audioBase64: bytes.toString('base64'),
      mimeType: 'audio/wav',
      species: t.species,
      name: t.name,
      context: t.context,
      language: t.language,
      soundClass: t.soundClass,
    };

    const start = Date.now();
    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const elapsed = Date.now() - start;
      const body = await res.json();

      if (res.status === 200 && typeof body.message === 'string' && body.mood !== undefined) {
        passed++;
        console.log(`[PASS] ${t.id}: ${t.title} (${elapsed}ms)`);
        console.log(`       Mood: ${body.mood} | Confidence: ${body.confidence}`);
        console.log(`       Message: "${body.message}"`);
        console.log(`       Advice:  "${body.advice}"\n`);
      } else {
        failed++;
        console.log(`[FAIL] ${t.id}: ${t.title} (HTTP ${res.status}, ${elapsed}ms)`);
        console.log(`       Response: ${JSON.stringify(body)}\n`);
      }
    } catch (err) {
      failed++;
      console.log(`[FAIL] ${t.id}: ${t.title} - ${err.message}\n`);
    }
  }

  console.log(`=== Summary: ${passed} passed, ${failed} failed out of ${testSuite.length} ===`);
  if (failed > 0) process.exitCode = 1;
}

runTests();
