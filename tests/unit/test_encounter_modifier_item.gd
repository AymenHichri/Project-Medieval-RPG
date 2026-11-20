extends TestCase
## Warding Torch (Phase 9): using it in the field adds a ×0.25 encounter-rate modifier that lasts
## exactly 200 steps, and the EncounterTracker rolls each step before ticking, so the 200th step's
## roll still has it. Using one also spends it; a second one restarts the count.

var _saved_mods: Dictionary[StringName, RateModifier]
var _saved_inventory: Inventory
var _saved_party: Party
var _torch: ItemData


func before_each() -> void:
	_saved_mods = GameState.encounter_rate_modifiers
	_saved_inventory = GameState.inventory
	_saved_party = GameState.party
	GameState.encounter_rate_modifiers = {}
	GameState.inventory = Inventory.new()
	GameState.party = Party.new()
	GameState.ensure_party()
	_torch = Inventory.item_data(&"warding_torch")


func after_each() -> void:
	GameState.encounter_rate_modifiers = _saved_mods
	GameState.inventory = _saved_inventory
	GameState.party = _saved_party


func test_torch_data() -> void:
	assert_eq(_torch.effect, ItemData.Effect.WARD)
	assert_eq(_torch.amount, 200)
	assert_almost_eq(_torch.ward_mult, 0.25, 0.001)
	assert_true(_torch.usable_in_field)
	assert_false(_torch.usable_in_battle)
	assert_false(FieldItems.needs_target(_torch))


func test_torch_modifier_lasts_exactly_200_steps() -> void:
	GameState.add_item(&"warding_torch", 1)
	assert_true(GameState.use_item(_torch))
	assert_eq(GameState.item_count(&"warding_torch"), 0, "the torch is spent")
	assert_almost_eq(GameState.get_encounter_multiplier(), 0.25, 0.001)
	for step: int in 199:
		GameState.tick_encounter_modifiers()
	assert_almost_eq(GameState.get_encounter_multiplier(), 0.25, 0.001, "still lit for the 200th step")
	GameState.tick_encounter_modifiers()
	assert_almost_eq(GameState.get_encounter_multiplier(), 1.0, 0.001, "out after 200 steps")
	assert_true(GameState.encounter_rate_modifiers.is_empty())


func test_without_a_torch_nothing_happens() -> void:
	assert_false(GameState.use_item(_torch), "none in the bag")
	assert_true(GameState.encounter_rate_modifiers.is_empty())


func test_second_torch_restarts_the_count() -> void:
	GameState.add_item(&"warding_torch", 2)
	GameState.use_item(_torch)
	for step: int in 150:
		GameState.tick_encounter_modifiers()
	GameState.use_item(_torch)
	assert_eq(GameState.encounter_rate_modifiers.size(), 1, "one modifier, not two")
	assert_eq(GameState.encounter_rate_modifiers.values()[0].steps_left, 200)


func test_tracker_rolls_with_the_modifier_on_every_one_of_its_steps() -> void:
	var player: PlayerController = (load("res://scenes/world/player/player.tscn") as PackedScene).instantiate() as PlayerController
	(Engine.get_main_loop() as SceneTree).root.add_child(player)
	player.set_physics_process(false)
	var tracker: EncounterTracker = player.encounter_tracker
	var mults: Array[float] = []
	var record: Callable = func(_steps: int) -> void: mults.append(GameState.get_encounter_multiplier())
	tracker.step_taken.connect(record)
	GameState.add_item(&"warding_torch", 1)
	GameState.use_item(_torch)
	for step: int in 201:
		tracker._take_step()
	assert_eq(mults.size(), 201)
	assert_almost_eq(mults[0], 0.25, 0.001, "first step warded")
	assert_almost_eq(mults[199], 0.25, 0.001, "200th step warded")
	assert_almost_eq(mults[200], 1.0, 0.001, "201st step not")
	player.get_parent().remove_child(player)
	player.free()
