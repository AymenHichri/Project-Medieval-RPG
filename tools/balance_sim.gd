class_name BalanceSim
extends RefCounted
## Slice balance check (PROJECT_PLAN.md Phase 7): a fresh level 1 Knight fights graveyard
## encounters back to back with XP and level-ups applied, played the way a sensible player would
## (Minor Heal below 40% HP, or 50% while Bleeding, Whirlwind on 2+ enemies while MP lasts,
## otherwise Attack; no items),
## until HP falls below `rest_at` (time for the well) or the Knight dies.
## Target: 3–5 fights before resting. Used by tests/unit/test_balance.gd.

const KNIGHT: String = "res://data/characters/knight.tres"
const TABLE: String = "res://data/encounters/graveyard_outskirts.tres"
const MAX_ROUNDS: int = 40


## Runs `trials` sessions. Returns {"mean_fights": float, "deaths": int, "fights": Array[int]}.
static func run(trials: int, seed_value: int, rest_at: float = 0.3) -> Dictionary:
	var table: EncounterTable = load(TABLE) as EncounterTable
	var knight: CharacterData = load(KNIGHT) as CharacterData
	var heal: SkillData = load("res://data/skills/minor_heal.tres") as SkillData
	var whirlwind: SkillData = load("res://data/skills/whirlwind.tres") as SkillData
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var counts: Array[int] = []
	var deaths: int = 0
	for t: int in trials:
		var member: PartyMember = PartyMember.create(knight)
		var fights: int = 0
		while true:
			var group: EncounterGroup = EncounterRoller.pick_group(table, {}, rng)
			var engine: BattleEngine = BattleEngine.new()
			engine.setup(EncounterRoller.make_setup(group, table), [member.combatant], rng)
			_play(engine, member.combatant, heal, whirlwind)
			var result: BattleResult = engine.compute_rewards()
			member.combatant.statuses.clear()
			member.combatant.is_defending = false
			if not result.is_victory():
				deaths += 1
				break
			fights += 1
			member.gain_xp(result.xp_per_member, rng)
			if member.combatant.hp_ratio() < rest_at:
				break
		counts.append(fights)
	var total: int = 0
	for n: int in counts:
		total += n
	return {"mean_fights": float(total) / maxi(1, trials), "deaths": deaths, "fights": counts}


static func _play(engine: BattleEngine, me: Combatant, heal: SkillData, whirlwind: SkillData) -> void:
	while engine.outcome() == BattleEngine.Outcome.ONGOING and engine.round_number < MAX_ROUNDS:
		var foes: Array[Combatant] = ActionResolver.living(engine.enemies)
		var actions: Array[BattleAction] = []
		if me.can_act():
			var heal_below: float = 0.5 if me.has_status(&"bleed") else 0.4
			if me.hp_ratio() < heal_below and me.mp >= heal.mp_cost:
				actions.append(BattleAction.use_skill(me, heal, [me] as Array[Combatant]))
			elif foes.size() >= 2 and me.mp >= whirlwind.mp_cost + heal.mp_cost:
				actions.append(BattleAction.use_skill(me, whirlwind, foes))
			else:
				actions.append(BattleAction.attack(me, foes[0]))
		engine.begin_round(actions)
		while engine.has_next_action():
			engine.execute_next()
		engine.end_round()
