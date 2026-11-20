class_name EnemyAI
extends RefCounted
## Picks an enemy's action from its AIProfile: an optional heal rule, then a weighted random
## choice between attacking and each affordable skill, then a target by the profile's strategy.
## A foe with a Taunt status (Provoke) draws every single-target action.


static func choose(enemy: Combatant, engine: BattleEngine) -> BattleAction:
	return choose_from(enemy, engine.enemies, engine.party, engine.rng)


## Same as `choose()` with the sides given directly (allies includes `enemy` itself).
static func choose_from(enemy: Combatant, allies: Array[Combatant], foes: Array[Combatant],
		rng: RandomNumberGenerator) -> BattleAction:
	var profile: AIProfile = enemy.enemy_data.ai if enemy.enemy_data != null else null
	var living_allies: Array[Combatant] = ActionResolver.living(allies)
	var living_foes: Array[Combatant] = ActionResolver.living(foes)
	if profile == null:
		return BattleAction.attack(enemy, _pick_target(living_foes, AIProfile.TargetStrategy.RANDOM, rng))
	var heal_action: BattleAction = _heal_rule(enemy, profile, living_allies)
	if heal_action != null:
		return heal_action
	var options: Array[SkillData] = [null]  # null = plain attack
	var weights: Array[int] = [profile.attack_weight]
	for skill: SkillData in enemy.skills:
		var weight: int = profile.skill_weights.get(skill, 0) as int
		if weight > 0 and enemy.mp >= skill.mp_cost and skill.is_offensive():
			options.append(skill)
			weights.append(weight)
	var picked: SkillData = options[maxi(0, pick_weighted(weights, rng))]
	if picked == null:
		return BattleAction.attack(enemy, _pick_target(living_foes, profile.target_strategy, rng))
	var targets: Array[Combatant] = []
	if picked.target_mode == Targeting.Mode.ONE_ENEMY:
		targets = [_pick_target(living_foes, profile.target_strategy, rng)]
	return BattleAction.use_skill(enemy, picked, targets)


## Index chosen with probability weight / total. -1 when every weight is 0.
static func pick_weighted(weights: Array[int], rng: RandomNumberGenerator) -> int:
	var total: int = 0
	for w: int in weights:
		total += maxi(0, w)
	if total <= 0:
		return -1
	var roll: int = rng.randi_range(0, total - 1)
	for i: int in weights.size():
		roll -= maxi(0, weights[i])
		if roll < 0:
			return i
	return weights.size() - 1


static func _heal_rule(enemy: Combatant, profile: AIProfile, living_allies: Array[Combatant]) -> BattleAction:
	if profile.heal_below_hp_pct <= 0.0:
		return null
	var wounded: Combatant = null
	for ally: Combatant in living_allies:
		if ally.hp_ratio() < profile.heal_below_hp_pct and (wounded == null or ally.hp_ratio() < wounded.hp_ratio()):
			wounded = ally
	if wounded == null:
		return null
	for skill: SkillData in enemy.skills:
		if skill.effect == SkillData.Effect.HEAL and enemy.mp >= skill.mp_cost:
			var targets: Array[Combatant] = []
			if Targeting.is_single(skill.target_mode):
				targets.append(wounded)
			return BattleAction.use_skill(enemy, skill, targets)
	return null


static func _pick_target(foes: Array[Combatant], strategy: AIProfile.TargetStrategy,
		rng: RandomNumberGenerator) -> Combatant:
	if foes.is_empty():
		return null
	var taunting: Array[Combatant] = []
	for c: Combatant in foes:
		if c.draws_attacks():
			taunting.append(c)
	if not taunting.is_empty():
		foes = taunting
	match strategy:
		AIProfile.TargetStrategy.LOWEST_HP:
			var lowest: Combatant = foes[0]
			for c: Combatant in foes:
				if c.hp < lowest.hp:
					lowest = c
			return lowest
		AIProfile.TargetStrategy.HIGHEST_ATTACK:
			var strongest: Combatant = foes[0]
			for c: Combatant in foes:
				if c.effective_stat(&"attack") > strongest.effective_stat(&"attack"):
					strongest = c
			return strongest
	return foes[rng.randi_range(0, foes.size() - 1)]
