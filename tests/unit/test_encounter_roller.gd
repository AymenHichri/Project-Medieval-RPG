extends TestCase
## EncounterRoller with seeded RNGs: per-step rate, grace steps, weighted group picks, flag
## filters, multipliers, and RateModifier expiry (PROJECT_PLAN.md §6.2).

const STEPS: int = 100000
const PICKS: int = 100000


func _group(weight: int, id: StringName = &"foe", required: StringName = &"", forbidden: StringName = &"") -> EncounterGroup:
	var group: EncounterGroup = EncounterGroup.new()
	group.enemies = [BattleFixtures.enemy_data(id, StatBlock.new())]
	group.weight = weight
	group.required_flag = required
	group.forbidden_flag = forbidden
	return group


func _table(groups: Array[EncounterGroup], chance: float = 0.04, grace: int = 6) -> EncounterTable:
	var table: EncounterTable = EncounterTable.new()
	table.id = &"test"
	table.groups = groups
	table.base_chance_per_step = chance
	table.grace_steps = grace
	return table


## Walks STEPS steps the way the tracker does (reset after each battle). Returns
## [battles, rolled steps, shortest gap between battles].
func _simulate(table: EncounterTable, multiplier: float, seed_value: int) -> Array[int]:
	var rng: RandomNumberGenerator = BattleFixtures.rng(seed_value)
	var since: int = 0
	var battles: int = 0
	var rolled: int = 0
	var shortest: int = STEPS
	for i: int in STEPS:
		since += 1
		if since > table.grace_steps:
			rolled += 1
		if EncounterRoller.should_trigger(since, table, multiplier, rng):
			battles += 1
			shortest = mini(shortest, since)
			since = 0
	return [battles, rolled, shortest]


func test_rate_matches_base_chance_without_grace() -> void:
	var table: EncounterTable = _table([_group(1)], 0.04, 0)
	var stats: Array[int] = _simulate(table, 1.0, 11)
	var rate: float = float(stats[0]) / STEPS
	assert_almost_eq(rate, 0.04, 0.04 * 0.05, "observed rate per step")


func test_rate_per_rolled_step_matches_with_grace() -> void:
	var table: EncounterTable = _table([_group(1)], 0.04, 6)
	var stats: Array[int] = _simulate(table, 1.0, 12)
	var rate: float = float(stats[0]) / stats[1]
	assert_almost_eq(rate, 0.04, 0.04 * 0.05, "observed rate per step outside the grace period")


func test_grace_steps_are_never_violated() -> void:
	var table: EncounterTable = _table([_group(1)], 0.5, 6)
	var stats: Array[int] = _simulate(table, 1.0, 13)
	assert_true(stats[0] > 0, "some battles happened")
	assert_eq(stats[2], 7, "the first possible battle is the step after the grace period")
	var rng: RandomNumberGenerator = BattleFixtures.rng(1)
	for since: int in range(0, 7):
		for i: int in 200:
			assert_false(EncounterRoller.should_trigger(since, _table([_group(1)], 1.0, 6), 1.0, rng),
				"no roll at step %d" % since)


func test_multiplier_scales_the_rate() -> void:
	var table: EncounterTable = _table([_group(1)], 0.04, 0)
	var stats: Array[int] = _simulate(table, 0.5, 14)
	assert_almost_eq(float(stats[0]) / STEPS, 0.02, 0.02 * 0.05, "×0.5 halves the rate")


func test_multiplier_zero_means_no_encounters() -> void:
	var table: EncounterTable = _table([_group(1)], 0.9, 0)
	assert_eq(_simulate(table, 0.0, 15)[0], 0, "no battle with multiplier 0")


func test_group_frequencies_follow_weights() -> void:
	var weights: Array[int] = [40, 30, 25, 5]
	var groups: Array[EncounterGroup] = []
	for w: int in weights:
		groups.append(_group(w))
	var table: EncounterTable = _table(groups)
	var counts: Dictionary[EncounterGroup, int] = {}
	var rng: RandomNumberGenerator = BattleFixtures.rng(21)
	var flags: Dictionary[StringName, Variant] = {}
	for i: int in PICKS:
		var group: EncounterGroup = EncounterRoller.pick_group(table, flags, rng)
		counts[group] = counts.get(group, 0) + 1
	for i: int in groups.size():
		var share: float = float(counts.get(groups[i], 0)) / PICKS
		assert_almost_eq(share, weights[i] / 100.0, 0.02, "group %d share" % i)


func test_flag_filtered_groups_are_never_picked() -> void:
	var open: EncounterGroup = _group(10, &"open")
	var needs_flag: EncounterGroup = _group(50, &"needs", &"crypt_opened")
	var blocked: EncounterGroup = _group(50, &"blocked", &"", &"bells_rung")
	var table: EncounterTable = _table([open, needs_flag, blocked])
	var flags: Dictionary[StringName, Variant] = {&"bells_rung": true}
	var rng: RandomNumberGenerator = BattleFixtures.rng(31)
	for i: int in 5000:
		assert_eq(EncounterRoller.pick_group(table, flags, rng), open, "only the open group")
		if failures.size() > 0:
			return
	flags = {&"crypt_opened": true}
	var seen_needed: bool = false
	for i: int in 2000:
		var group: EncounterGroup = EncounterRoller.pick_group(table, flags, rng)
		seen_needed = seen_needed or group == needs_flag
	assert_true(seen_needed, "the flagged group is eligible once its flag is set")


func test_empty_eligible_list_returns_null() -> void:
	var rng: RandomNumberGenerator = BattleFixtures.rng(41)
	var flags: Dictionary[StringName, Variant] = {}
	assert_null(EncounterRoller.pick_group(_table([]), flags, rng), "no groups")
	assert_null(EncounterRoller.pick_group(_table([_group(0)]), flags, rng), "only weight 0")
	assert_null(EncounterRoller.pick_group(_table([_group(5, &"x", &"never_set")]), flags, rng), "only filtered")
	assert_null(EncounterRoller.pick_group(null, flags, rng), "no table")
	assert_false(EncounterRoller.should_trigger(100, null, 1.0, rng), "no table, no battle")


func test_modifier_with_200_steps_expires_after_exactly_200() -> void:
	var modifiers: Dictionary[StringName, RateModifier] = {
		&"torch": RateModifier.new(0.25, 200), &"charm": RateModifier.new(0.5),
	}
	assert_almost_eq(RateModifier.product(modifiers), 0.125, 0.0001)
	for i: int in 199:
		RateModifier.tick(modifiers)
	assert_true(modifiers.has(&"torch"), "still active after 199 steps")
	assert_eq(modifiers[&"torch"].steps_left, 1)
	var expired: Array[StringName] = RateModifier.tick(modifiers)
	assert_eq(expired, [&"torch"] as Array[StringName], "expires on step 200")
	assert_false(modifiers.has(&"torch"))
	assert_true(modifiers.has(&"charm"), "permanent modifiers stay")
	assert_almost_eq(RateModifier.product(modifiers), 0.5, 0.0001)


func test_game_state_modifiers_tick_and_multiply() -> void:
	var saved: Dictionary[StringName, RateModifier] = GameState.encounter_rate_modifiers.duplicate()
	GameState.encounter_rate_modifiers.clear()
	GameState.add_encounter_modifier(&"torch", 0.25, 2)
	assert_almost_eq(GameState.get_encounter_multiplier(), 0.25, 0.0001)
	GameState.tick_encounter_modifiers()
	GameState.tick_encounter_modifiers()
	assert_almost_eq(GameState.get_encounter_multiplier(), 1.0, 0.0001, "expired after 2 steps")
	GameState.encounter_rate_modifiers = saved


func test_make_setup_copies_the_group_and_table() -> void:
	var group: EncounterGroup = _group(5)
	group.is_rare = true
	group.can_flee = false
	group.intro_text = "Something stirs."
	var table: EncounterTable = _table([group])
	table.background = load("res://scenes/battle/backgrounds/graveyard_bg.tscn") as PackedScene
	table.music = MusicTrack.new()
	var setup: BattleSetup = EncounterRoller.make_setup(group, table)
	assert_eq(setup.enemies.size(), 1)
	assert_true(setup.is_rare)
	assert_false(setup.can_flee)
	assert_false(setup.is_boss)
	assert_eq(setup.intro_text, "Something stirs.")
	assert_eq(setup.background, table.background)
	assert_eq(setup.music, table.music)
	setup.enemies.clear()
	assert_eq(group.enemies.size(), 1, "the setup's enemy list is a copy")


func test_boss_encounter_availability() -> void:
	var boss: BossEncounter = BossEncounter.new()
	boss.group = _group(1)
	boss.required_flags = [&"crypt_opened"]
	boss.defeated_flag = &"boss_defeated"
	assert_false(boss.is_available({}), "needs its flag")
	assert_true(boss.is_available({&"crypt_opened": true}))
	assert_false(boss.is_available({&"crypt_opened": true, &"boss_defeated": true}), "not after victory")
	var setup: BattleSetup = boss.make_setup()
	assert_false(setup.can_flee, "boss fights can't be fled")
	assert_true(setup.is_boss)


func test_graveyard_outskirts_table() -> void:
	var table: EncounterTable = load("res://data/encounters/graveyard_outskirts.tres") as EncounterTable
	assert_not_null(table, "table loads")
	if table == null:
		return
	assert_eq(table.id, &"graveyard_outskirts")
	var summary: Array[String] = []
	for group: EncounterGroup in table.groups:
		var ids: PackedStringArray = []
		for enemy: EnemyData in group.enemies:
			ids.append(String(enemy.id))
		summary.append("%s:%d%s" % ["+".join(ids), group.weight, " rare" if group.is_rare else ""])
	assert_eq(summary, ["wolf+wolf:40", "goblin_scout+wolf:30", "skeleton+skeleton:25",
		"skeleton_charred:5 rare"] as Array[String])
	assert_almost_eq(table.base_chance_per_step, 0.04, 0.0001)
	assert_eq(table.grace_steps, 6)
	assert_not_null(table.background, "battle background set")
