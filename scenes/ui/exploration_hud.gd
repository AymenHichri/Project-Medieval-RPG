class_name ExplorationHud
extends CanvasLayer
## Minimal exploration HUD (PROJECT_PLAN.md §6.5): the dfgui MENU button in the top-right corner,
## which opens the pause menu (as does the `menu` action). Mouse only: the keyboard and gamepad
## use `menu`. Phase 10: a short notice at the top when a quest starts, moves on or is completed.

signal menu_pressed

## How long a notice stays, then how long it fades.
const NOTICE_SECONDS: float = 3.0
const NOTICE_FADE_SECONDS: float = 0.6

@onready var menu_button: TextureButton = %MenuButton
@onready var notice: PanelContainer = %Notice
@onready var _notice_text: Label = %NoticeText

var _notice_tween: Tween


func _ready() -> void:
	menu_button.pressed.connect(menu_pressed.emit)
	UiSounds.attach(menu_button)
	notice.visible = false
	GameState.quests_changed.connect(_on_quests_changed)


## Shows `text` at the top of the screen for a few seconds.
func show_notice(text: String) -> void:
	_notice_text.text = text
	notice.visible = true
	notice.modulate.a = 1.0
	if _notice_tween != null:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(NOTICE_SECONDS)
	_notice_tween.tween_property(notice, ^"modulate:a", 0.0, NOTICE_FADE_SECONDS)
	_notice_tween.tween_callback(notice.hide)


## The notice for a quest change: new, moved on, or completed.
static func quest_notice(quest: QuestData, quests: QuestLog) -> String:
	if quests.is_completed(quest.id):
		return "Quest complete: %s" % quest.title
	if quests.stage_index(quest.id) == 0:
		return "New quest: %s" % quest.title
	return "Journal updated: %s" % quest.title


func _on_quests_changed(quest: QuestData) -> void:
	show_notice(quest_notice(quest, GameState.quests))
	AudioManager.sfx.play_ui_named(&"open")
