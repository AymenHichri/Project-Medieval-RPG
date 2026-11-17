// Greyscale composition block-ins for image generators (img2img / layout / depth guidance).
// Values: darker = nearer/denser. Usage: node layouts.js <outDir>
const sharp = require('sharp');
const path = require('path');
const out = process.argv[2];
const svg = (w, h, body) => Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${body}</svg>`);
const label = (x, y, t, s = 22) => `<text x="${x}" y="${y}" font-family="monospace" font-size="${s}" fill="#e33">${t}</text>`;

const L = {
  // ---------- 1. COVER 2:3 ----------
  cover: [1440, 2160, (lbl) => `
  <rect width="1440" height="2160" fill="#2b2b2e"/>
  <!-- entity mass in the sky -->
  <ellipse cx="760" cy="620" rx="760" ry="640" fill="#1c1c1f"/>
  <!-- eclipse / pupil -->
  <circle cx="790" cy="560" r="150" fill="#d8c070"/><circle cx="790" cy="560" r="138" fill="#050505"/>
  <!-- ring of half-closed lids -->
  ${Array.from({ length: 14 }, (_, i) => { const a = i / 14 * Math.PI * 2, r = 380; return `<ellipse cx="${790 + Math.cos(a) * r}" cy="${560 + Math.sin(a) * r * 0.8}" rx="34" ry="9" fill="#6a6a6a" transform="rotate(${a * 57.3 + 90} ${790 + Math.cos(a) * r} ${560 + Math.sin(a) * r * 0.8})"/>`; }).join('')}
  <!-- hanging forms descending behind towers -->
  ${[300, 430, 560, 1010, 1140, 1260].map((x, i) => `<path d="M${x} 900 Q ${x + 30} 1200 ${x - 10 + i * 4} ${1350 + (i % 3) * 60}" stroke="#151517" stroke-width="${26 - i * 2}" fill="none"/>`).join('')}
  <!-- fog band -->
  <rect x="0" y="1300" width="1440" height="180" fill="#4a4a4d" opacity="0.8"/>
  <!-- cathedral -->
  <rect x="380" y="1180" width="680" height="640" fill="#0f0f10"/>
  <polygon points="380,1180 720,960 1060,1180" fill="#0f0f10"/>
  <rect x="300" y="820" width="170" height="1000" fill="#0c0c0d"/><polygon points="300,820 385,560 470,820" fill="#0c0c0d"/>
  <rect x="970" y="900" width="170" height="920" fill="#0c0c0d"/><polygon points="970,900 1010,780 1060,840 1140,900" fill="#0c0c0d"/>
  <circle cx="720" cy="1250" r="90" fill="#3a1212"/>
  <path d="M650 1820 L650 1560 Q720 1470 790 1560 L790 1820Z" fill="#050505"/>
  <!-- road + tiny figure + lantern -->
  <polygon points="620,2160 820,2160 760,1820 680,1820" fill="#232325"/>
  <rect x="712" y="1930" width="14" height="44" fill="#000"/><circle cx="732" cy="1950" r="6" fill="#ff9a3c"/>
  <!-- foreground fence / headstones -->
  <rect x="0" y="2020" width="1440" height="140" fill="#060606"/>
  ${Array.from({ length: 18 }, (_, i) => `<polygon points="${i * 82},2040 ${i * 82 + 6},1940 ${i * 82 + 12},2040" fill="#060606"/>`).join('')}
  <path d="M60 2040 v-120 q60 -50 120 0 v120z M1240 2040 v-90 q50 -40 100 0 v90z" fill="#060606"/>
  ${lbl ? label(30, 60, 'COVER 2:3 - entity behind/above, eclipse = its pupil, NO text') + label(860, 380, 'eclipse w/ pale-gold corona') + label(60, 1280, 'hanging forms (fingers/roots/ribs) into fog') + label(820, 1260, 'faint crimson rose window') + label(760, 1990, '&lt;- tiny figure + lantern (only warm light)') + label(30, 1440, 'fog band') : ''}`],

  // ---------- 2. PARTY 16:9 ----------
  party: [1920, 1080, (lbl) => `
  <rect width="1920" height="1080" fill="#1b1b1d"/>
  <!-- ruined crypt walls / arches -->
  <rect x="0" y="0" width="1920" height="560" fill="#262628"/>
  ${[160, 620, 1080, 1540].map(x => `<path d="M${x} 560 V260 Q${x + 120} 120 ${x + 240} 260 V560Z" fill="#141415"/>`).join('')}
  <rect x="0" y="560" width="1920" height="520" fill="#2e2e30"/>
  <!-- fire glow -->
  <ellipse cx="820" cy="760" rx="420" ry="230" fill="#5a4a3a" opacity="0.55"/><circle cx="820" cy="740" r="40" fill="#ffb060"/>
  <!-- figures (seated/standing, apart) -->
  <rect x="200" y="420" width="90" height="300" fill="#0b0b0b"/>   <!-- cautious, standing at edge, looking away -->
  <rect x="520" y="600" width="130" height="190" fill="#0b0b0b"/>  <!-- hardened, seated cleaning sword -->
  <rect x="1500" y="470" width="100" height="280" fill="#080808"/> <!-- untrustworthy, in shadow beyond fire -->
  <rect x="1220" y="610" width="150" height="160" fill="#0b0b0b"/> <!-- exhausted, slumped vs pillar -->
  <rect x="930" y="630" width="110" height="170" fill="#0b0b0b"/>  <!-- unnatural, closest to fire -->
  <path d="M985 800 L1300 1040 L1180 1060Z" fill="#000" opacity="0.7"/> <!-- wrong shadow -->
  ${lbl ? label(30, 40, 'PARTY 16:9 - five figures APART, none facing viewer, one small fire') + label(160, 400, 'cautious: watching the dark') + label(470, 590, 'hardened: cleans notched sword') + label(1420, 450, 'untrustworthy: hooded, in shadow') + label(1180, 600, 'exhausted: slumped, helm off') + label(880, 620, 'unnatural: wrong shadow') : ''}`],

  // ---------- 3. BATTLE 16:9 ----------
  battle: [1920, 1080, (lbl) => `
  <rect width="1920" height="1080" fill="#1a1a1c"/>
  <!-- nave pillars receding -->
  ${[0, 1, 2, 3, 4].map(i => `<rect x="${120 + i * 150}" y="${80 + i * 40}" width="${110 - i * 14}" height="${520 - i * 40}" fill="#${(0x20 + i * 8).toString(16).repeat(3)}"/><rect x="${1690 - i * 150}" y="${80 + i * 40}" width="${110 - i * 14}" height="${520 - i * 40}" fill="#${(0x20 + i * 8).toString(16).repeat(3)}"/>`).join('')}
  <!-- altar + headless statue -->
  <rect x="890" y="300" width="140" height="260" fill="#333"/><rect x="840" y="540" width="240" height="60" fill="#3a3a3a"/>
  <!-- light shafts onto empty centre -->
  <polygon points="860,0 1060,0 1180,1080 740,1080" fill="#6a6a70" opacity="0.35"/>
  <!-- floor band -->
  <rect x="0" y="600" width="1920" height="480" fill="#2c2c2e" opacity="0.9"/>
  <!-- party left (E-facing) -->
  ${[[250, 640], [420, 700], [210, 790], [400, 840]].map(([x, y]) => `<rect x="${x}" y="${y}" width="90" height="190" fill="#0a0a0a"/>`).join('')}
  <!-- enemy right: fused congregation mass -->
  <path d="M1380 1000 Q1320 700 1430 460 Q1500 300 1540 160 Q1580 300 1650 460 Q1760 700 1700 1000Z" fill="#070707"/>
  <ellipse cx="1540" cy="150" rx="40" ry="60" fill="#b8b4a8"/>
  ${[[1390, 560], [1680, 520], [1360, 760], [1720, 700], [1450, 380]].map(([x, y]) => `<line x1="1540" y1="${y}" x2="${x}" y2="${y + 60}" stroke="#070707" stroke-width="22"/><circle cx="${x}" cy="${y + 80}" r="16" fill="#c03030"/>`).join('')}
  ${lbl ? label(30, 40, 'BATTLE 16:9 - side view, party left, enemy right, NO UI') + label(180, 620, 'party (3-4), profile facing right') + label(1300, 140, 'faceless pale head too high') + label(1220, 1040, 'fused bodies in one cassock, censers glow red') + label(800, 1040, 'brightest = empty space between') : ''}`],

  // ---------- 4. EXPLORATION 16:9 (top-down 3/4) ----------
  exploration: [1920, 1080, (lbl) => `
  <rect width="1920" height="1080" fill="#3a3a3a"/>
  <!-- mud street running up to chapel -->
  <polygon points="760,1080 1160,1080 1060,330 860,330" fill="#2c2a26"/>
  <!-- chapel at top -->
  <rect x="700" y="40" width="520" height="290" fill="#151515"/><polygon points="760,40 960,-80 1160,40" fill="#151515"/>
  <rect x="930" y="230" width="60" height="100" fill="#000"/>
  <!-- cottages along the street -->
  ${[[180, 120], [140, 520], [1400, 180], [1450, 600]].map(([x, y], i) => `<rect x="${x}" y="${y}" width="${300 - i * 10}" height="${240}" fill="#${i % 2 ? '1d1d1d' : '232323'}"/>`).join('')}
  <!-- square with statues facing chapel -->
  <circle cx="960" cy="640" r="150" fill="#444" opacity="0.6"/>
  ${[[860, 600], [1060, 600], [900, 720], [1020, 720]].map(([x, y]) => `<rect x="${x - 15}" y="${y - 40}" width="30" height="60" fill="#666"/>`).join('')}
  <!-- tree, cart, drag marks -->
  <circle cx="1300" cy="880" r="110" fill="#0e0e0e"/>
  <rect x="620" y="840" width="120" height="70" fill="#1b140f"/>
  <path d="M700 880 Q820 700 950 420" stroke="#1a1714" stroke-width="10" fill="none" stroke-dasharray="20 10"/>
  <!-- adventurer + lantern -->
  <rect x="955" y="905" width="26" height="54" fill="#000"/><circle cx="992" cy="922" r="10" fill="#ff9a3c"/>
  <!-- fog edges -->
  <rect x="0" y="0" width="1920" height="1080" fill="none" stroke="#777" stroke-width="120" opacity="0.35"/>
  ${lbl ? label(30, 40, 'EXPLORATION 16:9 - top-down 3/4 camera like the tiles') + label(1230, 140, 'abandoned chapel') + label(1080, 560, 'statues all turned to face chapel') + label(560, 950, 'abandoned cart, spilled') + label(1010, 960, 'adventurer + lantern') + label(720, 760, 'drag marks') : ''}`],

  // ---------- 5. DEAD GODS 16:9 ----------
  deadgods: [1920, 1080, (lbl) => `
  <rect width="1920" height="1080" fill="#2a2a2d"/>
  <!-- far cavern wall silhouette -->
  <path d="M0 0 H1920 V380 Q1500 300 1100 360 Q600 420 0 340Z" fill="#1d1d20"/>
  <!-- stalactite fingers -->
  ${[700, 860, 1040, 1220, 1400, 1580].map((x, i) => `<polygon points="${x - 30},0 ${x + 30},0 ${x + 6},${260 + (i % 3) * 70}" fill="#141416"/>`).join('')}
  <!-- ribcage = flying buttresses -->
  ${Array.from({ length: 7 }, (_, i) => `<path d="M${780 + i * 150} 1000 Q ${720 + i * 150} 520 ${1180 + i * 40} ${330 + i * 10}" stroke="#121214" stroke-width="${46 - i * 3}" fill="none"/>`).join('')}
  <!-- membranes -->
  <path d="M900 900 Q1000 700 1100 900 Q1200 720 1300 900" fill="#3a1e1a" opacity="0.7"/>
  <!-- facade face, dead rose-window eye -->
  <rect x="1500" y="300" width="300" height="420" fill="#101012"/><circle cx="1650" cy="420" r="70" fill="#2e2e30"/>
  <!-- glowing crack -->
  <path d="M1250 560 L1270 620 L1255 680 L1280 760" stroke="#e0b860" stroke-width="6" fill="none"/>
  <!-- stair from lower left + tiny explorer -->
  <polygon points="0,1080 520,1080 420,760 300,760" fill="#0c0c0d"/>
  <rect x="352" y="742" width="10" height="22" fill="#000"/><circle cx="366" cy="748" r="4" fill="#ff9a3c"/>
  <!-- cold shrines -->
  ${[[600, 960], [680, 990], [760, 975]].map(([x, y]) => `<rect x="${x}" y="${y - 30}" width="24" height="30" fill="#555"/>`).join('')}
  ${lbl ? label(30, 40, 'DEAD GODS 16:9 - remains fused into architecture') + label(1100, 300, 'ribs = gothic flying buttresses') + label(1480, 290, 'facade face, rose-window dead eye') + label(1290, 640, 'crack seeping pale gold') + label(250, 730, 'tiny explorer on stair') + label(560, 920, 'cold shrines left by worshippers') : ''}`],
};

(async () => {
  for (const [name, [w, h, f]] of Object.entries(L)) {
    await sharp(svg(w, h, f(true))).png().toFile(path.join(out, `layout_${name}_annotated.png`));
    await sharp(svg(w, h, f(false))).greyscale().blur(6).png().toFile(path.join(out, `layout_${name}_clean.png`));
    console.log('wrote', name);
  }
})();
