class_name CombatantVisual
extends Resource
## How a combatant is drawn in battle (read by BattleSprite; may be null in tests).
## Logical animations (PROJECT_PLAN.md §6.3): idle, move, attack, skill, cast, hurt, death, plus
## per-move keys named by `SkillData.anim_key` (e.g. whirlwind). A logical animation that is not
## mapped falls back to a stand-in (see BattleSprite.STAND_INS).

## Injured idles used when `injured_idles` is empty: the vendor's half and quarter health idles.
const DEFAULT_INJURED_IDLES: Dictionary[StringName, float] = {&"idle_hp50": 0.5, &"idle_hp25": 0.25}

@export var sprite_frames: SpriteFrames
## Scale of the sprite on the battlefield.
@export var battle_scale: float = 1.0
## Sprite offset that puts the vendor feet pivot on the node origin (frames are centred).
@export var offset: Vector2 = Vector2.ZERO
## Facing row of the vendor animations: &"E" for the party, &"W" for enemies.
@export var facing: StringName = &"W"
## Logical animation → vendor animation name, e.g. `{&"attack": &"attack_E"}`.
@export var anim_map: Dictionary[StringName, StringName] = {}
## Logical animations stored in another SpriteFrames (vendor move sheets such as Whirlwind).
## Their cells are centred on the base cell, so `offset` still applies.
@export var move_frames: Dictionary[StringName, SpriteFrames] = {}
## Frame of the attack animation on which damage is shown.
@export var hit_frame: int = 0
## Hit frame of other logical animations (a missing entry = the animation's last frame).
@export var hit_frames: Dictionary[StringName, int] = {}
## Play a logical animation only up to this frame, then hold it (Knight cast = Charged Strike 0–6).
@export var last_frames: Dictionary[StringName, int] = {}
## Visible height above the feet at scale 1 (px): places HP bars, popups and the target cursor.
@export var height: float = 150.0
## Effect played on this combatant when a physical blow lands (blood, sparks; null = none).
@export var hit_fx: FxSpec
## Injured idles (Phase 10): logical idle animation → HP fraction at or below which it replaces
## `idle` (the lowest matching fraction wins). Empty = `DEFAULT_INJURED_IDLES`. A boss form that
## ends at half HP uses its own fractions so both injured idles are seen before it changes.
@export var injured_idles: Dictionary[StringName, float] = {}
## Effect played on this combatant when it appears (a boss's blink arrival; null = none).
@export var entrance_fx: FxSpec
## Effect played on this combatant when it takes this form (a boss's phase change; null = none).
@export var phase_fx: FxSpec

@export_group("Sounds")
## Played as this combatant swings (Attack and melee skills).
@export var attack_sfx: SfxSet
## Played on this combatant when a physical blow lands (flesh, bone, metal).
@export var hit_sfx: SfxSet
## This combatant's cry: when it appears and when it changes phase.
@export var cry_sfx: SfxSet
## Played when it falls.
@export var death_sfx: SfxSet


## The resting animation for a combatant at `hp_ratio` of its max HP: the mapped injured idle
## with the lowest fraction it is at or below, else `idle`.
func idle_for(hp_ratio: float) -> StringName:
	var thresholds: Dictionary[StringName, float] = injured_idles if not injured_idles.is_empty() else DEFAULT_INJURED_IDLES
	var best: StringName = &"idle"
	var best_fraction: float = 2.0
	for anim: StringName in thresholds:
		var fraction: float = thresholds[anim]
		if hp_ratio <= fraction and fraction < best_fraction and has_animation(anim):
			best = anim
			best_fraction = fraction
	return best


## The SpriteFrames that hold logical animation `anim` (null if the visual has none).
func frames_for(anim: StringName) -> SpriteFrames:
	return move_frames.get(anim, sprite_frames) as SpriteFrames


## The vendor animation name for `anim`, or &"" when it is not mapped or missing from its frames.
func animation_for(anim: StringName) -> StringName:
	var vendor_name: StringName = anim_map.get(anim, &"") as StringName
	var frames: SpriteFrames = frames_for(anim)
	if vendor_name == &"" or frames == null or not frames.has_animation(vendor_name):
		return &""
	return vendor_name


func has_animation(anim: StringName) -> bool:
	return animation_for(anim) != &""


## Frame of `anim` on which its hit lands, clamped to the animation's length.
func hit_frame_for(anim: StringName) -> int:
	var vendor_name: StringName = animation_for(anim)
	if vendor_name == &"":
		return 0
	var count: int = frames_for(anim).get_frame_count(vendor_name)
	var frame: int = hit_frame if anim == &"attack" else (hit_frames.get(anim, count - 1) as int)
	return clampi(frame, 0, count - 1)
