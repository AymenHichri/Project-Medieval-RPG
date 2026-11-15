extends SceneTree
## Generates the random-encounter tables under res://data/encounters/ (PROJECT_PLAN.md §6.2).
##   godot --headless --path <project> -s res://tools/build_encounters.gd
## Uses the enemies written by tools/build_battle_data.gd. Source of truth for the tables until
## they are tuned in the Inspector; re-running it overwrites them.

const ENCOUNTER_DIR: String = "res://data/encounters"
const ENEMY_DIR: String = "res://data/enemies"
const GRAVEYARD_BG: String = "res://scenes/battle/backgrounds/graveyard_bg.tscn"

var _failed: bool = false


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ENCOUNTER_DIR)
	_build_graveyard_outskirts()
	print("encounter tables %s" % ("FAILED" if _failed else "written"))
	quit(1 if _failed else 0)


## Wolf×2 (40), Goblin + Wolf (30), Skeleton×2 (25), rare Charred Skeleton (5).
func _build_graveyard_outskirts() -> void:
	var wolf: EnemyData = _enemy(&"wolf")
	var goblin: EnemyData = _enemy(&"goblin_scout")
	var skeleton: EnemyData = _enemy(&"skeleton")
	var charred: EnemyData = _enemy(&"skeleton_charred")
	var table: EncounterTable = EncounterTable.new()
	table.id = &"graveyard_outskirts"
	table.base_chance_per_step = 0.04
	table.grace_steps = 6
	table.background = load(GRAVEYARD_BG) as PackedScene
	table.groups = [
		_group([wolf, wolf], 40, "A pack of wolves emerges from the fog!"),
		_group([goblin, wolf], 30, ""),
		_group([skeleton, skeleton], 25, "The dead stir beneath the soil!"),
		_group([charred], 5, "A charred skeleton rises, still smouldering!", true),
	]
	_save(table, ENCOUNTER_DIR.path_join("graveyard_outskirts.tres"))


func _group(enemies: Array[EnemyData], weight: int, intro: String, rare: bool = false) -> EncounterGroup:
	var group: EncounterGroup = EncounterGroup.new()
	group.enemies = enemies
	group.weight = weight
	group.intro_text = intro
	group.is_rare = rare
	return group


func _enemy(id: StringName) -> EnemyData:
	var data: EnemyData = load(ENEMY_DIR.path_join(String(id) + ".tres")) as EnemyData
	if data == null:
		push_error("missing enemy %s (run tools/build_battle_data.gd first)" % id)
		_failed = true
	return data


func _save(res: Resource, path: String) -> void:
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		push_error("could not save %s: %s" % [path, error_string(err)])
		_failed = true
