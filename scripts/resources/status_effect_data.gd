class_name StatusEffectData
extends Resource
## A status effect definition (Bleed, Burn, Curse, Blessed, Sleep, Stun…).
## Applying it again to a target that already has it refreshes its duration (no stacking).

enum Kind { BLEED, BURN, CURSE, BLESSED, SLEEP, STUN, TAUNT }

@export var id: StringName
@export var display_name: String = ""
@export var kind: Kind = Kind.BLEED
## HUD icon. Null for statuses shown as a text tag (see `tag_text`).
@export var icon: Texture2D
## Rounds the status lasts.
@export_range(1, 99) var duration_turns: int = 1
## When above `duration_turns`, the duration is rolled in [duration_turns, duration_turns_max].
@export_range(0, 99) var duration_turns_max: int = 0
## Damage per round as a fraction of max HP (0.05 = 5%).
@export_range(0.0, 1.0, 0.01) var dot_percent: float = 0.0
## Healing per round as a fraction of max HP.
@export_range(0.0, 1.0, 0.01) var regen_percent: float = 0.0
## The holder loses its turns while the status lasts.
@export var skip_turn: bool = false
## Multipliers applied to stats while active, e.g. `{&"attack": 0.75}`.
@export var stat_mult: Dictionary[StringName, float] = {}
## Multiplier on healing the holder receives (Curse: 0.5).
@export_range(0.0, 2.0, 0.05) var healing_received_mult: float = 1.0
## Opponents aim their single-target actions at the holder (Taunt, from Provoke).
@export var draws_attacks: bool = false
## Removed when the holder takes damage (Sleep).
@export var wears_off_on_hit: bool = false
## Element of the status. A target immune to a non-physical element is unaffected (Burn vs FIRE).
@export var element: Elements.Element = Elements.Element.PHYSICAL
## Short HUD tag for statuses without an icon, e.g. "SLP".
@export var tag_text: String = ""
@export var tag_color: Color = Color.WHITE
