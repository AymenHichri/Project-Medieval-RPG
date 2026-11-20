extends SceneTree
## Generates the battle data under res://data/ (statuses, skills, items, enemies, the party
## characters (Knight, and since Phase 8 the Warden and Hexblade recruits), and since Phase 5 the
## battle visuals in data/visuals/).
##   godot --headless --path <project> -s res://tools/build_battle_data.gd
## This script is the source of truth for the numbers until the files are tuned in the Inspector.
## Re-running it overwrites those files.
## Phase 9 items and equipment come from tools/build_items.gd (run it after this one).

const STATUS_DIR: String = "res://data/status_effects"
const SKILL_DIR: String = "res://data/skills"
const ITEM_DIR: String = "res://data/items"
const ENEMY_DIR: String = "res://data/enemies"
const CHARACTER_DIR: String = "res://data/characters"
const GROWTH_DIR: String = "res://data/growth"
const VISUAL_DIR: String = "res://data/visuals"
const FX_DIR: String = "res://data/fx"
## SovDigital effect packs (extracted by tools/extract_assets.py).
const FX: String = "res://assets/vendor/sovdigital/effects/"
const SOV: String = "res://assets/vendor/sovdigital/"
const HUD_ICONS: String = "res://assets/vendor/gimbles/hud_icons/64px/"
## HD item icons from the SovDigital Inventory UI kit, used where the kit has the item (the
## Gimble's 64 px icons in assets/vendor/gimbles/item_icons/ cover the rest, from Phase 9).
const HD_ITEM_ICONS: String = "res://assets/vendor/sovdigital/inventory_ui/icons/"
const ITEM_ICONS: String = "res://assets/vendor/gimbles/item_icons/64px/"
## Gimble's framed portraits (placeholders for the recruits, PROJECT_PLAN.md Phase 8).
const PORTRAITS: String = "res://assets/vendor/gimbles/portraits/framed/256px/"


var _failed: bool = false
## Battle effects by id (built first; skills, items and visuals refer to them).
var _fx: Dictionary[StringName, FxSpec] = {}


func _initialize() -> void:
	for dir: String in [STATUS_DIR, SKILL_DIR, ITEM_DIR, ENEMY_DIR, CHARACTER_DIR, GROWTH_DIR, VISUAL_DIR, FX_DIR]:
		DirAccess.make_dir_recursive_absolute(dir)
	_build_fx()
	var statuses: Dictionary[StringName, StatusEffectData] = _build_statuses()
	var skills: Dictionary[StringName, SkillData] = _build_skills(statuses)
	var potion: ItemData = _build_potion()
	var holy_water: ItemData = _build_holy_water(statuses)
	var visuals: Dictionary[StringName, CombatantVisual] = _build_visuals()
	_build_enemies(statuses, skills, potion, holy_water, visuals)
	_build_knight(skills, visuals[&"knight"])
	_build_warden(skills, visuals[&"warden"])
	_build_hexblade(skills, visuals[&"hexblade"])
	print("battle data %s" % ("FAILED" if _failed else "written"))
	quit(1 if _failed else 0)


func _build_statuses() -> Dictionary[StringName, StatusEffectData]:
	var out: Dictionary[StringName, StatusEffectData] = {}
	var bleed: StatusEffectData = _status(&"bleed", "Bleed", StatusEffectData.Kind.BLEED, 3, "01_bleeding")
	bleed.dot_percent = 0.05
	bleed.tag_color = Color("8f1d1d")
	out[&"bleed"] = bleed
	var burn: StatusEffectData = _status(&"burn", "Burn", StatusEffectData.Kind.BURN, 2, "03_burning")
	burn.dot_percent = 0.06
	burn.element = Elements.Element.FIRE
	burn.tag_color = Color("d9692b")
	out[&"burn"] = burn
	var curse: StatusEffectData = _status(&"curse", "Curse", StatusEffectData.Kind.CURSE, 3, "05_cursed")
	curse.stat_mult = {&"attack": 0.75, &"magic": 0.75}
	curse.healing_received_mult = 0.5
	curse.element = Elements.Element.SHADOW
	curse.tag_color = Color("6b3fa0")
	out[&"curse"] = curse
	var blessed: StatusEffectData = _status(&"blessed", "Blessed", StatusEffectData.Kind.BLESSED, 3, "22_blessed")
	blessed.stat_mult = {&"defense": 1.25, &"spirit": 1.25}
	blessed.regen_percent = 0.03
	blessed.tag_color = Color("e3c26b")
	out[&"blessed"] = blessed
	var sleep: StatusEffectData = _status(&"sleep", "Sleep", StatusEffectData.Kind.SLEEP, 2, "")
	sleep.duration_turns_max = 4
	sleep.skip_turn = true
	sleep.wears_off_on_hit = true
	sleep.tag_text = "SLP"
	sleep.tag_color = Color("6f8fb8")
	out[&"sleep"] = sleep
	var stun: StatusEffectData = _status(&"stun", "Stun", StatusEffectData.Kind.STUN, 1, "")
	stun.skip_turn = true
	stun.tag_text = "STN"
	stun.tag_color = Color("d8d0b0")
	out[&"stun"] = stun
	# Phase 8: the Warden's Provoke. Enemies aim their single-target actions at the holder.
	var taunt: StatusEffectData = _status(&"taunt", "Taunt", StatusEffectData.Kind.TAUNT, 2, "")
	taunt.draws_attacks = true
	taunt.tag_text = "TNT"
	taunt.tag_color = Color("bb322c")
	out[&"taunt"] = taunt
	for id: StringName in out:
		out[id] = _save(out[id], STATUS_DIR) as StatusEffectData
	return out


func _build_skills(statuses: Dictionary[StringName, StatusEffectData]) -> Dictionary[StringName, SkillData]:
	var out: Dictionary[StringName, SkillData] = {}
	var basic: SkillData = _skill(&"attack_basic", "Attack", SkillData.Category.SKILL, 0, 100, Targeting.Mode.ONE_ENEMY)
	basic.description = "A plain weapon strike."
	out[basic.id] = basic
	var whirlwind: SkillData = _skill(&"whirlwind", "Whirlwind", SkillData.Category.SKILL, 6, 70, Targeting.Mode.ALL_ENEMIES)
	whirlwind.anim_key = &"whirlwind"
	whirlwind.description = "A spinning cut that strikes every foe."
	out[whirlwind.id] = whirlwind
	var charged: SkillData = _skill(&"charged_strike", "Charged Strike", SkillData.Category.SKILL, 5, 180, Targeting.Mode.ONE_ENEMY)
	charged.anim_key = &"charged_strike"
	charged.inflicts = statuses[&"stun"]
	charged.inflict_chance = 0.2
	charged.description = "A heavy overhead blow that may stun."
	out[charged.id] = charged
	var ember: SkillData = _skill(&"ember", "Ember", SkillData.Category.MAGIC, 4, 18, Targeting.Mode.ONE_ENEMY)
	ember.scaling_stat = &"magic"
	ember.element = Elements.Element.FIRE
	ember.inflicts = statuses[&"burn"]
	ember.inflict_chance = 0.25
	ember.anim_key = &"cast"
	ember.description = "A tongue of flame. May set the target alight."
	ember.impact_fx = _fx[&"fire_impact"]
	out[ember.id] = ember
	var heal: SkillData = _skill(&"minor_heal", "Minor Heal", SkillData.Category.MAGIC, 4, 20, Targeting.Mode.ONE_ALLY)
	heal.effect = SkillData.Effect.HEAL
	heal.scaling_stat = &"magic"
	heal.anim_key = &"cast"
	heal.description = "Mends a single ally's wounds."
	heal.impact_fx = _fx[&"heal_burst"]
	out[heal.id] = heal
	_build_party_skills(statuses, out)
	_build_enemy_skills(statuses, out)
	for id: StringName in out:
		out[id] = _save(out[id], SKILL_DIR) as SkillData
	return out


## Phase 8: the Warden (tank and support) and the Hexblade (spells).
func _build_party_skills(statuses: Dictionary[StringName, StatusEffectData], out: Dictionary[StringName, SkillData]) -> void:
	var provoke: SkillData = _skill(&"provoke", "Provoke", SkillData.Category.SKILL, 3, 0, Targeting.Mode.SELF)
	provoke.effect = SkillData.Effect.STATUS
	provoke.inflicts = statuses[&"taunt"]
	provoke.inflict_chance = 1.0
	provoke.priority = 1
	provoke.description = "Bellow a challenge. Foes strike only at you this round and the next."
	out[provoke.id] = provoke
	var guard: SkillData = _skill(&"guard", "Guard", SkillData.Category.SKILL, 0, 0, Targeting.Mode.ONE_ALLY)
	guard.effect = SkillData.Effect.GUARD
	guard.priority = 1
	guard.description = "Defend, and take the single blows aimed at an ally this round."
	out[guard.id] = guard
	var blessing: SkillData = _skill(&"blessing", "Blessing", SkillData.Category.MAGIC, 5, 0, Targeting.Mode.ONE_ALLY)
	blessing.effect = SkillData.Effect.STATUS
	blessing.inflicts = statuses[&"blessed"]
	blessing.inflict_chance = 1.0
	blessing.anim_key = &"cast"
	blessing.impact_fx = _fx[&"holy_light"]
	blessing.description = "A warding prayer: DEF and SPR up and slow healing for 3 rounds."
	out[blessing.id] = blessing
	var benediction: SkillData = _skill(&"benediction", "Benediction", SkillData.Category.MAGIC, 12, 0, Targeting.Mode.ALL_ALLIES)
	benediction.effect = SkillData.Effect.STATUS
	benediction.inflicts = statuses[&"blessed"]
	benediction.inflict_chance = 1.0
	benediction.anim_key = &"cast"
	benediction.impact_fx = _fx[&"holy_light"]
	benediction.description = "Blesses the whole party."
	out[benediction.id] = benediction
	var purify: SkillData = _skill(&"purify", "Purify", SkillData.Category.MAGIC, 3, 0, Targeting.Mode.ONE_ALLY)
	purify.effect = SkillData.Effect.CURE
	purify.cures = [statuses[&"bleed"], statuses[&"burn"], statuses[&"curse"]]
	purify.anim_key = &"cast"
	purify.impact_fx = _fx[&"holy_light"]
	purify.description = "Closes wounds and lifts curses: cures Bleed, Burn and Curse."
	out[purify.id] = purify
	var frost: SkillData = _skill(&"frost", "Frost", SkillData.Category.MAGIC, 5, 22, Targeting.Mode.ONE_ENEMY)
	frost.scaling_stat = &"magic"
	frost.element = Elements.Element.FROST
	frost.anim_key = &"cast"
	frost.impact_fx = _fx[&"frost_impact"]
	frost.description = "A lance of grave-cold ice."
	out[frost.id] = frost
	var spark: SkillData = _skill(&"spark", "Spark", SkillData.Category.MAGIC, 7, 12, Targeting.Mode.ALL_ENEMIES)
	spark.scaling_stat = &"magic"
	spark.element = Elements.Element.LIGHTNING
	spark.anim_key = &"cast"
	spark.impact_fx = _fx[&"spark_impact"]
	spark.description = "Crackling light leaps between every foe."
	out[spark.id] = spark
	var hex: SkillData = _skill(&"hex", "Hex", SkillData.Category.MAGIC, 6, 14, Targeting.Mode.ONE_ENEMY)
	hex.scaling_stat = &"magic"
	hex.element = Elements.Element.SHADOW
	hex.inflicts = statuses[&"curse"]
	hex.inflict_chance = 0.6
	hex.anim_key = &"cast"
	hex.impact_fx = _fx[&"shadow_impact"]
	hex.description = "A whispered malediction. May curse the target."
	out[hex.id] = hex


## Chance an enemy's status attack inflicts Bleed / Curse, and how many plain attacks an enemy
## makes for each status attack (Phase 8, tuned so the solo Knight still meets the Phase 7 balance
## target: about 3.7 fights before resting and 6% deaths, over 900 simulated sessions).
const ENEMY_BLEED_CHANCE: float = 0.25
const ENEMY_CURSE_CHANCE: float = 0.3
const ENEMY_ATTACK_WEIGHT: int = 5

## Phase 8: the enemies' status attacks (PROJECT_PLAN.md Phase 8). Blood Mist belongs to the boss
## (Phase 10) and is not used by any enemy yet.
func _build_enemy_skills(statuses: Dictionary[StringName, StatusEffectData], out: Dictionary[StringName, SkillData]) -> void:
	var rend: SkillData = _skill(&"rend", "Rend", SkillData.Category.SKILL, 0, 90, Targeting.Mode.ONE_ENEMY)
	rend.inflicts = statuses[&"bleed"]
	rend.inflict_chance = ENEMY_BLEED_CHANCE
	rend.anim_key = &"skill"
	rend.description = "Tearing fangs. May cause Bleed."
	out[rend.id] = rend
	var stab: SkillData = _skill(&"serrated_stab", "Serrated Stab", SkillData.Category.SKILL, 0, 100, Targeting.Mode.ONE_ENEMY)
	stab.inflicts = statuses[&"bleed"]
	stab.inflict_chance = ENEMY_BLEED_CHANCE
	stab.anim_key = &"skill"
	stab.description = "A jagged blade. May cause Bleed."
	out[stab.id] = stab
	var chill: SkillData = _skill(&"grave_chill", "Grave Chill", SkillData.Category.SKILL, 0, 80, Targeting.Mode.ONE_ENEMY)
	chill.element = Elements.Element.SHADOW
	chill.inflicts = statuses[&"curse"]
	chill.inflict_chance = ENEMY_CURSE_CHANCE
	chill.anim_key = &"skill"
	chill.description = "The touch of the grave. May Curse."
	out[chill.id] = chill
	var mist: SkillData = _skill(&"blood_mist", "Blood Mist", SkillData.Category.MAGIC, 0, 14, Targeting.Mode.ALL_ENEMIES)
	mist.scaling_stat = &"magic"
	mist.element = Elements.Element.SHADOW
	mist.inflicts = statuses[&"bleed"]
	mist.inflict_chance = 1.0
	mist.anim_key = &"cast"
	mist.description = "A crimson haze that opens every wound. Bleed on all."
	out[mist.id] = mist


func _build_potion() -> ItemData:
	var potion: ItemData = ItemData.new()
	potion.id = &"minor_potion"
	potion.display_name = "Minor Potion"
	potion.icon = _texture(HD_ITEM_ICONS + "flask-round-large/flask-round-large_transparent_64.png")
	potion.price = 20
	potion.target_mode = Targeting.Mode.ONE_ALLY
	potion.effect = ItemData.Effect.HEAL_HP
	potion.amount = 40
	potion.description = "A bitter red draught. Restores 40 HP."
	potion.impact_fx = _fx[&"potion_burst"]
	return _save(potion, ITEM_DIR) as ItemData


## Phase 8: cures Curse. Phase 9: thrown at a foe in battle it deals 15 HOLY damage (×2 on the
## undead). Statuses end with the battle, so it is battle-only.
func _build_holy_water(statuses: Dictionary[StringName, StatusEffectData]) -> ItemData:
	var water: ItemData = ItemData.new()
	water.id = &"holy_water"
	water.display_name = "Holy Water"
	water.icon = _texture(ITEM_ICONS + "058_holy_water.png")
	water.price = 30
	water.target_mode = Targeting.Mode.ONE_ALLY
	water.effect = ItemData.Effect.CURE_STATUS
	water.cures = [statuses[&"curse"]]
	water.usable_in_field = false
	water.element = Elements.Element.HOLY
	water.foe_damage = 15
	water.description = "Water from the old chapel font. Lifts a Curse, or burns the dead for 15 Holy damage."
	water.impact_fx = _fx[&"holy_light"]
	return _save(water, ITEM_DIR) as ItemData


## Phase 7 balance pass: HP ×0.65 and attack ×0.85 of the Phase 4 numbers, so a level 1 Knight
## played sensibly (attacks, Whirlwind on groups, Minor Heal when low) wins 3–5 graveyard fights
## before needing the well (simulated: mean 4.2 fights, 300 runs).
## Phase 8: each enemy also has its status attack (see ENEMY_ATTACK_WEIGHT).
func _build_enemies(statuses: Dictionary[StringName, StatusEffectData], skills: Dictionary[StringName, SkillData],
		potion: ItemData, holy_water: ItemData, visuals: Dictionary[StringName, CombatantVisual]) -> void:
	var wolf: EnemyData = _enemy(&"wolf", "Wolf", StatBlock.create(29, 0, 19, 8, 0, 6, 16, 6), 8, 5)
	wolf.affinities = {Elements.Element.FIRE: Elements.WEAK}
	wolf.drops = [_drop(potion, 0.1)]
	_give_skill(wolf, skills[&"rend"])
	wolf.visual = visuals[&"wolf"]
	_save(wolf, ENEMY_DIR)

	var goblin: EnemyData = _enemy(&"goblin_scout", "Goblin Scout", StatBlock.create(25, 0, 17, 10, 0, 8, 14, 10), 7, 9)
	goblin.affinities = {Elements.Element.LIGHTNING: Elements.WEAK}
	goblin.drops = [_drop(potion, 0.2)]
	goblin.ai.target_strategy = AIProfile.TargetStrategy.LOWEST_HP
	_give_skill(goblin, skills[&"serrated_stab"])
	goblin.visual = visuals[&"goblin_scout"]
	_save(goblin, ENEMY_DIR)

	var undead: Array[StatusEffectData] = [statuses[&"bleed"], statuses[&"sleep"]]
	var skeleton: EnemyData = _enemy(&"skeleton", "Skeleton", StatBlock.create(39, 0, 22, 16, 0, 4, 8, 4), 12, 7)
	skeleton.affinities = {Elements.Element.HOLY: Elements.WEAK, Elements.Element.SHADOW: Elements.RESIST}
	skeleton.status_immunities = undead
	skeleton.drops = [_drop(potion, 0.15), _drop(holy_water, 0.1)]
	_give_skill(skeleton, skills[&"grave_chill"])
	skeleton.visual = visuals[&"skeleton"]
	_save(skeleton, ENEMY_DIR)

	var charred: EnemyData = _enemy(&"skeleton_charred", "Charred Skeleton", StatBlock.create(52, 0, 26, 18, 0, 8, 9, 8), 30, 25)
	charred.affinities = {Elements.Element.HOLY: Elements.WEAK, Elements.Element.SHADOW: Elements.RESIST, Elements.Element.FIRE: Elements.IMMUNE}
	var charred_immunities: Array[StatusEffectData] = undead.duplicate()
	charred_immunities.append(statuses[&"burn"])
	charred.status_immunities = charred_immunities
	charred.drops = [_drop(potion, 0.6), _drop(holy_water, 0.3)]
	_give_skill(charred, skills[&"grave_chill"])
	charred.visual = visuals[&"skeleton_charred"]
	_save(charred, ENEMY_DIR)


func _build_knight(skills: Dictionary[StringName, SkillData], visual: CombatantVisual) -> void:
	var knight: CharacterData = CharacterData.new()
	knight.id = &"knight"
	knight.display_name = "Knight"
	knight.base_stats = StatBlock.create(120, 20, 30, 20, 12, 14, 12, 8)
	# Since Phase 7 the curve is its own file (PROJECT_PLAN.md §6.4: xp_to_next(L) = round(12 × L^1.6)).
	var growth: GrowthCurve = GrowthCurve.new()
	growth.xp_base = 12
	growth.xp_exponent = 1.6
	growth.stat_gain_per_level = StatBlock.create(12, 3, 3, 2, 2, 2, 1, 1)
	growth.max_level = 30
	knight.growth = _save_as(growth, GROWTH_DIR.path_join("knight_growth.tres")) as GrowthCurve
	knight.starting_skills = [skills[&"whirlwind"], skills[&"ember"], skills[&"minor_heal"]]
	var unlock: SkillUnlock = SkillUnlock.new()
	unlock.level = 3
	unlock.skill = skills[&"charged_strike"]
	knight.skill_unlocks = [unlock]
	knight.visual = visual
	knight.portrait = _texture(PORTRAITS + "01_knight.png")
	_save(knight, CHARACTER_DIR)


## Phase 8 recruit: the tank (Knight black recolour, Witch Hunter portrait as a placeholder).
func _build_warden(skills: Dictionary[StringName, SkillData], visual: CombatantVisual) -> void:
	var warden: CharacterData = CharacterData.new()
	warden.id = &"warden"
	warden.display_name = "Warden"
	warden.base_stats = StatBlock.create(150, 16, 26, 28, 8, 18, 8, 6)
	var growth: GrowthCurve = GrowthCurve.new()
	growth.stat_gain_per_level = StatBlock.create(15, 2, 2, 3, 1, 2, 1, 1)
	warden.growth = _save_as(growth, GROWTH_DIR.path_join("warden_growth.tres")) as GrowthCurve
	warden.starting_skills = [skills[&"provoke"], skills[&"guard"], skills[&"blessing"], skills[&"purify"]]
	warden.skill_unlocks = [_unlock(4, skills[&"benediction"])]
	warden.visual = visual
	warden.portrait = _texture(PORTRAITS + "11_witch_hunter.png")
	_save(warden, CHARACTER_DIR)


## Phase 8 recruit: the spellblade (Knight gold recolour, Witch portrait as a placeholder).
func _build_hexblade(skills: Dictionary[StringName, SkillData], visual: CombatantVisual) -> void:
	var hexblade: CharacterData = CharacterData.new()
	hexblade.id = &"hexblade"
	hexblade.display_name = "Hexblade"
	hexblade.base_stats = StatBlock.create(90, 36, 18, 12, 28, 20, 14, 8)
	var growth: GrowthCurve = GrowthCurve.new()
	growth.stat_gain_per_level = StatBlock.create(8, 5, 1, 1, 3, 2, 1, 1)
	hexblade.growth = _save_as(growth, GROWTH_DIR.path_join("hexblade_growth.tres")) as GrowthCurve
	hexblade.starting_skills = [skills[&"ember"], skills[&"frost"], skills[&"spark"], skills[&"minor_heal"]]
	hexblade.skill_unlocks = [_unlock(3, skills[&"hex"])]
	# Phase 9: a spellblade carries no shield.
	hexblade.allowed_equipment = [EquipmentData.Category.WEAPON, EquipmentData.Category.HELM,
			EquipmentData.Category.ACCESSORY]
	hexblade.visual = visual
	hexblade.portrait = _texture(PORTRAITS + "35_witch.png")
	_save(hexblade, CHARACTER_DIR)


# --- effects (FxSpec, SovDigital effect packs) -------------------------------------------------

## Physical hits: blood on the living, sparks off bone, embers off the charred skeleton.
## Spells and items: a fire impact for Ember, a green burst for healing.
func _build_fx() -> void:
	var blood: FxSpec = _fx_spec(&"blood_hit", "blood/effects/blood_splash_medium", &"effect", 0.8)
	blood.mirror_for_facing = true
	_fx_spec(&"bone_sparks", "ambient/effects/sparks_burst", &"effect", 0.7)
	_fx_spec(&"ember_sparks", "ambient/effects/ember_burst", &"effect", 0.8)
	_fx_spec(&"fire_impact", "projectile/effects/fire", &"impact", 0.9)
	# Phase 8: Frost, Spark, Hex and the Warden's holy light.
	_fx_spec(&"frost_impact", "spell/effects/frost", &"impact", 0.8)
	var spark: FxSpec = _fx_spec(&"spark_impact", "ambient/effects/sparks_burst", &"effect", 0.9)
	spark.tint = Color(1.0, 0.95, 0.7)
	_fx_spec(&"shadow_impact", "spell/effects/shadow_orb", &"effect", 0.6)
	var holy: FxSpec = _fx_spec(&"holy_light", "spell/effects/energy_burst", &"effect", 0.4)
	holy.tint = Color(1.0, 0.88, 0.55)
	holy.anchor = FxSpec.Anchor.FEET
	var heal: FxSpec = _fx_spec(&"heal_burst", "spell/effects/energy_burst", &"effect", 0.4)
	heal.tint = Color(0.62, 1.0, 0.55)
	heal.anchor = FxSpec.Anchor.FEET  # a ring on the ground
	var potion: FxSpec = _fx_spec(&"potion_burst", "spell/effects/energy_burst", &"effect", 0.3)
	potion.tint = Color(1.0, 0.6, 0.55)
	potion.anchor = FxSpec.Anchor.FEET
	for id: StringName in _fx:
		_fx[id] = _save_as(_fx[id], FX_DIR.path_join(String(id) + ".tres")) as FxSpec


func _fx_spec(id: StringName, effect_dir: String, animation: StringName, scale: float) -> FxSpec:
	var spec: FxSpec = FxSpec.new()
	var name: String = effect_dir.get_file()
	var path: String = FX + effect_dir + "/godot/%s_spriteframes.tres" % name
	spec.frames = load(path) as SpriteFrames
	if spec.frames == null or not spec.frames.has_animation(animation):
		push_error("missing effect %s (%s)" % [path, animation])
		_failed = true
	spec.animation = animation
	spec.scale = scale
	_fx[id] = spec
	return spec


# --- visuals (Phase 5) ----------------------------------------------------------------------

## Battle scale of every battler: the vendor humanoid is ≈160 px tall at 1.0, small at 1080p.
const BATTLE_SCALE: float = 1.2
## Hit frames of the base attack sheets (the vendor JSON only lists them for the Knight's moves).
## Picked as the frame where the sprite reaches furthest towards its target (measured on the sheets).
const KNIGHT_ATTACK_HIT: int = 4
const KNIGHT_ATTACK2_HIT: int = 3
const WOLF_ATTACK_HIT: int = 8
const WOLF_ATTACK2_HIT: int = 3
const GOBLIN_ATTACK_HIT: int = 5
const GOBLIN_ATTACK2_HIT: int = 5
const SKELETON_ATTACK_HIT: int = 3
## Knight cast stand-in: the wind-up of Charged Strike, held on this frame (§6.3).
const KNIGHT_CAST_LAST_FRAME: int = 6
## Visible height above the feet (px at scale 1), measured on the idle sheets.
const KNIGHT_HEIGHT: float = 164.0
const WOLF_HEIGHT: float = 136.0
const GOBLIN_HEIGHT: float = 153.0
const SKELETON_HEIGHT: float = 157.0


func _build_visuals() -> Dictionary[StringName, CombatantVisual]:
	var out: Dictionary[StringName, CombatantVisual] = {}
	var knight_dir: String = SOV + "knight/characters/knight/"
	var knight: CombatantVisual = _visual(knight_dir, "knight", &"E", KNIGHT_HEIGHT,
			[&"idle", &"move", &"attack", &"skill", &"hurt", &"death"], {&"move": &"run", &"skill": &"attack2"})
	knight.hit_frame = KNIGHT_ATTACK_HIT
	knight.hit_frames[&"skill"] = KNIGHT_ATTACK2_HIT
	# Whirlwind uses the wind-ring version of the move (the spin with its effect drawn in).
	_add_move(knight, knight_dir, &"whirlwind", "whirlwind_ring")
	_add_move(knight, knight_dir, &"charged_strike", "charged_strike")
	_add_move(knight, knight_dir, &"combo", "combo")
	_add_move(knight, knight_dir, &"cast", "charged_strike")
	knight.last_frames[&"cast"] = KNIGHT_CAST_LAST_FRAME
	knight.hit_frames[&"cast"] = KNIGHT_CAST_LAST_FRAME
	knight.hit_fx = _fx[&"blood_hit"]
	out[&"knight"] = knight
	# Phase 8 recruits: the Knight's black and gold recolours. They have only the base sheets, so
	# skills use attack2 and spells the attack2 wind-up.
	var recolour_anims: Array[StringName] = [&"idle", &"move", &"attack", &"skill", &"cast", &"hurt", &"death"]
	var recolour_renames: Dictionary[StringName, StringName] = {&"move": &"run", &"skill": &"attack2", &"cast": &"attack2"}
	for id: StringName in [&"warden", &"hexblade"]:
		var colour: String = "black" if id == &"warden" else "gold"
		var recolour: CombatantVisual = _visual(SOV + "knight/ColourVariations/%s/knight/" % colour, "knight", &"E",
				KNIGHT_HEIGHT, recolour_anims, recolour_renames)
		recolour.hit_frame = KNIGHT_ATTACK_HIT
		recolour.hit_frames = {&"skill": KNIGHT_ATTACK2_HIT, &"cast": KNIGHT_ATTACK2_HIT}
		recolour.hit_fx = _fx[&"blood_hit"]
		out[id] = recolour

	var common: Array[StringName] = [&"idle", &"move", &"attack", &"skill", &"cast", &"hurt", &"death"]
	var renames: Dictionary[StringName, StringName] = {&"move": &"run", &"skill": &"attack2", &"cast": &"attack2"}
	var wolf: CombatantVisual = _visual(SOV + "wolf/characters/wolf/", "wolf", &"W", WOLF_HEIGHT, common, renames)
	wolf.hit_frame = WOLF_ATTACK_HIT
	wolf.hit_frames = {&"skill": WOLF_ATTACK2_HIT, &"cast": WOLF_ATTACK2_HIT}
	wolf.hit_fx = _fx[&"blood_hit"]
	out[&"wolf"] = wolf
	var goblin: CombatantVisual = _visual(SOV + "goblin_scout/characters/goblin-scout/", "goblin-scout", &"W",
			GOBLIN_HEIGHT, common, renames)
	goblin.hit_frame = GOBLIN_ATTACK_HIT
	goblin.hit_frames = {&"skill": GOBLIN_ATTACK2_HIT, &"cast": GOBLIN_ATTACK2_HIT}
	goblin.hit_fx = _fx[&"blood_hit"]
	out[&"goblin_scout"] = goblin
	# Skeletons have no second attack: skill and cast fall back to stand-ins (BattleSprite).
	var bones: Array[StringName] = [&"idle", &"move", &"attack", &"hurt", &"death"]
	var skeleton: CombatantVisual = _visual(SOV + "skeleton/characters/skeleton/", "skeleton", &"W",
			SKELETON_HEIGHT, bones, {&"move": &"run"})
	skeleton.hit_frame = SKELETON_ATTACK_HIT
	skeleton.hit_fx = _fx[&"bone_sparks"]
	out[&"skeleton"] = skeleton
	var charred: CombatantVisual = _visual(SOV + "skeleton/ColourVariations/charred/skeleton/", "skeleton", &"W",
			SKELETON_HEIGHT, bones, {&"move": &"run"})
	charred.hit_frame = SKELETON_ATTACK_HIT
	charred.hit_fx = _fx[&"ember_sparks"]
	out[&"skeleton_charred"] = charred

	for id: StringName in out:
		out[id] = _save_as(out[id], VISUAL_DIR.path_join(String(id) + ".tres")) as CombatantVisual
	return out


## A visual for the vendor character in `dir` (`<name>.json`, `godot/<name>_spriteframes.tres`).
## `anims` are the logical animations to map; `renames` maps a logical name to a vendor base name.
func _visual(dir: String, vendor_name: String, facing: StringName, visible_height: float,
		anims: Array[StringName], renames: Dictionary[StringName, StringName]) -> CombatantVisual:
	var visual: CombatantVisual = CombatantVisual.new()
	visual.sprite_frames = load(dir + "godot/%s_spriteframes.tres" % vendor_name) as SpriteFrames
	if visual.sprite_frames == null:
		push_error("missing SpriteFrames in " + dir)
		_failed = true
	var info: Dictionary = _json(dir + vendor_name + ".json")
	var frame: Vector2 = _vec2(info.get("frame_size"))
	var pivot: Vector2 = _vec2(info.get("pivot"))
	# AnimatedSprite2D centres the frame: shift it so the feet pivot sits on the origin.
	visual.offset = (frame / 2.0 - pivot).round()
	visual.facing = facing
	visual.battle_scale = BATTLE_SCALE
	visual.height = visible_height
	for anim: StringName in anims:
		visual.anim_map[anim] = StringName("%s_%s" % [renames.get(anim, anim), facing])
	return visual


## Maps logical `anim` to a vendor move of the Knight (`moves/<move>/`), with its first hit frame.
func _add_move(visual: CombatantVisual, dir: String, anim: StringName, move: String) -> void:
	var move_dir: String = dir + "moves/%s/" % move
	var frames: SpriteFrames = load(move_dir + "godot/%s_spriteframes.tres" % move) as SpriteFrames
	if frames == null:
		push_error("missing move SpriteFrames " + move_dir)
		_failed = true
		return
	var info: Dictionary = _json(move_dir + move + ".json")
	# The move cell must be centred on the base cell, or the body would jump when it starts.
	var cell: Vector2 = _vec2(info.get("frame_size"))
	var clip: Vector2 = _vec2(info.get("clip_frame_size"))
	var cell_offset: Vector2 = _vec2(info.get("cell_offset", [0, 0]))
	if not (cell / 2.0).is_equal_approx(cell_offset + clip / 2.0):
		push_error("%s: move cell is not centred on the base cell" % move)
		_failed = true
	visual.move_frames[anim] = frames
	visual.anim_map[anim] = StringName("%s_%s" % [move, visual.facing])
	var hits: Array = info.get("hit_frames", []) as Array
	if not hits.is_empty():
		visual.hit_frames[anim] = int(hits[0])


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("cannot read " + path)
		_failed = true
		return {}
	return parsed as Dictionary


func _vec2(value: Variant) -> Vector2:
	var list: Array = value as Array if value is Array else [0, 0]
	return Vector2(float(list[0]), float(list[1]))


# --- helpers --------------------------------------------------------------------------------

func _status(id: StringName, label: String, kind: StatusEffectData.Kind, turns: int, icon: String) -> StatusEffectData:
	var data: StatusEffectData = StatusEffectData.new()
	data.id = id
	data.display_name = label
	data.kind = kind
	data.duration_turns = turns
	if not icon.is_empty():
		data.icon = _texture(HUD_ICONS + icon + ".png")
	return data


func _skill(id: StringName, label: String, category: SkillData.Category, mp: int, power: int,
		mode: Targeting.Mode) -> SkillData:
	var skill: SkillData = SkillData.new()
	skill.id = id
	skill.display_name = label
	skill.category = category
	skill.mp_cost = mp
	skill.power = power
	skill.target_mode = mode
	return skill


func _enemy(id: StringName, label: String, stats: StatBlock, xp: int, gold: int) -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = id
	enemy.display_name = label
	enemy.stats = stats
	enemy.xp = xp
	enemy.gold = gold
	enemy.ai = AIProfile.new()
	return enemy


func _unlock(level: int, skill: SkillData) -> SkillUnlock:
	var unlock: SkillUnlock = SkillUnlock.new()
	unlock.level = level
	unlock.skill = skill
	return unlock


## Adds an offensive skill the enemy uses once for every ENEMY_ATTACK_WEIGHT plain attacks.
func _give_skill(enemy: EnemyData, skill: SkillData) -> void:
	enemy.skills.append(skill)
	enemy.ai.attack_weight = ENEMY_ATTACK_WEIGHT
	enemy.ai.skill_weights[skill] = 1


func _drop(item: ItemData, chance: float) -> DropEntry:
	var drop: DropEntry = DropEntry.new()
	drop.item = item
	drop.chance = chance
	return drop


func _texture(path: String) -> Texture2D:
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_error("missing texture " + path)
		_failed = true
	return texture


func _save_as(res: Resource, path: String) -> Resource:
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		push_error("could not save %s (%s)" % [path, error_string(err)])
		_failed = true
		return res
	return load(path)


## Saves `res` as `<dir>/<id>.tres` and returns the saved copy, so later resources reference
## the file instead of embedding a duplicate.
func _save(res: Resource, dir: String) -> Resource:
	var path: String = dir.path_join(String(res.get(&"id")) + ".tres")
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		push_error("could not save %s (%s)" % [path, error_string(err)])
		_failed = true
		return res
	return load(path)
