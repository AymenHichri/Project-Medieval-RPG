class_name PauseMenu
extends CanvasLayer
## Exploration pause menu (PROJECT_PLAN.md Phase 7): opened with `menu` (or the HUD's MENU button)
## while the player can act. Pauses the game. Gimble's panel with a tab list (Party now; Items,
## Equipment and Journal arrive in Phases 8–10 and are shown disabled), a party summary, and
## Resume / Settings / Quit to Title. `cancel` or `menu` closes it (or the settings page first).

signal opened
signal closed

## Tabs in order; only the first exists in Phase 7.
const TABS: PackedStringArray = ["Party", "Items", "Equipment", "Journal"]

@onready var _tabs: TabBar = %Tabs
@onready var _summary: Label = %Summary
@onready var _gold: Label = %Gold
@onready var _resume: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit: Button = %QuitButton
@onready var _panel: Control = %Panel
@onready var settings_menu: SettingsMenu = %SettingsMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in TABS.size():
		_tabs.add_tab(TABS[i])
		_tabs.set_tab_disabled(i, i > 0)
	_resume.pressed.connect(close)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	settings_menu.closed.connect(_on_settings_closed)
	UiSounds.attach(_panel)
	visible = false


func is_open() -> bool:
	return visible


## Opens and pauses the game (ignored when already open).
func open() -> void:
	if visible:
		return
	refresh()
	visible = true
	_panel.visible = true
	get_tree().paused = true
	AudioManager.sfx.play_ui_named(&"open")
	AudioManager.set_ambience_muffled(true)
	_resume.grab_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	settings_menu.close()
	visible = false
	get_tree().paused = false
	AudioManager.set_ambience_muffled(false)
	closed.emit()


## Rewrites the party summary from GameState.
func refresh() -> void:
	var lines: PackedStringArray = []
	for member: PartyMember in GameState.party.members:
		var c: Combatant = member.combatant
		lines.append("%s    Lv %d" % [member.display_name(), member.level])
		lines.append("HP %d / %d    MP %d / %d" % [c.hp, c.max_hp(), c.mp, c.max_mp()])
		var next: int = member.xp_to_next_level()
		lines.append("Next level: %s" % ("—" if next <= 0 else "%d XP" % next))
	_summary.text = "\n".join(lines)
	_gold.text = "Gold  %d" % GameState.gold


func summary_text() -> String:
	return _summary.text


func _on_settings_pressed() -> void:
	_panel.visible = false
	settings_menu.open()


func _on_settings_closed() -> void:
	_panel.visible = true
	_settings_button.grab_focus()


func _on_quit_pressed() -> void:
	_quit.disabled = true
	visible = false
	get_tree().paused = false
	AudioManager.set_ambience_muffled(false)
	closed.emit()
	SceneManager.to_title()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if settings_menu.visible:
		return  # The settings page handles its own `cancel`.
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"menu"):
		get_viewport().set_input_as_handled()
		UiSounds.cancel()
		close()
