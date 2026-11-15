class_name CommandMenu
extends Control
## The party command menu (PROJECT_PLAN.md §6.5): Attack / Skills / Magic / Items / Defend / Flee on
## Gimble's iron panel with dfgui ×2 icons, plus a sub-panel listing skills (MP cost, greyed when
## unaffordable) or items (count). Every `choose_*` call is awaited and returns null / &"" when
## the player cancels, so the controller can step back.

const ICON_DIR: String = "res://assets/vendor/dfgui/2x/"
## Command id → [label, dfgui icon file or "" for text only].
const COMMANDS: Array[StringName] = [&"attack", &"skills", &"magic", &"items", &"defend", &"flee"]
const LABELS: Dictionary[StringName, String] = {
	&"attack": "Attack", &"skills": "Skills", &"magic": "Magic",
	&"items": "Items", &"defend": "Defend", &"flee": "Flee",
}
const ICONS: Dictionary[StringName, String] = {
	&"attack": "dfgui_icon-sword.png", &"skills": "dfgui_icon-skillbook.png", &"magic": "dfgui_icon-wand.png",
	&"items": "dfgui_icon-pouch.png", &"defend": "dfgui_icon-shield.png",
}

@onready var _command_panel: PanelContainer = %CommandPanel
@onready var _member_name: Label = %MemberName
@onready var _commands: MenuList = %Commands
@onready var _sub_panel: PanelContainer = %SubPanel
@onready var _sub_title: Label = %SubTitle
@onready var _sub: MenuList = %Sub
@onready var _description: Label = %Description


func _ready() -> void:
	_sub.highlighted.connect(_on_sub_highlighted)
	close()


## Shows the commands for `member` and waits for one (&"" = cancel, i.e. back to the previous
## member; only possible when `allow_back`). Disabled: Skills/Magic without such skills, Items
## when the bag is empty, Flee when the battle forbids it.
func choose_command(member: Combatant, can_flee: bool, has_items: bool, allow_back: bool,
		last: StringName = &"attack") -> StringName:
	_command_panel.visible = true
	_sub_panel.visible = false
	_member_name.text = member.display_name
	var entries: Array[Dictionary] = []
	for id: StringName in COMMANDS:
		var enabled: bool = true
		match id:
			&"skills":
				enabled = not skills_of(member, SkillData.Category.SKILL).is_empty()
			&"magic":
				enabled = not skills_of(member, SkillData.Category.MAGIC).is_empty()
			&"items":
				enabled = has_items
			&"flee":
				enabled = can_flee
		var icon: Texture2D = load(ICON_DIR + ICONS[id]) as Texture2D if ICONS.has(id) else null
		entries.append(MenuList.entry(LABELS[id], id, icon, "", enabled))
	_commands.set_entries(entries)
	_commands.allow_cancel = allow_back
	var start: int = _commands.index_of(last)
	var picked: Variant = await _commands.pick(start if _commands.is_enabled(start) else -1)
	return picked as StringName if picked != null else &""


## Lists `member`'s skills of `category` and waits for one (null = cancel).
func choose_skill(member: Combatant, category: SkillData.Category) -> SkillData:
	var entries: Array[Dictionary] = []
	for skill: SkillData in skills_of(member, category):
		entries.append(MenuList.entry(skill.display_name, skill, null, "%d MP" % skill.mp_cost,
				member.mp >= skill.mp_cost))
	_open_sub("Skills" if category == SkillData.Category.SKILL else "Magic", entries)
	var picked: Variant = await _sub.pick()
	_sub_panel.visible = false
	return picked as SkillData


## Lists the battle-usable items with their counts and waits for one (null = cancel).
func choose_item(items: Dictionary[ItemData, int]) -> ItemData:
	var entries: Array[Dictionary] = []
	for item: ItemData in items:
		if items[item] > 0 and item.usable_in_battle:
			entries.append(MenuList.entry(item.display_name, item, item.icon, "×%d" % items[item]))
	_open_sub("Items", entries)
	var picked: Variant = await _sub.pick()
	_sub_panel.visible = false
	return picked as ItemData


func close() -> void:
	_command_panel.visible = false
	_sub_panel.visible = false


## The command list (tests drive it with `press()`).
func commands() -> MenuList:
	return _commands


## The skill / item list.
func sub_menu() -> MenuList:
	return _sub


static func skills_of(member: Combatant, category: SkillData.Category) -> Array[SkillData]:
	var out: Array[SkillData] = []
	for skill: SkillData in member.skills:
		if skill.category == category:
			out.append(skill)
	return out


func _open_sub(title: String, entries: Array[Dictionary]) -> void:
	_sub_title.text = title
	_sub.set_entries(entries)
	_sub_panel.visible = true
	_on_sub_highlighted(_sub.selected_value())


func _on_sub_highlighted(value: Variant) -> void:
	var text: String = ""
	if value is SkillData:
		text = (value as SkillData).description
	elif value is ItemData:
		text = (value as ItemData).description
	_description.text = text
