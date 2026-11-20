extends TestCase
## Victory rewards (Phase 7): gold, XP and drops reach GameState; drops are deterministic per seed.

const WOLF: String = "res://data/enemies/wolf.tres"

var _saved_party: Party
var _saved_gold: int = 0
var _saved_items: Inventory
var _saved_rng: RandomNumberGenerator


func before_each() -> void:
	_saved_party = GameState.party
	_saved_gold = GameState.gold
	_saved_items = GameState.inventory
	GameState.inventory = Inventory.new()
	_saved_rng = GameState.rng
	GameState.party = Party.new()
	GameState.ensure_party()
	GameState.gold = 0
	GameState.rng = BattleFixtures.rng(5)


func after_each() -> void:
	GameState.party = _saved_party
	GameState.gold = _saved_gold
	GameState.inventory = _saved_items
	GameState.rng = _saved_rng


## Two wolves against the real Knight, auto-attacking, with a seeded RNG.
func _win_against_two_wolves(seed_value: int) -> BattleResult:
	var wolf: EnemyData = load(WOLF) as EnemyData
	var engine: BattleEngine = BattleEngine.new()
	engine.setup(BattleFixtures.setup([wolf, wolf]), GameState.party.combatants(), BattleFixtures.rng(seed_value))
	BattleFixtures.run_auto_battle(engine, 30)
	return engine.compute_rewards()


func test_wolf_pair_gives_expected_gold_and_xp() -> void:
	var wolf: EnemyData = load(WOLF) as EnemyData
	var result: BattleResult = _win_against_two_wolves(11)
	assert_true(result.is_victory(), "the Knight beats two wolves")
	assert_eq(result.gold, wolf.gold * 2)
	assert_eq(result.xp, wolf.xp * 2)
	assert_eq(result.xp_per_member, wolf.xp * 2, "one survivor takes all the XP")
	var member: PartyMember = GameState.party.leader()
	GameState.apply_battle_rewards(result)
	assert_eq(GameState.gold, wolf.gold * 2)
	assert_eq(member.xp, wolf.xp * 2)
	for drop: ItemData in result.drops:
		assert_true(GameState.item_count(drop.id) > 0)


func test_reward_xp_levels_up_and_matches_the_preview() -> void:
	var result: BattleResult = _win_against_two_wolves(11)
	var member: PartyMember = GameState.party.leader()
	var preview: PackedStringArray = GameState.preview_level_ups(result)
	var leveled: Array[LevelUp] = []
	var on_level: Callable = func(_m: PartyMember, up: LevelUp) -> void: leveled.append(up)
	GameState.member_leveled.connect(on_level)
	var ups: Array[LevelUp] = GameState.apply_battle_rewards(result)
	GameState.member_leveled.disconnect(on_level)
	assert_eq(member.level, Progression.level_for_xp(member.data.growth, result.xp_per_member))
	assert_true(member.level >= 2, "16 XP is past the 12 needed for level 2")
	assert_eq(leveled.size(), ups.size(), "one signal per level")
	var lines: PackedStringArray = []
	for up: LevelUp in ups:
		lines.append_array(up.describe())
	assert_eq(preview, lines, "the results screen shows what is applied")


func test_drops_are_deterministic_per_seed() -> void:
	var names: Array[String] = []
	for attempt: int in 2:
		GameState.party = Party.new()
		GameState.ensure_party()
		var result: BattleResult = _win_against_two_wolves(23)
		names.append(ResultsScreen.drops_text(result.drops))
	assert_eq(names[0], names[1], "same seed, same drops")
	var any_differs: bool = false
	for seed_value: int in range(1, 40):
		GameState.party = Party.new()
		GameState.ensure_party()
		var other: String = ResultsScreen.drops_text(_win_against_two_wolves(seed_value).drops)
		any_differs = any_differs or other != names[0]
	assert_true(any_differs, "the drop roll depends on the seed")


func test_defeat_and_fallen_members_get_nothing() -> void:
	var result: BattleResult = BattleResult.new()
	result.outcome = BattleEngine.Outcome.DEFEAT
	result.xp = 50
	result.xp_per_member = 50
	result.gold = 30
	GameState.apply_battle_rewards(result)
	assert_eq(GameState.gold, 0)
	assert_eq(GameState.party.leader().xp, 0)
	var won: BattleResult = BattleResult.new()
	won.outcome = BattleEngine.Outcome.VICTORY
	won.xp_per_member = 50
	won.survivors = []
	GameState.apply_battle_rewards(won)
	assert_eq(GameState.party.leader().xp, 0, "not a survivor, no XP")
