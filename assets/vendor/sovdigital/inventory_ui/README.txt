Free Inventory UI & Rarity Kit  -  version 1.0.0

A free, ready-made inventory and rarity set in our top-down HD style: slot frames in every state, equipment slots,
panels, tooltip and hotbar plates, durability and cooldown meters, and rarity tiles in 7 tiers, plus a small Godot 4
inventory demo with drag and drop and rarity tooltips. Works with every icon in our item icon packs.

RARITY (7 tiers in the colours players know)
  poor (grey) - common (white) - uncommon (green) - rare (blue) - epic (purple) - legendary (orange-gold) - mythic (red)
  frames/rarity/<tier>/rarity_<tier>_<background|ring|glow>_<square|round>_<size>.png   layers to stack under and over an icon
  Legendary and mythic also carry an 8-frame shimmer strip (128 px). Tiers read by shape too: 0 to 6 gems on the bottom edge.

UI
  ui/slots/slot_<empty|hover|selected|disabled|locked|new>_<size>.png       256/128/64
  ui/equipment/equip_<slot>_<size>.png   head, chest, hands, legs, feet, ring, amulet, main-hand, off-hand, belt
  ui/panels/*.png + slices.json          9-slice plates: inventory, hotbar, tooltip, tab active/inactive, scrollbar
  ui/meters/                             durability bar frame and fills; cooldown wedge as a 12-frame strip
  icons/<icon>/                          8 demo icons (square and transparent, 128/64 px)

GODOT 4
  godot/rarity_shimmer.gdshader, godot/cooldown_radial.gdshader   canvas_item shaders (MIT-0 licence)
  example/inventory_demo.tscn + .gd + slot.gd                     drop this folder into any Godot 4 project and run the
                                                                   scene; scripts are MIT-0. No project.godot inside.

All files are PNG with alpha (or Godot text files). Names are lowercase with hyphens.

MORE
  The full item icon packs: Weapon Icons, Fantasy Items & Loot, Crafting, Tools & Resources, Modern & Sci-Fi Gear,
  and the Icons Set with all of them.
