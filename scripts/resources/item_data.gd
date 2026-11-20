class_name ItemData
extends Resource
## An item (PROJECT_PLAN.md §5): a consumable, a key item, or (EquipmentData) a piece of gear.
## Kept by id in the Inventory; ids are file names under `data/items/` (and `data/equipment/`).
## Phase 9: WARD (Warding Torch), GOLD (coins turned into gold when picked up), NONE (key items,
## gear), an element for DAMAGE, and `foe_damage` for an ally item that also hurts a foe it is
## thrown at (Holy Water against the undead).

## Values are stored by number in the .tres files: only append.
enum Effect { HEAL_HP, HEAL_MP, CURE_STATUS, REVIVE, DAMAGE, WARD, GOLD, NONE }

@export var id: StringName
@export var display_name: String = ""
@export var icon: Texture2D
## Buying price. Sold for half (Shop.sell_price); 0 = cannot be sold.
@export_range(0, 99999) var price: int = 0
@export var usable_in_field: bool = true
@export var usable_in_battle: bool = true
## Kept in the Inventory's key-item list: never stacked, sold or used up.
@export var is_key_item: bool = false
@export var target_mode: Targeting.Mode = Targeting.Mode.ONE_ALLY
@export var effect: Effect = Effect.HEAL_HP
## HP/MP restored, damage dealt, HP after a revive, steps a WARD lasts, or gold per GOLD item.
@export_range(0, 9999) var amount: int = 0
## Statuses removed by CURE_STATUS (empty = all).
@export var cures: Array[StatusEffectData] = []
## Element of DAMAGE and of `foe_damage`.
@export var element: Elements.Element = Elements.Element.PHYSICAL
## When > 0, the item can also be used on one enemy in battle: it deals this much damage of
## `element` (× the foe's affinity) instead of its usual effect.
@export_range(0, 9999) var foe_damage: int = 0
## WARD: the encounter-rate multiplier added for `amount` steps.
@export_range(0.0, 1.0, 0.05) var ward_mult: float = 1.0
## Effect the battle presenter plays on each target when the item is used (null = none).
@export var impact_fx: FxSpec
## Played as it is used (on the cast animation for spells).
@export var cast_sfx: SfxSet
## Played on each target as it lands, with `impact_fx` (null = the default hit sound).
@export var impact_sfx: SfxSet
@export_multiline var description: String = ""


## Gear (an EquipmentData).
func is_equipment() -> bool:
	return false


## Used up when used (not gear, not a key item, and it does something).
func is_consumable() -> bool:
	return not is_key_item and not is_equipment() and effect != Effect.NONE


## Can be aimed at one enemy in battle (DAMAGE items, and items with `foe_damage`).
func can_target_foes() -> bool:
	return effect == Effect.DAMAGE or foe_damage > 0
