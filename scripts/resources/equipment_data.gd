class_name EquipmentData
extends ItemData
## A piece of gear (PROJECT_PLAN.md §6.4, Phase 9). It sits in the Inventory like any item until a
## PartyMember equips it in the slot of its `category`. While worn, its bonuses join the wearer's
## stats on demand (Combatant.stat), its `resist` multiplies the wearer's affinities, a weapon's
## `attack_element` is the element of plain attacks, and `encounter_rate_mult` joins the
## random-encounter rate. Read-only at runtime.

## The four equipment slots, one item each (no body armour yet: no icon in the kits).
enum Category { WEAPON, SHIELD, HELM, ACCESSORY }

@export var category: Category = Category.WEAPON
## Added to the wearer's stats (null = none).
@export var stat_bonus: StatBlock
## Element of the wearer's plain attacks (weapons only; PHYSICAL = none).
@export var attack_element: Elements.Element = Elements.Element.PHYSICAL
## Damage multipliers the wearer takes, by element (0.5 = resist); multiplied with the others.
@export var resist: Dictionary[Elements.Element, float] = {}
## Multiplies the random-encounter rate while worn (1.0 = no change).
@export_range(0.0, 2.0, 0.05) var encounter_rate_mult: float = 1.0


func _init() -> void:
	usable_in_field = false
	usable_in_battle = false
	effect = Effect.NONE


func is_equipment() -> bool:
	return true


## The bonus to one stat (0 when there is no StatBlock).
func bonus(stat: StringName) -> int:
	return stat_bonus.get_stat(stat) if stat_bonus != null else 0


## Display name of a category ("Weapon").
static func category_name(value: Category) -> String:
	return (Category.keys()[value] as String).capitalize()
