extends TestCase
## The Blade Assassin (Phase 10): a seeded fight changes phase exactly once; injured idles by HP
## threshold; big attacks stagger it (lost turn, halved Defense, the stagger pose); it acts twice a
## round; boss rules (no flee, immunities, Holy weakness); balance (tools/boss_sim.gd).

const BOSS: String = "res://data/enemies/blade_assassin.tres"
const ENCOUNTER: String = "res://data/bosses/blade_assassin.tres"
const SPRITE_SCENE: PackedScene = preload("res://scenes/battle/battle_sprite.tscn")

var _tree: SceneTree = Engine.get_main_loop() as SceneTree


func _boss() -> EnemyData:
	return load(BOSS) as EnemyData


## Three sturdy fixture heroes that only attack.
func _party() -> Array[Combatant]:
	var party: Array[Combatant] = []
	for i: int in 3:
		party.append(BattleFixtures.hero(StatBlock.create(900, 0, 70, 40, 10, 30, 14, 8)))
	return party


func _engine(seed_value: int, party: Array[Combatant] = []) -> BattleEngine:
	var setup: BattleSetup = (load(ENCOUNTER) as BossEncounter).make_setup()
	var engine: BattleEngine = BattleEngine.new()
	engine.setup(setup, party if not party.is_empty() else _party(), BattleFixtures.rng(seed_value))
	return engine


func test_seeded_fight_changes_phase_exactly_once() -> void:
	var engine: BattleEngine = _engine(11)
	var phase_events: Array[BattleEvent] = []
	var guard: int = 0
	while engine.outcome() == BattleEngine.Outcome.ONGOING and guard < 80:
		guard += 1
		var actions: Array[BattleAction] = []
		for hero: Combatant in engine.party:
			if hero.can_act():
				actions.append(BattleAction.attack(hero, engine.enemies[0]))
		engine.begin_round(actions)
		var events: Array[BattleEvent] = []
		while engine.has_next_action():
			events.append_array(engine.execute_next())
		events.append_array(engine.end_round())
		for e: BattleEvent in events:
			if e.type == BattleEvent.Type.PHASE_CHANGE:
				phase_events.append(e)
	assert_eq(engine.outcome(), BattleEngine.Outcome.VICTORY)
	assert_eq(phase_events.size(), 1, "one phase change")
	var form_two: EnemyData = phase_events[0].get_value(&"new_data") as EnemyData
	assert_eq(form_two.id, &"blade_assassin_unmasked")
	assert_true(engine.enemies[0].phase_changed)
	assert_eq(engine.compute_rewards().xp, form_two.xp, "rewards of the form it died in")


func test_phase_change_keeps_the_hp_ratio() -> void:
	var boss: Combatant = Combatant.from_enemy(_boss())
	boss.hp = boss.max_hp() / 2
	assert_true(boss.should_change_phase())
	boss.change_phase()
	assert_almost_eq(boss.hp_ratio(), 0.5, 0.01)
	assert_false(boss.should_change_phase(), "never twice")


func test_injured_idle_selection_by_hp() -> void:
	var form_one: CombatantVisual = _boss().visual
	assert_eq(form_one.idle_for(1.0), &"idle")
	assert_eq(form_one.idle_for(0.8), &"idle")
	assert_eq(form_one.idle_for(0.75), &"idle_hp50", "half of its own part of the bar")
	assert_eq(form_one.idle_for(0.65), &"idle_hp50")
	assert_eq(form_one.idle_for(0.6), &"idle_hp25")
	assert_eq(form_one.idle_for(0.51), &"idle_hp25")
	var form_two: CombatantVisual = _boss().phase_two.visual
	assert_eq(form_two.idle_for(0.3), &"idle", "the second form has no injured idles")
	# Default fractions (0.5 / 0.25) when a visual sets none.
	var plain: CombatantVisual = form_one.duplicate() as CombatantVisual
	plain.injured_idles = {}
	assert_eq(plain.idle_for(0.6), &"idle")
	assert_eq(plain.idle_for(0.5), &"idle_hp50")
	assert_eq(plain.idle_for(0.2), &"idle_hp25")
	var knight: CombatantVisual = load("res://data/visuals/knight.tres") as CombatantVisual
	assert_eq(knight.idle_for(0.1), &"idle", "no injured idles mapped")


func test_big_attack_staggers_the_boss() -> void:
	var engine: BattleEngine = _engine(3)
	var boss: Combatant = engine.enemies[0]
	var rush: SkillData = load("res://data/skills/phase_rush.tres") as SkillData
	var resolver: ActionResolver = ActionResolver.new(engine.party, engine.enemies, engine.rng)
	var defense: int = boss.effective_stat(&"defense")
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_skill(boss, rush, [engine.party[0]] as Array[Combatant]))
	var staggered: bool = false
	for e: BattleEvent in events:
		staggered = staggered or (e.type == BattleEvent.Type.STATUS_APPLIED and e.subject() == boss)
	assert_true(staggered, "Phase Rush leaves it Staggered")
	assert_true(boss.has_status(&"stagger"))
	assert_eq(boss.effective_stat(&"defense"), roundi(defense * 0.5), "an opening: Defense halved at once")
	assert_true(boss.can_act(), "it keeps the rest of this round")
	engine.end_round()
	assert_true(boss.has_status(&"stagger"), "still reeling into the next round")
	assert_false(boss.can_act())
	# The whole next round is lost, then the stagger wears off.
	engine.begin_round([] as Array[BattleAction])
	var acted: int = 0
	while engine.has_next_action():
		for e: BattleEvent in engine.execute_next():
			if e.type == BattleEvent.Type.ACTION_STARTED:
				acted += 1
	engine.end_round()
	assert_eq(acted, 0, "both of its actions are lost")
	assert_false(boss.has_status(&"stagger"), "over after that round")
	assert_true(boss.can_act())


func test_stagger_from_the_first_action_keeps_the_second() -> void:
	var engine: BattleEngine = _engine(8)
	var boss: Combatant = engine.enemies[0]
	StatusEffects.apply(boss, load("res://data/status_effects/stagger.tres") as StatusEffectData, engine.rng)
	var blink: SkillData = load("res://data/skills/blink_strike.tres") as SkillData
	var events: Array[BattleEvent] = ActionResolver.new(engine.party, engine.enemies, engine.rng).resolve(
			BattleAction.use_skill(boss, blink, [engine.party[0]] as Array[Combatant]))
	assert_eq(events[0].type, BattleEvent.Type.ACTION_STARTED, "not skipped in the round it reeled")


func test_blink_strike_does_not_stagger() -> void:
	var engine: BattleEngine = _engine(4)
	var boss: Combatant = engine.enemies[0]
	var blink: SkillData = load("res://data/skills/blink_strike.tres") as SkillData
	ActionResolver.new(engine.party, engine.enemies, engine.rng).resolve(
			BattleAction.use_skill(boss, blink, [engine.party[0]] as Array[Combatant]))
	assert_false(boss.has_status(&"stagger"))


func test_boss_acts_twice_per_round() -> void:
	var engine: BattleEngine = _engine(5)
	engine.begin_round([] as Array[BattleAction])
	var actions: int = 0
	while engine.has_next_action():
		for e: BattleEvent in engine.execute_next():
			if e.type == BattleEvent.Type.ACTION_STARTED:
				actions += 1
	assert_eq(actions, 2)


func test_boss_rules() -> void:
	var encounter: BossEncounter = load(ENCOUNTER) as BossEncounter
	var setup: BattleSetup = encounter.make_setup()
	assert_false(setup.can_flee)
	assert_true(setup.is_boss)
	assert_eq(setup.victory_flag, &"blade_assassin_defeated")
	assert_not_null(setup.music, "boss music (or the battle music until it is built)")
	var boss: Combatant = Combatant.from_enemy(_boss())
	assert_eq(boss.affinity(Elements.Element.HOLY), Elements.WEAK)
	assert_eq(boss.affinity(Elements.Element.SHADOW), Elements.RESIST)
	for status: String in ["sleep", "stun"]:
		var data: StatusEffectData = load("res://data/status_effects/%s.tres" % status) as StatusEffectData
		assert_true(StatusEffects.is_immune(boss, data), "immune to " + status)
	var stagger: StatusEffectData = load("res://data/status_effects/stagger.tres") as StatusEffectData
	assert_false(StatusEffects.is_immune(boss, stagger), "but its own stagger lands")
	var engine: BattleEngine = _engine(6)
	assert_eq(engine.flee_chance(), 0.0, "no escape")


func test_sprite_rests_in_stagger_and_injured_idles() -> void:
	var sprite: BattleSprite = SPRITE_SCENE.instantiate() as BattleSprite
	_tree.root.add_child(sprite)
	var boss: Combatant = Combatant.from_enemy(_boss())
	sprite.setup(boss, boss.enemy_data.visual, Vector2(1320, 700))
	assert_eq(sprite.resting_anim(), &"idle")
	boss.hp = roundi(boss.max_hp() * 0.7)
	assert_eq(sprite.resting_anim(), &"idle_hp50")
	StatusEffects.apply(boss, load("res://data/status_effects/stagger.tres") as StatusEffectData, BattleFixtures.rng(1))
	assert_eq(sprite.resting_anim(), &"stagger", "the opening shows")
	sprite.rest()
	assert_eq(sprite.body.animation, &"stagger_W")
	boss.statuses.clear()
	sprite.set_visual(boss.enemy_data.phase_two.visual)
	assert_eq(sprite.resting_anim(), &"idle", "form two")
	sprite.free()


func test_balance_a_level_four_party_usually_wins() -> void:
	var four: Dictionary = BossSim.run(60, 4, 2026)
	var two: Dictionary = BossSim.run(40, 2, 2026)
	assert_true(int(four["wins"]) >= 36 and int(four["wins"]) <= 57,
			"level 4 wins %d/60 (target 60–95%%, no items or gear)" % four["wins"])
	assert_true(float(four["mean_rounds"]) >= 7.0, "a real fight: %.1f rounds" % four["mean_rounds"])
	assert_true(int(two["wins"]) <= 8, "level 2 mostly loses: %d/40" % two["wins"])
	assert_eq(int(four["phase_changes"]), 60, "every fight reaches the second form")
