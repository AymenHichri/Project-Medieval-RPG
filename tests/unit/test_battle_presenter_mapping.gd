extends TestCase
## BattlePresenter: every BattleEvent type has a handler, and the pure helpers pick the right
## animation, text and colour.


func test_every_event_type_has_a_handler() -> void:
	var presenter: BattlePresenter = BattlePresenter.new()
	for type_name: String in BattleEvent.Type.keys():
		var type: BattleEvent.Type = BattleEvent.Type[type_name] as BattleEvent.Type
		assert_true(presenter.has_handler(type), "no presenter handler for %s" % type_name)
	presenter.free()


func test_action_text() -> void:
	var knight: Combatant = BattleFixtures.hero(StatBlock.create(100, 20, 10, 10))
	var wolf: Combatant = BattleFixtures.foe(StatBlock.create(40, 0, 10, 10), &"wolf")
	var ember: SkillData = BattleFixtures.skill(&"ember", SkillData.Category.MAGIC, 4, 18, Targeting.Mode.ONE_ENEMY)
	ember.display_name = "Ember"
	var whirl: SkillData = BattleFixtures.skill(&"whirlwind", SkillData.Category.SKILL, 6, 70, Targeting.Mode.ALL_ENEMIES)
	whirl.display_name = "Whirlwind"
	assert_eq(BattlePresenter.action_text(BattleAction.attack(knight, wolf)), "Hero attacks!")
	assert_eq(BattlePresenter.action_text(BattleAction.use_skill(knight, ember, [wolf])), "Hero casts Ember!")
	assert_eq(BattlePresenter.action_text(BattleAction.use_skill(knight, whirl, [])), "Hero uses Whirlwind!")
	assert_eq(BattlePresenter.action_text(BattleAction.defend(knight)), "Hero defends.")


func test_spell_colour_follows_element_and_healing() -> void:
	var palette: UIPalette = load("res://scenes/ui/theme/ui_palette.tres") as UIPalette
	var ember: SkillData = load("res://data/skills/ember.tres") as SkillData
	var heal: SkillData = load("res://data/skills/minor_heal.tres") as SkillData
	assert_eq(BattlePresenter.spell_color(ember), palette.ember)
	assert_eq(BattlePresenter.spell_color(heal), palette.heal)


func test_intro_text() -> void:
	var stats: StatBlock = StatBlock.create(10, 0, 1, 1)
	var one: Array[Combatant] = [BattleFixtures.foe(stats, &"wolf")]
	assert_eq(BattleController.intro_text(one), "A Wolf appears!")
	var three: Array[Combatant] = [BattleFixtures.foe(stats, &"wolf"), BattleFixtures.foe(stats, &"wolf"),
			BattleFixtures.foe(stats, &"goblin")]
	three[0].display_name = "Wolf A"
	three[1].display_name = "Wolf B"
	assert_eq(BattleController.intro_text(three), "Wolf A, Wolf B and Goblin appear!")


func test_drops_text_groups_items() -> void:
	var potion: ItemData = load("res://data/items/minor_potion.tres") as ItemData
	var drops: Array[ItemData] = [potion, potion]
	assert_eq(ResultsScreen.drops_text(drops), "Found: Minor Potion ×2")
	assert_eq(ResultsScreen.drops_text([] as Array[ItemData]), "")
