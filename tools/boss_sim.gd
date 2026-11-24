class_name BossSim
extends RefCounted
## Boss balance check (PROJECT_PLAN.md Phase 10): the Knight, Warden and Hexblade at one level, at
## full HP/MP and without gear or items, fight the Blade Assassin, played the way a sensible player
## would:
##   Knight   - Minor Heal on an ally below 35% HP, else Charged Strike while MP lasts (keeping
##              enough for a heal), else Attack.
##   Warden   - Purify a Bleeding or Cursed ally, else Blessing on an unblessed ally below 70% HP
##              (Benediction from level 4 when two need it), else Attack.
##   Hexblade - Minor Heal on an ally below 40% HP, else Frost while MP lasts, else Attack.
## Used by tests/unit/test_boss_battle.gd. Target: a level 4 party (where the quest puts it) wins
## most fights in about 8–14 rounds, and a level 2 party mostly loses.

const BOSS: String = "res://data/enemies/blade_assassin.tres"
const CHARACTERS: Array[String] = [
	"res://data/characters/knight.tres", "res://data/characters/warden.tres", "res://data/characters/hexblade.tres",
]
const MAX_ROUNDS: int = 60


## Runs `trials` fights at `level`. Returns {"wins": int, "mean_rounds": float, "phase_changes": int}.
static func run(trials: int, level: int, seed_value: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var boss: EnemyData = load(BOSS) as EnemyData
	var skills: Dictionary[StringName, SkillData] = {}
	for id: StringName in [&"minor_heal", &"charged_strike", &"purify", &"blessing", &"benediction", &"frost"]:
		skills[id] = load("res://data/skills/%s.tres" % id) as SkillData
	var wins: int = 0
	var rounds: int = 0
	var phase_changes: int = 0
	for t: int in trials:
		var party: Array[Combatant] = []
		for path: String in CHARACTERS:
			party.append(PartyMember.create(load(path) as CharacterData, level, rng).combatant)
		var setup: BattleSetup = BattleSetup.new()
		setup.enemies = [boss]
		setup.can_flee = false
		setup.is_boss = true
		var engine: BattleEngine = BattleEngine.new()
		engine.setup(setup, party, rng)
		phase_changes += _play(engine, skills)
		if engine.outcome() == BattleEngine.Outcome.VICTORY:
			wins += 1
		rounds += engine.round_number
	return {"wins": wins, "mean_rounds": float(rounds) / maxi(1, trials), "phase_changes": phase_changes}


## Plays one fight; returns how many PHASE_CHANGE events it produced.
static func _play(engine: BattleEngine, skills: Dictionary[StringName, SkillData]) -> int:
	var changes: int = 0
	while engine.outcome() == BattleEngine.Outcome.ONGOING and engine.round_number < MAX_ROUNDS:
		var actions: Array[BattleAction] = []
		for me: Combatant in engine.party:
			if me.can_act():
				actions.append(_choose(me, engine, skills))
		engine.begin_round(actions)
		while engine.has_next_action():
			changes += _count_phase_changes(engine.execute_next())
		changes += _count_phase_changes(engine.end_round())
	return changes


static func _count_phase_changes(events: Array[BattleEvent]) -> int:
	var n: int = 0
	for e: BattleEvent in events:
		if e.type == BattleEvent.Type.PHASE_CHANGE:
			n += 1
	return n


static func _choose(me: Combatant, engine: BattleEngine, skills: Dictionary[StringName, SkillData]) -> BattleAction:
	var allies: Array[Combatant] = ActionResolver.living(engine.party)
	var boss: Combatant = ActionResolver.living(engine.enemies)[0]
	var weakest: Combatant = allies[0]
	for ally: Combatant in allies:
		if ally.hp_ratio() < weakest.hp_ratio():
			weakest = ally
	var heal: SkillData = skills[&"minor_heal"]
	match me.character_data.id:
		&"knight":
			if weakest.hp_ratio() < 0.35 and me.mp >= heal.mp_cost:
				return BattleAction.use_skill(me, heal, [weakest] as Array[Combatant])
			var strike: SkillData = skills[&"charged_strike"]
			if strike in me.skills and me.mp >= strike.mp_cost + heal.mp_cost:
				return BattleAction.use_skill(me, strike, [boss] as Array[Combatant])
		&"warden":
			var purify: SkillData = skills[&"purify"]
			for ally: Combatant in allies:
				if (ally.has_status(&"bleed") or ally.has_status(&"curse")) and me.mp >= purify.mp_cost:
					return BattleAction.use_skill(me, purify, [ally] as Array[Combatant])
			var needy: Array[Combatant] = []
			for ally: Combatant in allies:
				if ally.hp_ratio() < 0.7 and not ally.has_status(&"blessed"):
					needy.append(ally)
			var bene: SkillData = skills[&"benediction"]
			if needy.size() >= 2 and bene in me.skills and me.mp >= bene.mp_cost:
				return BattleAction.use_skill(me, bene, allies)
			var bless: SkillData = skills[&"blessing"]
			if not needy.is_empty() and me.mp >= bless.mp_cost:
				return BattleAction.use_skill(me, bless, [needy[0]] as Array[Combatant])
		&"hexblade":
			if weakest.hp_ratio() < 0.4 and me.mp >= heal.mp_cost:
				return BattleAction.use_skill(me, heal, [weakest] as Array[Combatant])
			var frost: SkillData = skills[&"frost"]
			if me.mp >= frost.mp_cost + heal.mp_cost:
				return BattleAction.use_skill(me, frost, [boss] as Array[Combatant])
	return BattleAction.attack(me, boss)
