class_name PauseMenu
extends CanvasLayer
## Exploration pause menu (PROJECT_PLAN.md Phase 7): opened with `menu` (or the HUD's MENU button)
## while the player can act. Pauses the game. Gimble's panel with a tab bar (Party: StatusPage,
## Phase 8; Items: InventoryPage and Equipment: EquipmentPage, Phase 9; Journal: JournalPage and
## Map: MapPage, Phase 10), the gold, and Resume / Settings / Quit to Title. The tab bar
## takes focus (left/right switches tabs). `cancel` steps back inside a page first (choosing a
## target or a piece of gear), else closes the menu; `menu` always closes it.

signal opened
signal closed

## Tabs in order.
const TABS: PackedStringArray = ["Party", "Items", "Equipment", "Journal", "Map"]
const TAB_PARTY: int = 0
const TAB_ITEMS: int = 1
const TAB_EQUIPMENT: int = 2
const TAB_JOURNAL: int = 3
const TAB_MAP: int = 4

@onready var _tabs: TabBar = %Tabs
@onready var status_page: StatusPage = %StatusPage
@onready var inventory_page: InventoryPage = %InventoryPage
@onready var equipment_page: EquipmentPage = %EquipmentPage
@onready var journal_page: JournalPage = %JournalPage
@onready var map_page: MapPage = %MapPage
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
	_tabs.tab_changed.connect(show_tab)
	_resume.pressed.connect(close)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	settings_menu.closed.connect(_on_settings_closed)
	GameState.gold_changed.connect(_on_gold_changed)
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


## Rewrites the shown tab and the gold from GameState.
func refresh() -> void:
	show_tab(_tabs.current_tab)


## Shows one tab's page and refreshes it.
func show_tab(tab: int) -> void:
	if _tabs.current_tab != tab:
		_tabs.set_current_tab(tab)  # Emits tab_changed, which calls this again.
		return
	status_page.visible = tab == TAB_PARTY
	inventory_page.visible = tab == TAB_ITEMS
	equipment_page.visible = tab == TAB_EQUIPMENT
	journal_page.visible = tab == TAB_JOURNAL
	map_page.visible = tab == TAB_MAP
	match tab:
		TAB_PARTY:
			status_page.refresh(status_page.shown)
		TAB_ITEMS:
			inventory_page.refresh()
		TAB_EQUIPMENT:
			equipment_page.refresh()
		TAB_JOURNAL:
			journal_page.refresh()
		TAB_MAP:
			map_page.refresh()
	_refresh_gold()


func current_tab() -> int:
	return _tabs.current_tab


func _on_gold_changed(_gold_now: int) -> void:
	_refresh_gold()


func _refresh_gold() -> void:
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
	if event.is_action_pressed(&"cancel") and _page_steps_back():
		get_viewport().set_input_as_handled()
		UiSounds.cancel()
		_refresh_gold()
		return
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"menu"):
		get_viewport().set_input_as_handled()
		UiSounds.cancel()
		close()


## Lets the shown page undo its sub-step (target or gear choice). True when it did.
func _page_steps_back() -> bool:
	if inventory_page.visible:
		return inventory_page.handle_cancel()
	if equipment_page.visible:
		return equipment_page.handle_cancel()
	return false
