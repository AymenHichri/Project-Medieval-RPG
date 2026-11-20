class_name PauseMenu
extends CanvasLayer
## Exploration pause menu (PROJECT_PLAN.md Phase 7): opened with `menu` (or the HUD's MENU button)
## while the player can act. Pauses the game. Gimble's panel with a tab list (Party now; Items,
## Equipment and Journal arrive in Phases 9–10 and are shown disabled), the Party tab's status
## page (Phase 8: StatusPage), and Resume / Settings / Quit to Title. `cancel` or `menu` closes it
## (or the settings page first).

signal opened
signal closed

## Tabs in order; only the first exists so far.
const TABS: PackedStringArray = ["Party", "Items", "Equipment", "Journal"]

@onready var _tabs: TabBar = %Tabs
@onready var status_page: StatusPage = %StatusPage
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


## Rewrites the Party tab and the gold from GameState.
func refresh() -> void:
	status_page.refresh(status_page.shown)
	_gold.text = "Gold  %d" % GameState.gold


## "Knight Lv 1, Warden Lv 1" (tests).
func summary_text() -> String:
	return status_page.summary_text()


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
