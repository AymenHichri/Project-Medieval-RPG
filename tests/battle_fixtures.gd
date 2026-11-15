class_name BattleFixtures
extends RefCounted
## Builders for battle tests: fixture stats and data made in code, independent of res://data tuning.


static func rng(seed_value: int = 1) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = seed_value
	return r


static func enemy_data(id: StringName, stats: StatBlock, xp: int = 0, gold: int = 0) -> EnemyData:
	var data: EnemyData = EnemyData.new()
	data.id = id
	data.display_name = String(id).capitalize()
	data.stats = stats
	data.xp = xp
	data.gold = gold
	return data


static func character_data(id: StringName, stats: StatBlock, skills: Array[SkillData] = []) -> CharacterData:
	var data: CharacterData = CharacterData.new()
	data.id = id
	data.display_name = String(id).capitalize()
	data.base_stats = stats
	data.starting_skills = skills
	return data


static func hero(stats: StatBlock, skills: Array[SkillData] = []) -> Combatant:
	return Combatant.from_character(character_data(&"hero", stats, skills))


static func foe(stats: StatBlock, id: StringName = &"foe") -> Combatant:
	return Combatant.from_enemy(enemy_data(id, stats))


static func skill(id: StringName, category: SkillData.Category, mp_cost: int, power: int,
		mode: Targeting.Mode, element: Elements.Element = Elements.Element.PHYSICAL) -> SkillData:
	var s: SkillData = SkillData.new()
	s.id = id
	s.category = category
	s.mp_cost = mp_cost
	s.power = power
	s.target_mode = mode
	s.element = element
	s.scaling_stat = &"magic" if category == SkillData.Category.MAGIC else &"attack"
	return s


static func status(id: StringName, turns: int) -> StatusEffectData:
	var s: StatusEffectData = StatusEffectData.new()
	s.id = id
	s.display_name = String(id).capitalize()
	s.duration_turns = turns
	return s


static func setup(enemies: Array[EnemyData], can_flee: bool = true) -> BattleSetup:
	var s: BattleSetup = BattleSetup.new()
	s.enemies = enemies
	s.can_flee = can_flee
	return s


## Attack actions on the first living enemy for every party member who can act.
static func auto_attacks(engine: BattleEngine) -> Array[BattleAction]:
	var actions: Array[BattleAction] = []
	var targets: Array[Combatant] = ActionResolver.living(engine.enemies)
	for member: Combatant in engine.party:
		if member.can_act() and not targets.is_empty():
			actions.append(BattleAction.attack(member, targets[0]))
	return actions


## Plays rounds with `auto_attacks` until the battle ends or `max_rounds` pass. Returns all events.
static func run_auto_battle(engine: BattleEngine, max_rounds: int) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	while engine.outcome() == BattleEngine.Outcome.ONGOING and engine.round_number < max_rounds:
		engine.begin_round(auto_attacks(engine))
		while engine.has_next_action():
			events.append_array(engine.execute_next())
		events.append_array(engine.end_round())
	return events


static func count(events: Array[BattleEvent], type: BattleEvent.Type) -> int:
	var n: int = 0
	for e: BattleEvent in events:
		if e.type == type:
			n += 1
	return n


static func first(events: Array[BattleEvent], type: BattleEvent.Type) -> BattleEvent:
	for e: BattleEvent in events:
		if e.type == type:
			return e
	return null
