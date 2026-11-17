class_name ItemData
extends Resource
## A consumable item (Phase 4: minimal; equipment extends it in Phase 9).

enum Effect { HEAL_HP, HEAL_MP, CURE_STATUS, REVIVE, DAMAGE }

@export var id: StringName
@export var display_name: String = ""
@export var icon: Texture2D
@export_range(0, 99999) var price: int = 0
@export var usable_in_field: bool = true
@export var usable_in_battle: bool = true
@export var target_mode: Targeting.Mode = Targeting.Mode.ONE_ALLY
@export var effect: Effect = Effect.HEAL_HP
## HP/MP restored, damage dealt, or HP after a revive.
@export_range(0, 9999) var amount: int = 0
## Statuses removed by CURE_STATUS (empty = all).
@export var cures: Array[StatusEffectData] = []
## Effect the battle presenter plays on each target when the item is used (null = none).
@export var impact_fx: FxSpec
## Played as it is used (on the cast animation for spells).
@export var cast_sfx: SfxSet
## Played on each target as it lands, with `impact_fx` (null = the default hit sound).
@export var impact_sfx: SfxSet
@export_multiline var description: String = ""
