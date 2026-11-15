extends Node
## Debug launcher (PROJECT_PLAN.md Phase 5): F6 on debug_battle.tscn starts the fight described by
## the exported `setup` with the exported party, prints the result and restarts the scene.
## Edit the exports in the Inspector to try other fights (e.g. `party_hp = 1` to check defeat).

const BATTLE_SCENE: PackedScene = preload("res://scenes/battle/battle_scene.tscn")
## Pause after the battle before it restarts.
const RESTART_SECONDS: float = 1.0

@export var setup: BattleSetup
@export var party: Array[CharacterData] = []
## Skills added to every member on top of their starting skills (e.g. Charged Strike, learned at
## level 3, to try it at level 1).
@export var extra_skills: Array[SkillData] = []
## Starting HP of every member (-1 = full). 1 makes a defeat easy to check.
@export var party_hp: int = -1
## Battle items and counts.
@export var items: Dictionary[ItemData, int] = {}
## RNG seed (0 = random each run).
@export var rng_seed: int = 0
@export var auto_battle: bool = false
## Restart the fight when it ends.
@export var loop: bool = true


func _ready() -> void:
	if setup == null or party.is_empty():
		push_error("debug_battle: set `setup` and `party` in the Inspector")
		return
	var members: Array[Combatant] = []
	for data: CharacterData in party:
		var skills: Array[SkillData] = data.starting_skills.duplicate()
		for skill: SkillData in extra_skills:
			if not skill in skills:
				skills.append(skill)
		members.append(Combatant.from_character(data, null, skills, party_hp))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	var battle: BattleController = BATTLE_SCENE.instantiate() as BattleController
	battle.auto_battle = auto_battle
	add_child(battle)
	var result: BattleResult = await battle.start(setup, members, rng, items)
	print("debug_battle: %s after %d rounds, xp %d, gold %d, drops %s" % [
		BattleEngine.Outcome.keys()[result.outcome], result.rounds, result.xp, result.gold,
		ResultsScreen.drops_text(result.drops)])
	if loop and is_inside_tree():
		await get_tree().create_timer(RESTART_SECONDS).timeout
		get_tree().reload_current_scene()
