# UI Asset Catalog

_Status: draft v1 (2026-11-13). Inventory of UI assets available today, a mapping of every required UI component to assets, and the gap list. Source zips stay untouched in `assests/`._

## 1. Licence records — UI asset packs

| Name | Creator | Source URL | Licence | Commercial use | Attribution | Format | Intended usage |
|---|---|---|---|---|---|---|---|
| Gimble's Dark Fantasy Kit Sampler (Free) v1.0 | Gimble's Games | https://gimblesgames.itch.io/ (full packs linked in its README) | Custom free licence (`LICENSE.txt` in zip) | **Yes**: personal and commercial; modify; ship inside game. **No:** redistribution as assets, AI/ML training, NFTs, claiming as own | Appreciated, not required ("Art by Gimble's Games") | PNG (1×/2×/4× copies), JSON, CSV, GPL/HEX palettes | **Primary UI kit**: panels, buttons, cursors, slots, item and status icons, portraits, battle backgrounds |
| dfgui UI kit (`All Assets.zip`) | **Unknown** | **Unknown** | **Unknown (no licence file)** | **Unknown: release blocker** | Unknown | PNG (1×) | Complements: MP/XP bar fills, command icons, round portrait frames, MENU button, map icons |

> ⚠ The Gimble's README states that its icons, portraits and backgrounds were made with **AI-assisted generation** and then cleaned up by hand. Record this for store disclosures (e.g. Steam).
> ⚠ dfgui must be **identified and licensed before any public build** (PROJECT_PLAN R2b, Q13).

## 2. File inventory

### Gimble's (used at 2×; `ui_index.json` holds 9-slice margins and hotspots for 1×)
| Group | Files | 1× size | Notes |
|---|---|---|---|
| Panels | `panel_iron_9slice`, `panel_iron_tooltip_9slice` | 128², 112² | 9-slice 16 / 8 px, **tile** middle |
| Buttons | `button_red_{normal,hover,pressed,disabled}_9slice` | 96×24 | Horizontal 9-slice 8 px; text band y 8–16 |
| Bars | `bar_frame_9slice`, `fill_red_segmented`, `fill_red_empty` | 96×12, 8×6 | Fill area inset 3 px, inner height 6 |
| Slots | `slot_normal_36x36`, `slot_selected_36x36` | 36² | For 32 px icons, offset 2,2 |
| Cursors | `cursor_gauntlet_16` (hotspot 5,0), `cursor_sword_16` (0,0) | 16² | Menu pointer and mouse cursor |
| Item icons | longsword, battle axe, longbow, iron helm, kite shield, health potion, mana potion, holy water, grimoire, soul gem, skull key, old map, silver stake, gold coins, torch | 32/64/128 | |

**SovDigital Inventory UI & Rarity Kit (added 2026-11-17, partial use).** HD painted, like the world sprites. Its panels, slots, tabs and rarity frames are **not** used: they would clash with the pixel UI layer (decision D6), and the kit has no buttons, bars, cursor or portraits. Extracted to `assets/vendor/sovdigital/inventory_ui/`:
- HD item icons (64/128 px, transparent): `flask-round-large` (**Minor Potion**, in use), `long-sword`, `ring-gold-ruby`, `key-gold`, `chest-open-gold`. Prefer these over the Gimble's icon for the same item; Gimble's covers the rest. Show them at their native size (no scaling).
- Equipment-slot silhouettes (64/128 px) for Phase 9: `main-hand` (Weapon), `off-hand` (Shield), `head` (Helm), `ring` / `amulet` (Accessory).
| HUD/status icons | bleeding, burning, cursed, blessed, fire, talk, locked, quest, health, gold | 32/64/128 | |
| Portraits | knight, witch hunter, witch, vampire lord, skeleton warrior, werewolf | 64/128/256 framed and transparent | |
| Battle backgrounds | haunted forest, graveyard | 320×180 native, up to 1920×1080 | True side view |
| Palette | `dark_fantasy_kit_icons_80`, `dark_fantasy_kit_portraits_64` | — | Source of `ART_GUIDELINES.md` §3 tokens |

### dfgui (used as ×2 nearest copies)
| Group | Files | 1× size |
|---|---|---|
| Party HUD atlas | `dfgui_partyhud.png`: portrait slot, name plate, bar frames (1 and 2 segments), red/purple/blue fills | 216×103 |
| Bar | `dfgui_foodbar.png` (green fill) | 125×15 |
| Icons | 25 × `dfgui_icon-*` (axe, cauldron, chat bubble, chest, clock, anvil, hammer, crown, fish, food, goblet, helmet, info, monster book, pickaxe, pouch, red book, settings, shield, shirt, shovel, skill book, sword, wand, wardrobe) | 26² |
| Buttons | `dfgui_button-{bag,empty,info,settings}`, `dfgui_smallbutton`, `dfgui_menubutton{,-hovered,-pressed}` ("MENU" baked in) | 26², 30², 69×18 |
| Frames | `dfgui_portraitframe` (round, gems), `dfgui_portraitframe2` (large runic ring) | 63×60, 116² |
| Map icons | `dfgui_mapicons.png` atlas: village, crypt, shrine, mine, ship, dog, party, "?", house, flag, scroll | 147×172 |

## 3. Required components → assets → gaps

| Component | Godot scene (planned) | Uses | Missing → fallback | Phase |
|---|---|---|---|---|
| **Main menu** | `scenes/ui/title_screen.tscn` | Gimble's buttons and panel; **live background** = in-engine necropolis night scene with fog (cheaper and more cohesive than a static image); title text in Cinzel | Title logo/wordmark → Cinzel text + gold rule ornament | 1 (stub), 7 (final) |
| **Pause menu** | `scenes/ui/pause_menu.tscn` | Gimble's panel, red buttons, gauntlet cursor, dfgui MENU button in HUD | Tab headers → Theme `TabBar` styled with `wood`/`bronze` StyleBoxFlat | 7 |
| **Dialogue box** | `scenes/ui/dialogue_box.tscn` | Gimble's panel, framed 256 px portrait, dfgui name plate (atlas), Alegreya/Cinzel | "Continue" indicator → gauntlet cursor rotated 90° with a 2-frame bob; choice list uses red buttons | 3 (simple), 7 (full) |
| **Character portraits** | `scenes/ui/widgets/portrait.tscn` | Gimble's 6 portraits; dfgui round frames for bestiary/boss | **NPC portraits (elder, merchant, villagers)** → reuse the closest Gimble's portrait or no portrait; full portrait pack later | 7, 10 |
| **Party HUD** | `scenes/battle/ui/battle_hud.tscn`, `scenes/ui/widgets/party_panel.tscn` | dfgui party-HUD atlas (slot, plate, bars), 128 px portraits, status icons | — | 5, 8 |
| **HP / MP bars** | `scenes/ui/widgets/stat_bar.tscn` | dfgui red/blue/purple fills + frames (party); Gimble's bar (enemies) | — | 5 |
| **Battle command menu** | `scenes/battle/ui/command_menu.tscn` | Gimble's panel, gauntlet cursor, dfgui icons (sword, skill book, wand, pouch, shield) | Flee icon → text only | 5 |
| **Inventory** | `scenes/ui/menus/inventory_page.tscn` | Gimble's slots + item icons, dfgui extra icons, tooltip panel | Category tabs, **scrollbar** → Theme StyleBoxFlat (`iron_edge`, `bronze`); item variety beyond 40 icons → reuse by category | 9 |
| **Equipment screen** | `scenes/ui/menus/equipment_page.tscn` | Slots, helm/shield/sword icons, stat-diff colours (`heal`/`blood`) | Body-armour icon; paper-doll silhouette → portrait + slot list (no paper doll) | 9 |
| **Character status** | `scenes/ui/menus/status_page.tscn` | Portrait, NumericLabel rows, XP bar, status icons | **Element icons** (fire/frost/lightning/holy/shadow) → coloured text tags; Gimble's `32_fire` for fire | 8 |
| **Quest journal** | `scenes/ui/menus/journal_page.tscn` | Panel, `51_quest` icon, dfgui red book icon, LoreLabel | **Worn parchment page texture** → panel with `parchment` text on `panel_slate` (no parchment page) until a parchment asset is sourced | 10 (built: dark panel, `51_quest` icon; no book icon) |
| **Map interface** | `scenes/ui/menus/map_page.tscn` | dfgui map icons, Gimble's `087_old_map` icon | **Map illustration** → auto-render: each map scene captured once into a `SubViewport` texture, desaturated and sepia-toned, with markers | 10 (built: `MapAtlas` capture in `user://map_cache`, `sepia.gdshader` with auto-exposure; icons party / flag / ? / shrine / crypt) |
| **Settings menu** | `scenes/ui/menus/settings_menu.tscn` | Panel, buttons | **Slider, checkbox, option button, scrollbar** → Theme StyleBoxFlat in palette tokens (grabber = `gold`, track = `iron_edge`) | 7 |
| **Save / load** | `scenes/ui/menus/save_load_menu.tscn` | Panel, slots, portraits, NumericLabel (play time, gold), `66_gold` icon | Slot thumbnails → screenshot captured at save time (`get_viewport().get_texture().get_image()`, downscaled to 320×180) | 11 |
| **Interaction prompt** | `scenes/world/components/interact_prompt.tscn` | Gimble's `39_talk` / `43_locked` / `51_quest` icons | — | 3 |
| **Damage popups** | `scenes/battle/ui/damage_popup.tscn` | DamageNumber type variation | — | 5 |

## 4. Gap list (to source; nothing will be downloaded by the assistant)

| Priority | Asset | Why | Suggested source |
|---|---|---|---|
| High | Worn parchment panel / page (9-slice) | Journal, lore, item descriptions ("worn parchment" is a stated reference) | Full Gimble's UI Kit (check contents), or another pixel UI kit in the same palette |
| High | Slider, checkbox, scrollbar, tab pieces | Settings, inventory | Full Gimble's UI Kit; fallback StyleBoxFlat |
| Medium | NPC portraits (elder, merchant, priest, villagers) | Dialogue identity | Full Gimble's Portraits pack |
| Medium | Element icons and Sleep/Stun icons | Status screen, battle HUD | Full Gimble's Status & HUD Icons pack |
| Medium | Aged-wood panel variant | Material variety (wood) | Full Gimble's UI Kit, or a recoloured tooltip panel |
| Low | Title wordmark / logo | Main menu | Commission, or Cinzel text treatment |
| Low | Region map illustration | Map interface | Auto-render fallback is acceptable |

## 5. Rules

- Every UI scene uses `main_theme.tres`. **No per-scene StyleBox or font overrides**; add a Theme type variation instead.
- Reusable widgets live in `scenes/ui/widgets/` (`stat_bar`, `portrait`, `item_slot`, `party_panel`, `icon_label`, `confirm_dialog`).
- Every new UI asset gets a row in §1 (pack level) and in `docs/asset_manifest.csv` (file level) before it is used.
