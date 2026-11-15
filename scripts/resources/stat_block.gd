class_name StatBlock
extends Resource
## The eight core stats of a character or enemy. Read-only at runtime (see Combatant).

## Names accepted by `get_stat()` and `Combatant.effective_stat()`.
const NAMES: Array[StringName] = [
	&"max_hp", &"max_mp", &"attack", &"defense", &"magic", &"spirit", &"agility", &"luck"]

@export var max_hp: int = 1
@export var max_mp: int = 0
## Physical damage dealt.
@export var attack: int = 0
## Physical damage taken.
@export var defense: int = 0
## Magic damage and healing dealt.
@export var magic: int = 0
## Magic damage taken.
@export var spirit: int = 0
## Turn order and fleeing.
@export var agility: int = 0
## Critical hit chance.
@export var luck: int = 0


## Builds a StatBlock in code (tests, tools).
static func create(hp: int, mp: int, atk: int, def: int, mag: int = 0, spr: int = 0,
		agi: int = 0, luk: int = 0) -> StatBlock:
	var block: StatBlock = StatBlock.new()
	block.max_hp = hp
	block.max_mp = mp
	block.attack = atk
	block.defense = def
	block.magic = mag
	block.spirit = spr
	block.agility = agi
	block.luck = luk
	return block


## Value of the stat called `stat` (one of NAMES).
func get_stat(stat: StringName) -> int:
	assert(stat in NAMES, "unknown stat '%s'" % stat)
	return get(stat) as int
