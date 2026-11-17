// Builds unlabeled style-reference boards for image generators (Option B: SovDigital painted HD style).
// Usage: node genref.js <outDir>   (needs `sharp`; run from anywhere)
const sharp = require('sharp');
const path = require('path');
const V = '/mnt/c/Users/AymenH/Desktop/RPG/assets/vendor/sovdigital/';
const out = process.argv[2];
const BG = '#121214';

async function load(p, crop, scale = 1) {
  let img = sharp(V + p);
  if (crop) img = img.extract({ left: crop[0], top: crop[1], width: crop[2], height: crop[3] });
  let buf = await img.png().toBuffer();
  if (scale !== 1) {
    const m = await sharp(buf).metadata();
    buf = await sharp(buf).resize(Math.round(m.width * scale), Math.round(m.height * scale), { kernel: 'lanczos3' }).png().toBuffer();
  }
  return sharp(buf).trim({ threshold: 1 }).png().toBuffer().catch(() => buf);
}
async function fit(buf, w, h) {
  return sharp(buf).resize(w, h, { fit: 'inside', withoutEnlargement: false, kernel: 'lanczos3' }).png().toBuffer();
}
async function grid(file, W, H, cols, rows, items) {
  const cw = Math.floor(W / cols), ch = Math.floor(H / rows), comps = [];
  for (let i = 0; i < items.length; i++) {
    const b = await fit(items[i], cw - 24, ch - 24);
    const m = await sharp(b).metadata();
    comps.push({ input: b, left: (i % cols) * cw + Math.floor((cw - m.width) / 2), top: Math.floor(i / cols) * ch + Math.floor((ch - m.height) / 2) });
  }
  await sharp({ create: { width: W, height: H, channels: 4, background: BG } }).composite(comps).png().toFile(path.join(out, file));
  console.log('wrote', file);
}

(async () => {
  const N = 'necropolis/', NA = 'necropolis/ColourVariations/ash/';
  // 1. Architecture & props
  await grid('ref_A_architecture.png', 2048, 1366, 4, 3, [
    await load(NA + 'buildings/crypt-barracks.png'),
    await load(N + 'buildings/crypt-barracks-ruined.png'),
    await load('necropolis/ColourVariations/frost/buildings/crypt-barracks.png'),
    await load('village/ColourVariations/slate/buildings/cottage-ruined.png'),
    await load(N + 'props/setpieces/gargoyle-plinth.png'),
    await load(N + 'props/setpieces/small-obelisk.png'),
    await load(N + 'walls/wall-north.png'),
    await load('castle_courtyard/ColourVariations/ash/walls/curtain-wall.png'),
    await load(N + 'props/setpieces/gnarled-tree.png'),
    await load(N + 'props/setpieces/lantern-post.png'),
    await load(N + 'props/setpieces/iron-fence.png'),
    await load(N + 'props/setpieces/headstone-cross.png'),
  ]);
  // 2. Characters & creatures (E = row 2, SE = row 1, W = row 6)
  const K = 'knight/', s = 2;
  await grid('ref_B_characters.png', 2048, 1366, 4, 2, [
    await load(K + 'characters/knight/sheets/idle.png', [0, 492, 232, 246], s),
    await load(K + 'ColourVariations/black/knight/sheets/idle.png', [0, 246, 232, 246], s),
    await load(K + 'characters/knight/sheets/attack.png', [696, 492, 232, 246], s),
    await load('wolf/ColourVariations/black/wolf/sheets/idle.png', [0, 1320, 244, 220], s),
    await load('skeleton/characters/skeleton/sheets/idle.png', [0, 1332, 226, 222], s),
    await load('skeleton/ColourVariations/charred/skeleton/sheets/idle.png', [0, 1332, 226, 222], s),
    await load('blade_assassin/characters/blade-assassin/sheets/idle.png', [0, 2166, 415, 361], s),
    await load('blade_assassin/characters/blade-assassin-phase-two/sheets/idle.png', [0, 2532, 547, 422], s),
  ]);
  // 3. Materials (ground textures, 1:1 crops)
  await grid('ref_C_materials.png', 2048, 1024, 4, 2, [
    await load(N + 'grounds/bone-flags/bone-flags.png', [0, 0, 512, 512]),
    await load(N + 'grounds/ash-soil/ash-soil.png', [0, 0, 512, 512]),
    await load('castle_courtyard/ColourVariations/ash/grounds/courtyard-flagstones/courtyard-flagstones.png', [0, 0, 512, 512]),
    await load('village/ColourVariations/ash/grounds/mud-street/mud-street.png', [0, 0, 512, 512]),
    await load(NA + 'buildings/crypt-barracks.png', [150, 180, 260, 200], 2),
    await load('castle_courtyard/ColourVariations/ash/walls/curtain-wall.png', [0, 60, 256, 185], 2),
    await load(N + 'props/setpieces/gargoyle-plinth.png', [0, 0, 124, 100], 3),
    await load(K + 'characters/knight/sheets/idle.png', [70, 530, 100, 100], 4),
  ]);
  // 4. Palette swatch (measured from the ash/default world assets)
  const pal = ['#080808','#121214','#191919','#2a2a2a','#3b3b3b','#4c4c4c','#5d5d5d','#7d7f83',
               '#2a2a19','#3b3b2a','#4c4c3b','#3b2a2a','#5d4c4c','#3b2a19','#4c3b2a','#6e4c2a',
               '#c3904c','#bcbaaf','#d5c8b3','#dcae4f','#a47b4f','#5d201d','#8c2821','#bb322c'];
  const sw = 256, comps = [];
  pal.forEach((c, i) => comps.push({ input: Buffer.from(`<svg width="${sw}" height="${sw}"><rect width="${sw}" height="${sw - 40}" fill="${c}"/><text x="10" y="${sw - 12}" font-family="monospace" font-size="24" fill="#ccc">${c}</text></svg>`), left: (i % 8) * sw, top: Math.floor(i / 8) * sw }));
  await sharp({ create: { width: sw * 8, height: sw * 3, channels: 4, background: BG } }).composite(comps).png().toFile(path.join(out, 'ref_D_palette.png'));
  console.log('wrote ref_D_palette.png');

  // 5. In-game look: a small necropolis scene built from real tiles (exploration reference)
  const ground = await sharp(V + 'necropolis/ColourVariations/ash/grounds/ash-soil/ash-soil.png').resize(1080, 1080).png().toBuffer();
  const place = async (p, x, y, sc = 1, crop) => ({ input: await load(p, crop, sc), left: x, top: y });
  const scene = [
    { input: ground, left: 0, top: 0 }, { input: ground, left: 840, top: 0 },
    await place(NA + 'buildings/crypt-barracks.png', 700, 40, 1),
    await place('village/ColourVariations/ash/buildings/cottage-ruined.png', 60, 120, 0.85),
    await place('village/ColourVariations/slate/buildings/cottage-damaged.png', 1400, 160, 0.8),
    await place(N + 'props/setpieces/gnarled-tree.png', 1250, 520, 1),
    await place(N + 'props/setpieces/gargoyle-plinth.png', 620, 520, 1),
    await place(N + 'props/setpieces/small-obelisk.png', 1180, 470, 1),
    await place(N + 'props/setpieces/headstone-cross.png', 300, 700, 1),
    await place(N + 'props/setpieces/headstone-round.png', 420, 760, 1),
    await place(N + 'props/setpieces/burial-cart.png', 1500, 760, 0.9),
    await place(N + 'props/setpieces/lantern-post.png', 900, 560, 1),
    await place(K + 'characters/knight/sheets/walk.png', 960, 700, 1, [0, 1968 / 8 * 3, 232, 246]),
  ];
  await sharp({ create: { width: 1920, height: 1080, channels: 4, background: BG } })
    .composite(scene).png().toFile(path.join(out, 'ref_E_ingame_scene.png'));
  console.log('wrote ref_E_ingame_scene.png');
})();
