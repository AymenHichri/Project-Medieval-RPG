// Approximate in-game battle composition: Gimble's graveyard bg + SovDigital battlers at battle_scale 1.2
const sharp = require('sharp');
const V = '/mnt/c/Users/AymenH/Desktop/RPG/assets/vendor/';
const out = process.argv[2];
async function frame(p, row, w, h, s) {
  const b = await sharp(V + p).extract({ left: 0, top: row * h, width: w, height: h }).png().toBuffer();
  return sharp(b).resize(Math.round(w * s), Math.round(h * s), { kernel: 'lanczos3' }).png().toBuffer();
}
(async () => {
  const K = 'sovdigital/knight/', E = 2, W = 6, s = 1.2;
  const kn = await frame(K + 'characters/knight/sheets/idle.png', E, 232, 246, s);
  const kb = await frame(K + 'ColourVariations/black/knight/sheets/idle.png', E, 232, 246, s);
  const kg = await frame(K + 'ColourVariations/gold/knight/sheets/idle.png', E, 232, 246, s);
  const sk = await frame('sovdigital/skeleton/characters/skeleton/sheets/idle.png', W, 226, 222, s);
  const wf = await frame('sovdigital/wolf/characters/wolf/sheets/idle.png', W, 244, 220, s);
  await sharp(V + 'gimbles/backgrounds/1920x1080/08_graveyard.png').composite([
    { input: kn, left: 330, top: 560 }, { input: kb, left: 210, top: 680 }, { input: kg, left: 430, top: 700 },
    { input: sk, left: 1380, top: 560 }, { input: wf, left: 1300, top: 700 },
  ]).resize(1920, 1080).png().toFile(out);
  console.log('wrote', out);
})();
