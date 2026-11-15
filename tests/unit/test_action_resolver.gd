extends TestCase
## ActionResolver: retargeting, MP, area skills, items, healing, flee.

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var resolver: ActionResolver
var hero: Combatant


func before_each() -> void:
	hero = BattleFixtures.hero(StatBlock.create(100, 10, 40, 10, 20, 10, 10))
	party = [hero]
	enemies = []
	for i: int in 3:
		enemies.append(BattleFixtures.foe(StatBlock.create(50, 0, 10, 0, 0, 0, 10), StringName("foe_%d" % i)))
	resolver = ActionResolver.new(party, enemies, BattleFixtures.rng(5))


func _damaged(events: Array[BattleEvent]) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for e: BattleEvent in events:
		if e.type == BattleEvent.Type.DAMAGE:
			out.append(e.subject())
	return out


func test_retarget_on_dead_target() -> void:
	enemies[0].hp = 0
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.attack(hero, enemies[0]))
	var hit: Array[Combatant] = _damaged(events)
	assert_eq(hit.size(), 1)
	assert_true(hit[0] != enemies[0] and hit[0].side == Combatant.Team.ENEMY, "another enemy was hit")


func test_no_target_left_fails() -> void:
	for e: Combatant in enemies:
		e.hp = 0
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.attack(hero, enemies[0]))
	assert_eq(events[-1].type, BattleEvent.Type.ACTION_FAILED)
	assert_eq(events[-1].get_value(&"reason"), &"no_target")


func test_mp_is_deducted() -> void:
	var fire: SkillData = BattleFixtures.skill(&"fire", SkillData.Category.MAGIC, 4, 10, Targeting.Mode.ONE_ENEMY, Elements.Element.FIRE)
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_skill(hero, fire, [enemies[0]]))
	assert_eq(hero.mp, 6)
	assert_eq(BattleFixtures.first(events, BattleEvent.Type.MP_CHANGED).get_value(&"amount"), -4)
	assert_true(enemies[0].hp < 50)


func test_insufficient_mp_is_rejected() -> void:
	var big: SkillData = BattleFixtures.skill(&"big", SkillData.Category.MAGIC, 11, 10, Targeting.Mode.ONE_ENEMY)
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_skill(hero, big, [enemies[0]]))
	assert_eq(events[-1].type, BattleEvent.Type.ACTION_FAILED)
	assert_eq(events[-1].get_value(&"reason"), &"not_enough_mp")
	assert_eq(hero.mp, 10, "nothing spent")
	assert_eq(enemies[0].hp, 50, "nothing hit")


func test_all_enemies_hits_every_living_enemy() -> void:
	enemies[1].hp = 0
	var sweep: SkillData = BattleFixtures.skill(&"sweep", SkillData.Category.SKILL, 0, 70, Targeting.Mode.ALL_ENEMIES)
	var hit: Array[Combatant] = _damaged(resolver.resolve(BattleAction.use_skill(hero, sweep, [])))
	assert_eq(hit.size(), 2)
	assert_true(enemies[0] in hit and enemies[2] in hit)
	assert_false(enemies[1] in hit, "dead enemies are skipped")


func test_multi_hit_retargets_after_kill() -> void:
	enemies[0].hp = 1
	var combo: SkillData = BattleFixtures.skill(&"combo", SkillData.Category.SKILL, 0, 100, Targeting.Mode.ONE_ENEMY)
	combo.hits = 3
	var hit: Array[Combatant] = _damaged(resolver.resolve(BattleAction.use_skill(hero, combo, [enemies[0]])))
	assert_eq(hit.size(), 3)
	assert_eq(hit[0], enemies[0])
	assert_true(hit[1] != enemies[0] and hit[2] != enemies[0])


func test_item_callback_is_invoked() -> void:
	var potion: ItemData = ItemData.new()
	potion.id = &"potion"
	potion.effect = ItemData.Effect.HEAL_HP
	potion.amount = 30
	var used: Array[ItemData] = []
	resolver.consume_item = func(item: ItemData) -> bool:
		used.append(item)
		return true
	hero.hp = 50
	resolver.resolve(BattleAction.use_item(hero, potion, [hero]))
	assert_eq(used.size(), 1)
	assert_eq(used[0], potion)
	assert_eq(hero.hp, 80)


func test_item_rejected_when_inventory_is_empty() -> void:
	var potion: ItemData = ItemData.new()
	potion.effect = ItemData.Effect.HEAL_HP
	potion.amount = 30
	resolver.consume_item = func(_item: ItemData) -> bool: return false
	hero.hp = 50
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_item(hero, potion, [hero]))
	assert_eq(events[-1].get_value(&"reason"), &"no_item")
	assert_eq(hero.hp, 50)


func test_revive_item_targets_the_fallen() -> void:
	var ally: Combatant = BattleFixtures.hero(StatBlock.create(80, 0, 10, 10))
	party.append(ally)
	ally.hp = 0
	var feather: ItemData = ItemData.new()
	feather.effect = ItemData.Effect.REVIVE
	feather.amount = 20
	resolver.resolve(BattleAction.use_item(hero, feather, [ally]))
	assert_eq(ally.hp, 20)


func test_heal_never_exceeds_max_hp() -> void:
	var mend: SkillData = BattleFixtures.skill(&"mend", SkillData.Category.MAGIC, 2, 500, Targeting.Mode.ONE_ALLY)
	mend.effect = SkillData.Effect.HEAL
	hero.hp = 90
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_skill(hero, mend, [hero]))
	assert_eq(hero.hp, 100)
	assert_eq(BattleFixtures.first(events, BattleEvent.Type.HEAL).get_value(&"amount"), 10)


func test_weakness_is_flagged() -> void:
	enemies[0].affinities = {Elements.Element.FIRE: Elements.WEAK}
	var fire: SkillData = BattleFixtures.skill(&"fire", SkillData.Category.MAGIC, 0, 10, Targeting.Mode.ONE_ENEMY, Elements.Element.FIRE)
	var dmg: BattleEvent = BattleFixtures.first(resolver.resolve(BattleAction.use_skill(hero, fire, [enemies[0]])), BattleEvent.Type.DAMAGE)
	assert_true(dmg.get_value(&"weak") as bool)


func test_kill_emits_defeated() -> void:
	enemies[0].hp = 1
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.attack(hero, enemies[0]))
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.DEFEATED), 1)
	assert_false(enemies[0].is_alive())


func test_defend_sets_flag_and_dead_actor_does_nothing() -> void:
	resolver.resolve(BattleAction.defend(hero))
	assert_true(hero.is_defending)
	enemies[0].hp = 0
	assert_true(resolver.resolve(BattleAction.attack(enemies[0], hero)).is_empty())


func test_flee_blocked_when_not_allowed() -> void:
	resolver.can_flee = false
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.flee(hero))
	assert_eq(events[-1].get_value(&"reason"), &"cannot_flee")


func test_flee_chance_follows_agility() -> void:
	var even: float = resolver.flee_chance()
	assert_almost_eq(even, ActionResolver.FLEE_BASE_CHANCE, 0.0001, "equal agility")
	var quick: Combatant = BattleFixtures.hero(StatBlock.create(10, 0, 1, 1, 0, 0, 30))
	party.append(quick)
	assert_true(resolver.flee_chance() > even, "a faster party flees more easily")
