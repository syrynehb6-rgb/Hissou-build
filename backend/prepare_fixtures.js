const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'test', 'fixtures');

function writeWav16k(outPath, samples) {
  const out = Buffer.alloc(44 + samples.length * 2);
  out.write('RIFF', 0);
  out.writeUInt32LE(36 + samples.length * 2, 4);
  out.write('WAVEfmt ', 8);
  out.writeUInt32LE(16, 16);
  out.writeUInt16LE(1, 20);
  out.writeUInt16LE(1, 22);
  out.writeUInt32LE(16000, 24);
  out.writeUInt32LE(32000, 28);
  out.writeUInt16LE(2, 32);
  out.writeUInt16LE(16, 34);
  out.write('data', 36);
  out.writeUInt32LE(samples.length * 2, 40);
  for (let i = 0; i < samples.length; i++) {
    out.writeInt16LE(samples[i], 44 + i * 2);
  }
  fs.writeFileSync(outPath, out);
}

for (const f of fs.readdirSync(dir)) {
  if (!f.endsWith('.wav')) continue;
  const p = path.join(dir, f);
  const b = fs.readFileSync(p);
  const rate = b.readUInt32LE(24);
  if (rate === 16000) continue;
  let pos = 12;
  while (pos + 8 <= b.length) {
    const id = b.toString('ascii', pos, pos + 4);
    const sz = b.readUInt32LE(pos + 4);
    if (id === 'data') {
      const inSamples = sz / 2;
      const outSamples = Math.floor((inSamples * 16000) / rate);
      const samples = new Int16Array(outSamples);
      for (let i = 0; i < outSamples; i++) {
        const srcIdx = Math.min(inSamples - 1, Math.floor((i * rate) / 16000));
        samples[i] = b.readInt16LE(pos + 8 + srcIdx * 2);
      }
      writeWav16k(p, samples);
      console.log(`${f}: resampled ${rate}Hz -> 16000Hz (${outSamples} samples)`);
      break;
    }
    pos += 8 + sz;
  }
}

// Generate silence.wav (2 seconds @ 16kHz)
writeWav16k(path.join(dir, 'silence.wav'), new Int16Array(32000));
console.log('silence.wav: generated (32000 samples)');
