class_name BattleHud
extends PanelContainer
## The party panel at the bottom of the battle screen (PROJECT_PLAN.md §6.5): per member a name,
## HP and MP StatBars and the active statuses (Gimble's 64 px HUD icons drawn at 32 px, or a text
## tag such as "SLP" for statuses without an icon). The presenter feeds it the HP/MP to show, so
## numbers change when each hit is shown, not when the engine resolved it.

const STAT_BAR: PackedScene = preload("res://scenes/ui/widgets/stat_bar.tscn")
const PALETTE: UIPalette = preload("res://scenes/ui/theme/ui_palette.tres")
const NAME_WIDTH: float = 200.0
const STATUS_ICON_SIZE: Vector2 = Vector2(32, 32)
const STATUS_WIDTH: float = 180.0

var _rows: Dictionary[Combatant, Dictionary] = {}

@onready var _list: VBoxContainer = %Rows


## Builds one row per party member, showing their current HP/MP.
func bind(party: Array[Combatant]) -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_rows.clear()
	for member: Combatant in party:
		_add_row(member)
		show_values(member, member.hp, member.mp)
		refresh_statuses(member)


func show_values(member: Combatant, hp: int, mp: int, animate: bool = false) -> void:
	if not _rows.has(member):
		return
	var row: Dictionary = _rows[member]
	(row[&"hp"] as StatBar).set_values(hp, member.max_hp(), animate)
	(row[&"mp"] as StatBar).set_values(mp, member.max_mp(), animate)
	var name_label: Label = row[&"name"] as Label
	name_label.modulate = Color.WHITE if hp > 0 else Color(1, 1, 1, 0.5)


## Redraws the status icons/tags from the member's live statuses.
func refresh_statuses(member: Combatant) -> void:
	if not _rows.has(member):
		return
	var box: HBoxContainer = _rows[member][&"statuses"] as HBoxContainer
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()
	for status: ActiveStatus in member.statuses:
		box.add_child(_status_badge(status.data))


## Highlights the member whose command is being chosen (null = nobody).
func set_active(member: Combatant) -> void:
	for c: Combatant in _rows:
		var label: Label = _rows[c][&"name"] as Label
		label.add_theme_color_override(&"font_color", PALETTE.gold if c == member else PALETTE.parchment)


func hp_bar(member: Combatant) -> StatBar:
	return _rows[member][&"hp"] as StatBar if _rows.has(member) else null


func mp_bar(member: Combatant) -> StatBar:
	return _rows[member][&"mp"] as StatBar if _rows.has(member) else null


func status_count(member: Combatant) -> int:
	return (_rows[member][&"statuses"] as HBoxContainer).get_child_count() if _rows.has(member) else 0


func _add_row(member: Combatant) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	_list.add_child(row)
	var name_label: Label = Label.new()
	name_label.text = member.display_name
	name_label.theme_type_variation = &"NameLabel"
	name_label.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)
	var hp: StatBar = _bar(row, StatBar.Style.PARTY_HP)
	var mp: StatBar = _bar(row, StatBar.Style.PARTY_MP)
	var statuses: HBoxContainer = HBoxContainer.new()
	statuses.custom_minimum_size = Vector2(STATUS_WIDTH, 0)
	statuses.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_child(statuses)
	_rows[member] = {&"name": name_label, &"hp": hp, &"mp": mp, &"statuses": statuses}


func _bar(row: HBoxContainer, style: StatBar.Style) -> StatBar:
	var bar: StatBar = STAT_BAR.instantiate() as StatBar
	bar.style = style
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	return bar


func _status_badge(data: StatusEffectData) -> Control:
	if data.icon != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = data.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = STATUS_ICON_SIZE
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.tooltip_text = data.display_name
		return icon
	var tag: Label = Label.new()
	tag.text = data.tag_text if not data.tag_text.is_empty() else data.display_name.left(3).to_upper()
	tag.theme_type_variation = &"SmallLabel"
	tag.add_theme_color_override(&"font_color", data.tag_color)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return tag
