extends SceneTree
## Generates the Phase 10 boss, the Blade Assassin (SovDigital Blade Assassin Boss pack):
##   godot --headless --path <project> -s res://tools/build_boss.gd
## Run after tools/build_battle_data.gd and tools/build_audio.gd (it reuses their statuses, the
## Blood Mist skill and the boss music). Writes:
##   data/status_effects/stagger.tres          the opening after the boss's big attacks
##   data/fx/frames/<effect>_spriteframes.tres the pack's six effects (it ships sheets + JSON only)
##   data/fx/boss_*.tres                       FxSpecs over them
##   data/skills/<boss skill>.tres             its moves (and Blood Mist gets its effect)
##   data/visuals/blade_assassin*.tres         both forms; hit frames and height are measured on the
##                                             W row of the sheets
##   data/enemies/blade_assassin*.tres         both forms (the first has `phase_two`)
##   data/bosses/blade_assassin.tres           the BossEncounter of the crypt door
## Source of truth for the boss numbers. Re-running it overwrites these files.

const BOSS: String = "res://assets/vendor/sovdigital/blade_assassin/"
const FORM_ONE: String = BOSS + "characters/blade-assassin/"
const FORM_TWO: String = BOSS + "characters/blade-assassin-phase-two/"
const STATUS_DIR: String = "res://data/status_effects"
const SKILL_DIR: String = "res://data/skills"
const FX_DIR: String = "res://data/fx"
const FX_FRAMES_DIR: String = "res://data/fx/frames"
const VISUAL_DIR: String = "res://data/visuals"
const ENEMY_DIR: String = "res://data/enemies"
const BOSS_DIR: String = "res://data/bosses"
const BACKGROUND: String = "res://scenes/battle/backgrounds/graveyard_bg.tscn"
const MUSIC: String = "res://data/audio/music/mus_boss_assassin.tres"
## Used until the boss track is built (a null BattleSetup.music would silence the fight).
const FALLBACK_MUSIC: String = "res://data/audio/music/mus_battle.tres"

## Same battle scale as every other battler (tools/build_battle_data.gd), so the packs keep their
## relative sizes: the boss is drawn larger than the Knight by the vendor.
const BATTLE_SCALE: float = 1.2
## Row of the W (left-facing) animations in the vendor sheets: S, SE, E, NE, N, NW, W, SW.
const W_ROW: int = 6
## Form one ends at half HP, so its injured idles use fractions of its own half of the bar:
## "half" at 75% and "a quarter left" at 62.5% (CombatantVisual.injured_idles).
const FORM_ONE_INJURED_IDLES: Dictionary[StringName, float] = {&"idle_hp50": 0.75, &"idle_hp25": 0.625}
## How often the boss picks each move (AIProfile weights; plain attack = Blade Slash).
const FORM_ONE_WEIGHTS: Dictionary[StringName, int] = {&"attack": 4, &"blink_strike": 3, &"phase_rush": 2, &"assassin_whirlwind": 2}
const FORM_TWO_WEIGHTS: Dictionary[StringName, int] = {&"attack": 3, &"blink_strike": 2, &"phase_rush_unmasked": 2,
		&"blood_mist": 2, &"bone_lance": 2}

var _failed: bool = false
var _fx: Dictionary[StringName, FxSpec] = {}
var _skills: Dictionary[StringName, SkillData] = {}


func _initialize() -> void:
	for dir: String in [STATUS_DIR, SKILL_DIR, FX_DIR, FX_FRAMES_DIR, VISUAL_DIR, ENEMY_DIR, BOSS_DIR]:
		DirAccess.make_dir_recursive_absolute(dir)
	var stagger: StatusEffectData = _build_stagger()
	_build_fx()
	_build_skills(stagger)
	var form_two: EnemyData = _build_form_two()
	var form_one: EnemyData = _build_form_one(form_two)
	_build_encounter(form_one)
	print("boss %s" % ("FAILED" if _failed else "written"))
	quit(1 if _failed else 0)


# --- status ----------------------------------------------------------------------------------

## Staggered: the boss reels after a big attack. Its Defense and Spirit are halved at once, it keeps
## any action left this round, then loses the whole next round; its sprite loops the vendor
## `stagger` animation meanwhile.
func _build_stagger() -> StatusEffectData:
	var stagger: StatusEffectData = StatusEffectData.new()
	stagger.id = &"stagger"
	stagger.display_name = "Staggered"
	stagger.kind = StatusEffectData.Kind.STAGGER
	stagger.duration_turns = 1
	stagger.skip_turn = true
	stagger.starts_next_round = true
	stagger.stat_mult = {&"defense": 0.5, &"spirit": 0.5}
	stagger.tag_text = "STG"
	stagger.tag_color = Color("d8a03a")
	stagger.rest_anim = &"stagger"
	return _save(stagger, STATUS_DIR.path_join("stagger.tres")) as StatusEffectData


# --- effects ---------------------------------------------------------------------------------

func _build_fx() -> void:
	var blink: FxSpec = _fx_spec(&"boss_blink_arrival", "blink_arrival", 0.8, FxSpec.Anchor.FEET)
	blink.offset = Vector2(0, -150)
	var blink_two: FxSpec = _fx_spec(&"boss_blink_arrival_two", "blink_arrival_phase_two", 0.9, FxSpec.Anchor.FEET)
	blink_two.offset = Vector2(0, -130)
	_fx_spec(&"boss_phase_trail", "phase_trail", 0.8, FxSpec.Anchor.BODY)
	_fx_spec(&"boss_phase_trail_two", "phase_trail_phase_two", 0.9, FxSpec.Anchor.BODY)
	var mist: FxSpec = _fx_spec(&"boss_blood_mist", "blood_mist_phase_two", 0.8, FxSpec.Anchor.FEET)
	mist.offset = Vector2(0, -80)
	var lance: FxSpec = _fx_spec(&"boss_bone_lance", "bone_lance_impact_phase_two", 0.8, FxSpec.Anchor.BODY)
	lance.mirror_for_facing = true
	for id: StringName in _fx:
		_fx[id] = _save(_fx[id], FX_DIR.path_join(String(id) + ".tres")) as FxSpec


func _fx_spec(id: StringName, effect: String, scale: float, anchor: FxSpec.Anchor) -> FxSpec:
	var spec: FxSpec = FxSpec.new()
	spec.frames = _effect_frames(effect)
	spec.animation = &"effect"
	spec.scale = scale
	spec.anchor = anchor
	_fx[id] = spec
	return spec


## SpriteFrames (one non-looping "effect" animation) cut from a vendor effect's horizontal sheet,
## at the frame size and fps of its JSON.
func _effect_frames(effect: String) -> SpriteFrames:
	var dir: String = BOSS + "effects/%s/" % effect
	var info: Dictionary = _json(dir + effect + ".json")
	var sheet: Texture2D = load(dir + str(info.get("sheet", effect + ".png"))) as Texture2D
	var cell: Vector2 = _vec2(info.get("frame_size"))
	var count: int = int(info.get("frames", 0))
	if sheet == null or count <= 0 or sheet.get_width() < cell.x * count:
		push_error("effect %s: sheet missing or smaller than its JSON says" % effect)
		_failed = true
		return null
	var frames: SpriteFrames = SpriteFrames.new()
	frames.rename_animation(&"default", &"effect")
	frames.set_animation_speed(&"effect", float(info.get("fps", 12)))
	frames.set_animation_loop(&"effect", bool(info.get("loop", false)))
	for i: int in count:
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(i * cell.x, 0), cell)
		frames.add_frame(&"effect", atlas)
	return _save(frames, FX_FRAMES_DIR.path_join("%s_spriteframes.tres" % effect)) as SpriteFrames


# --- skills ----------------------------------------------------------------------------------

## Blink Strike (quick), Phase Rush and Whirlwind / Bone Lance (big: they leave it Staggered),
## Blood Mist (Bleed on all, the Phase 8 skill, now with its effect).
func _build_skills(stagger: StatusEffectData) -> void:
	var blink: SkillData = _skill(&"blink_strike", "Blink Strike", 130, Targeting.Mode.ONE_ENEMY)
	blink.description = "It vanishes and strikes from the side you did not watch."
	var rush: SkillData = _skill(&"phase_rush", "Phase Rush", 190, Targeting.Mode.ONE_ENEMY)
	rush.user_fx = _fx[&"boss_phase_trail"]
	rush.user_inflicts = stagger
	rush.description = "A blur of steel that leaves its wielder reeling."
	var rush_two: SkillData = _skill(&"phase_rush_unmasked", "Phase Rush", 190, Targeting.Mode.ONE_ENEMY)
	rush_two.anim_key = &"phase_rush"
	rush_two.user_fx = _fx[&"boss_phase_trail_two"]
	rush_two.user_inflicts = stagger
	rush_two.description = rush.description
	var whirl: SkillData = _skill(&"assassin_whirlwind", "Whirlwind", 85, Targeting.Mode.ALL_ENEMIES)
	whirl.anim_key = &"whirlwind"
	whirl.user_inflicts = stagger
	whirl.description = "A spinning storm of blades that strikes every foe."
	var lance: SkillData = _skill(&"bone_lance", "Bone Lance", 230, Targeting.Mode.ONE_ENEMY)
	lance.impact_fx = _fx[&"boss_bone_lance"]
	lance.user_inflicts = stagger
	lance.description = "A spear of black bone driven through the guard."
	for skill: SkillData in [blink, rush, rush_two, whirl, lance]:
		_skills[skill.id] = _save(skill, SKILL_DIR.path_join(String(skill.id) + ".tres")) as SkillData
	var mist: SkillData = load(SKILL_DIR.path_join("blood_mist.tres")) as SkillData
	if mist == null:
		push_error("data/skills/blood_mist.tres is missing: run tools/build_battle_data.gd first")
		_failed = true
		return
	mist.impact_fx = _fx[&"boss_blood_mist"]
	_skills[mist.id] = _save(mist, mist.resource_path) as SkillData


func _skill(id: StringName, label: String, power: int, mode: Targeting.Mode) -> SkillData:
	var skill: SkillData = SkillData.new()
	skill.id = id
	skill.display_name = label
	skill.category = SkillData.Category.SKILL
	skill.power = power
	skill.target_mode = mode
	skill.anim_key = id
	return skill


# --- enemies ---------------------------------------------------------------------------------

## Form one: the masked assassin. Weak to Holy, resists Shadow (PROJECT_PLAN.md §6.3); never
## sleeps or is stunned (boss rule), but its own big attacks stagger it.
func _build_form_one(form_two: EnemyData) -> EnemyData:
	var boss: EnemyData = _enemy(&"blade_assassin", StatBlock.create(520, 0, 48, 22, 22, 20, 16, 10))
	boss.skills = [_skills[&"blink_strike"], _skills[&"phase_rush"], _skills[&"assassin_whirlwind"]]
	boss.ai.attack_weight = FORM_ONE_WEIGHTS[&"attack"]
	for skill: SkillData in boss.skills:
		boss.ai.skill_weights[skill] = FORM_ONE_WEIGHTS[skill.id]
	boss.visual = _build_visual(FORM_ONE, "blade-assassin", &"blade_assassin", false)
	boss.phase_two = form_two
	boss.phase_two_at_hp_pct = 0.5
	return _save(boss, ENEMY_DIR.path_join("blade_assassin.tres")) as EnemyData


## Form two: the Unmasked Daywalker. Same name in battle; Blood Mist and Bone Lance join its moves.
func _build_form_two() -> EnemyData:
	var boss: EnemyData = _enemy(&"blade_assassin_unmasked", StatBlock.create(560, 0, 51, 22, 28, 22, 18, 12))
	boss.skills = [_skills[&"blink_strike"], _skills[&"phase_rush_unmasked"], _skills[&"blood_mist"], _skills[&"bone_lance"]]
	boss.ai.attack_weight = FORM_TWO_WEIGHTS[&"attack"]
	for skill: SkillData in boss.skills:
		boss.ai.skill_weights[skill] = FORM_TWO_WEIGHTS[skill.id]
	boss.visual = _build_visual(FORM_TWO, "blade-assassin-phase-two", &"blade_assassin_unmasked", true)
	return _save(boss, ENEMY_DIR.path_join("blade_assassin_unmasked.tres")) as EnemyData


func _enemy(id: StringName, stats: StatBlock) -> EnemyData:
	var boss: EnemyData = EnemyData.new()
	boss.id = id
	boss.display_name = "Blade Assassin"
	boss.stats = stats
	boss.xp = 150
	boss.gold = 200
	boss.actions_per_round = 2
	boss.affinities = {Elements.Element.HOLY: Elements.WEAK, Elements.Element.SHADOW: Elements.RESIST}
	var immunities: Array[StatusEffectData] = []
	for status: String in ["sleep", "stun"]:
		immunities.append(load(STATUS_DIR.path_join(status + ".tres")) as StatusEffectData)
	boss.status_immunities = immunities
	boss.ai = AIProfile.new()
	boss.ai.target_strategy = AIProfile.TargetStrategy.RANDOM
	return boss


# --- visuals ---------------------------------------------------------------------------------

## A W-facing visual of one form. Logical animations (PROJECT_PLAN.md §6.3): attack = Blade Slash
## (attack3), skill = Phase Rush (attack2), cast = Whirlwind (attack4) in form one and Blood Mist
## (attack5) in form two; each move by its own key.
func _build_visual(dir: String, vendor_name: String, id: StringName, second_form: bool) -> CombatantVisual:
	var visual: CombatantVisual = CombatantVisual.new()
	visual.sprite_frames = load(dir + "godot/%s_spriteframes.tres" % vendor_name) as SpriteFrames
	if visual.sprite_frames == null:
		push_error("missing SpriteFrames in " + dir)
		_failed = true
		return visual
	var info: Dictionary = _json(dir + vendor_name + ".json")
	var cell: Vector2 = _vec2(info.get("frame_size"))
	var pivot: Vector2 = _vec2(info.get("pivot"))
	visual.offset = (cell / 2.0 - pivot).round()
	visual.facing = &"W"
	visual.battle_scale = BATTLE_SCALE
	visual.height = _visible_height(dir + "sheets/idle.png", cell, pivot)
	var anims: Dictionary[StringName, String] = {
		&"idle": "idle", &"move": "run", &"attack": "attack3", &"hurt": "hurt", &"death": "death",
		&"skill": "attack2", &"blink_strike": "attack", &"phase_rush": "attack2", &"whirlwind": "attack4",
	}
	if second_form:
		anims[&"cast"] = "attack5"
		anims[&"blood_mist"] = "attack5"
		anims[&"bone_lance"] = "attack6"
		visual.phase_fx = _fx[&"boss_blink_arrival_two"]
	else:
		anims[&"cast"] = "attack4"
		anims[&"idle_hp50"] = "idle_hp50"
		anims[&"idle_hp25"] = "idle_hp25"
		anims[&"stagger"] = "stagger"
		visual.injured_idles = FORM_ONE_INJURED_IDLES
		visual.entrance_fx = _fx[&"boss_blink_arrival"]
	for anim: StringName in anims:
		var vendor_anim: StringName = StringName("%s_W" % anims[anim])
		if not visual.sprite_frames.has_animation(vendor_anim):
			push_error("%s has no %s" % [vendor_name, vendor_anim])
			_failed = true
		visual.anim_map[anim] = vendor_anim
	visual.hit_frame = _reach_frame(dir + "sheets/attack3.png", cell)
	for anim: StringName in anims:
		if anims[anim].begins_with("attack") and anim != &"attack":
			visual.hit_frames[anim] = _reach_frame(dir + "sheets/%s.png" % anims[anim], cell)
	return _save(visual, VISUAL_DIR.path_join(String(id) + ".tres")) as CombatantVisual


## Height above the feet of the first W idle frame (px at scale 1).
func _visible_height(sheet_path: String, cell: Vector2, pivot: Vector2) -> float:
	var image: Image = _sheet(sheet_path)
	if image == null:
		return 150.0
	var used: Rect2i = image.get_region(Rect2i(Vector2i(0, int(cell.y) * W_ROW), Vector2i(cell))).get_used_rect()
	return pivot.y - used.position.y


## The W-row frame where the sprite reaches furthest left (towards the party): its hit frame, as
## measured for the other enemies in tools/build_battle_data.gd. Frame 0 (the wind-up) is skipped.
func _reach_frame(sheet_path: String, cell: Vector2) -> int:
	var image: Image = _sheet(sheet_path)
	if image == null:
		return 0
	var count: int = image.get_width() / int(cell.x)
	var best: int = 0
	var best_x: int = int(cell.x)
	for i: int in range(1, count):
		var frame: Image = image.get_region(Rect2i(Vector2i(i * int(cell.x), int(cell.y) * W_ROW), Vector2i(cell)))
		var used: Rect2i = frame.get_used_rect()
		var left: int = used.position.x if used.size.x > 0 else int(cell.x)
		if left < best_x:
			best_x = left
			best = i
	return best


func _sheet(path: String) -> Image:
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_error("missing sheet " + path)
		_failed = true
		return null
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


# --- encounter -------------------------------------------------------------------------------

## The crypt door fight: available once the three disturbed graves are searched, never again after
## the boss falls (`blade_assassin_defeated`).
func _build_encounter(boss: EnemyData) -> void:
	var group: EncounterGroup = EncounterGroup.new()
	group.enemies = [boss]
	group.can_flee = false
	group.intro_text = "The crypt door swings wide. A blade gleams in the dark!"
	var encounter: BossEncounter = BossEncounter.new()
	encounter.group = group
	encounter.required_flags = [&"grave_widow_searched", &"grave_soldier_searched", &"grave_fresh_searched"]
	encounter.defeated_flag = &"blade_assassin_defeated"
	encounter.background = load(BACKGROUND) as PackedScene
	if ResourceLoader.exists(MUSIC):
		encounter.music = load(MUSIC) as MusicTrack
	else:
		push_warning("no %s yet (tools/build_audio.gd): the boss fight uses the battle music" % MUSIC)
		encounter.music = load(FALLBACK_MUSIC) as MusicTrack
	_save(encounter, BOSS_DIR.path_join("blade_assassin.tres"))


# --- helpers ---------------------------------------------------------------------------------

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


## Saves `res` to `path` and returns the saved copy, so later resources reference the file.
func _save(res: Resource, path: String) -> Resource:
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		push_error("could not save %s (%s)" % [path, error_string(err)])
		_failed = true
		return res
	return load(path)
