// Build a labelled contact sheet.
// Usage: node sheet.js out.png cellW cellH cols bg "label|path|crop(x,y,w,h)|scale|kernel" ...
// crop and scale optional; kernel = nearest|lanczos3. Images are fitted into cell (contain) unless scale given.
const sharp = require('sharp');
const [out, cw, ch, cols, bg, ...items] = process.argv.slice(2);
const CW = +cw, CH = +ch, COLS = +cols, LBL = 22;
(async () => {
  const rows = Math.ceil(items.length / COLS);
  const W = CW * COLS, H = (CH + LBL) * rows;
  const comps = [];
  for (let i = 0; i < items.length; i++) {
    const [label, p, crop, scale, kernel] = items[i].split('|');
    let img = sharp(p);
    if (crop) { const [x, y, w, h] = crop.split(',').map(Number); img = img.extract({ left: x, top: y, width: w, height: h }); }
    let buf = await img.png().toBuffer();
    const k = kernel === 'lanczos3' ? 'lanczos3' : 'nearest';
    if (scale) {
      const m = await sharp(buf).metadata();
      buf = await sharp(buf).resize(Math.round(m.width * +scale), Math.round(m.height * +scale), { kernel: k }).png().toBuffer();
    }
    let m = await sharp(buf).metadata();
    if (m.width > CW - 8 || m.height > CH - 8) {
      buf = await sharp(buf).resize(CW - 8, CH - 8, { fit: 'inside', kernel: k }).png().toBuffer();
      m = await sharp(buf).metadata();
    }
    const cx = (i % COLS) * CW, cy = Math.floor(i / COLS) * (CH + LBL);
    comps.push({ input: buf, left: cx + Math.floor((CW - m.width) / 2), top: cy + LBL + Math.floor((CH - m.height) / 2) });
    const esc = label.replace(/&/g, '&amp;').replace(/</g, '&lt;');
    comps.push({ input: Buffer.from(`<svg width="${CW}" height="${LBL}"><text x="6" y="16" font-family="monospace" font-size="13" fill="#ddd">${esc}</text></svg>`), left: cx, top: cy });
  }
  await sharp({ create: { width: W, height: H, channels: 4, background: bg } }).composite(comps).png().toFile(out);
  console.log('wrote', out, W + 'x' + H);
})();
