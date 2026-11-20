class_name StatusPage
extends VBoxContainer
## The pause menu's Party tab (PROJECT_PLAN.md Phase 8): one button per member, and for the chosen
## member a framed Gimble's portrait, name, level, XP bar (dfgui purple, progress through the
## current level), HP/MP bars, the six combat stats in NumericLabels, element resistances as
## coloured text tags, active statuses and known skills. Reads GameState's party; never changes it.

const STAT_BAR: PackedScene = preload("res://scenes/ui/widgets/stat_bar.tscn")
const PALETTE: UIPalette = preload("res://scenes/ui/theme/ui_palette.tres")
## Stats listed in the grid (HP and MP have bars), with their labels.
const STAT_LABELS: Dictionary[StringName, String] = {
	&"attack": "Attack", &"defense": "Defense", &"magic": "Magic",
	&"spirit": "Spirit", &"agility": "Agility", &"luck": "Luck",
}
const STATUS_ICON_SIZE: Vector2 = Vector2(32, 32)

## The member whose page is shown.
var shown: PartyMember

var _buttons: Array[Button] = []

@onready var _members: HBoxContainer = %Members
@onready var _portrait: TextureRect = %Portrait
@onready var _name: Label = %MemberName
@onready var _level: Label = %Level
@onready var _xp_bar: StatBar = %XpBar
@onready var _next: Label = %NextLevel
@onready var _hp_bar: StatBar = %HpBar
@onready var _mp_bar: StatBar = %MpBar
@onready var _stats: GridContainer = %Stats
@onready var _resistances: HFlowContainer = %Resistances
@onready var _statuses: HFlowContainer = %Statuses
@onready var _skills: Label = %Skills


## Rebuilds the member buttons from the party and shows `member` (default: the first one).
func refresh(member: PartyMember = null) -> void:
	for button: Button in _buttons:
		_members.remove_child(button)
		button.queue_free()
	_buttons.clear()
	var members: Array[PartyMember] = GameState.party.members
	for m: PartyMember in members:
		var button: Button = Button.new()
		button.text = m.display_name()
		button.toggle_mode = true
		button.focus_entered.connect(show_member.bind(m))
		button.pressed.connect(show_member.bind(m))
		_members.add_child(button)
		_buttons.append(button)
	if members.is_empty():
		shown = null
		return
	show_member(member if member in members else members[0])


## Shows one member's page.
func show_member(member: PartyMember) -> void:
	shown = member
	var members: Array[PartyMember] = GameState.party.members
	for i: int in _buttons.size():
		_buttons[i].set_pressed_no_signal(i < members.size() and members[i] == member)
	var c: Combatant = member.combatant
	_portrait.texture = member.data.portrait
	_name.text = member.display_name()
	_level.text = "Level %d" % member.level if c.is_alive() else "Level %d    Fallen" % member.level
	var into: Vector2i = xp_progress(member)
	_xp_bar.set_values(into.x, into.y)
	_next.text = "Next level: —" if member.xp_to_next_level() <= 0 else "Next level: %d XP" % member.xp_to_next_level()
	_hp_bar.set_values(c.hp, c.max_hp())
	_mp_bar.set_values(c.mp, c.max_mp())
	_fill_stats(c)
	_fill_tags(_resistances, resistance_tags(c), "None")
	_fill_statuses(c)
	var names: PackedStringArray = []
	for skill: SkillData in member.skills():
		names.append(skill.display_name)
	_skills.text = ", ".join(names) if not names.is_empty() else "—"


## XP earned within the current level and XP that level needs (x = y at the level cap).
static func xp_progress(member: PartyMember) -> Vector2i:
	var growth: GrowthCurve = member.data.growth
	var needed: int = Progression.xp_to_next(growth, member.level)
	if needed <= 0:
		return Vector2i(1, 1)
	return Vector2i(member.xp - Progression.total_xp_for_level(growth, member.level), needed)


## One {text, color} per element the combatant does not take normally ("Resist Fire", "Weak Holy").
static func resistance_tags(c: Combatant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for element: Elements.Element in Elements.Element.values():
		var mult: float = c.affinity(element)
		var word: String = ""
		if Elements.is_immune(mult):
			word = "Immune"
		elif Elements.is_weak(mult):
			word = "Weak"
		elif Elements.is_resisted(mult):
			word = "Resist"
		if not word.is_empty():
			out.append({&"text": "%s %s" % [word, Elements.name_of(element)], &"color": element_color(element)})
	return out


## Palette colour of an element (ART_GUIDELINES.md: Fire ember, Frost mana, Lightning
## parchment_light, Holy gold, Shadow curse).
static func element_color(element: Elements.Element) -> Color:
	match element:
		Elements.Element.FIRE:
			return PALETTE.ember
		Elements.Element.FROST:
			return PALETTE.mana
		Elements.Element.LIGHTNING:
			return PALETTE.parchment_light
		Elements.Element.HOLY:
			return PALETTE.gold
		Elements.Element.SHADOW:
			return PALETTE.curse
	return PALETTE.parchment


## "Knight Lv 3, Warden Lv 3" (tests, the pause menu summary).
func summary_text() -> String:
	var parts: PackedStringArray = []
	for member: PartyMember in GameState.party.members:
		parts.append("%s Lv %d" % [member.display_name(), member.level])
	return ", ".join(parts)


## The shown value of a stat in the grid (tests).
func stat_text(stat: StringName) -> String:
	var value: Label = _stats.get_node_or_null(NodePath(String(stat))) as Label
	return value.text if value != null else ""


## The shown portrait (tests).
func portrait() -> Texture2D:
	return _portrait.texture


func xp_bar() -> StatBar:
	return _xp_bar


func member_buttons() -> Array[Button]:
	return _buttons


func _fill_stats(c: Combatant) -> void:
	for child: Node in _stats.get_children():
		_stats.remove_child(child)
		child.queue_free()
	for stat: StringName in STAT_LABELS:
		var label: Label = Label.new()
		label.text = STAT_LABELS[stat]
		label.theme_type_variation = &"SmallLabel"
		_stats.add_child(label)
		var value: Label = Label.new()
		value.name = String(stat)
		value.text = str(c.effective_stat(stat))
		value.theme_type_variation = &"NumericLabel"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.custom_minimum_size = Vector2(64, 0)
		_stats.add_child(value)


func _fill_tags(box: HFlowContainer, tags: Array[Dictionary], empty_text: String) -> void:
	_clear(box)
	if tags.is_empty():
		box.add_child(_tag(empty_text, PALETTE.parchment_dim))
		return
	for tag: Dictionary in tags:
		box.add_child(_tag(tag[&"text"] as String, tag[&"color"] as Color))


func _fill_statuses(c: Combatant) -> void:
	_clear(_statuses)
	if c.statuses.is_empty():
		_statuses.add_child(_tag("None", PALETTE.parchment_dim))
		return
	for status: ActiveStatus in c.statuses:
		var data: StatusEffectData = status.data
		if data.icon != null:
			var icon: TextureRect = TextureRect.new()
			icon.texture = data.icon
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = STATUS_ICON_SIZE
			icon.tooltip_text = data.display_name
			_statuses.add_child(icon)
		_statuses.add_child(_tag(data.display_name, data.tag_color))


func _tag(text: String, color: Color) -> Label:
	var tag: Label = Label.new()
	tag.text = text
	tag.theme_type_variation = &"SmallLabel"
	tag.add_theme_color_override(&"font_color", color)
	return tag


static func _clear(box: Node) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()
