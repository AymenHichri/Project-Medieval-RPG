// Measure pixel-art indicators for each PNG passed as an argument.
// Usage: node measure.js <file> [cropW cropH]  (crops first frame from top-left if given)
const sharp = require('sharp');
(async () => {
  const args = process.argv.slice(2);
  for (const f of args) {
    try {
      const img = sharp(f);
      const meta = await img.metadata();
      const { data, info } = await img.ensureAlpha().raw().toBuffer({ resolveWithObject: true });
      const n = info.width * info.height;
      const colors = new Set();
      let opaque = 0, semi = 0, clear = 0;
      // block-repeat test: fraction of pixels equal to right neighbour AND lower neighbour (detects upscaled pixel art)
      let eqR = 0, cmp = 0;
      for (let i = 0; i < n; i++) {
        const a = data[i * 4 + 3];
        if (a === 0) { clear++; continue; }
        if (a === 255) opaque++; else semi++;
        colors.add((data[i * 4] << 16) | (data[i * 4 + 1] << 8) | data[i * 4 + 2]);
        const x = i % info.width;
        if (x + 1 < info.width && data[(i + 1) * 4 + 3] > 0) {
          cmp++;
          if (data[i*4]===data[(i+1)*4] && data[i*4+1]===data[(i+1)*4+1] && data[i*4+2]===data[(i+1)*4+2]) eqR++;
        }
      }
      const vis = opaque + semi;
      console.log(`${f}\n  ${info.width}x${info.height}  visible=${vis}  uniqueRGB=${colors.size}  semiAlpha=${(100*semi/Math.max(vis,1)).toFixed(1)}%  sameAsRightNeighbour=${(100*eqR/Math.max(cmp,1)).toFixed(1)}%`);
    } catch (e) { console.log(f, 'ERR', e.message); }
  }
})();
