class_name JournalPage
extends HBoxContainer
## The pause menu's Journal tab (PROJECT_PLAN.md Phase 10): active and completed quests on the left;
## for the chosen one its title (with Gimble's `51_quest` icon), giver and summary, the current stage
## in a LoreLabel (with "2/3" progress for stages that need several things done), and the stages
## already done. Dark panel styling: no parchment page has been sourced (UI_ASSET_CATALOG.md).
## Reads GameState.quests; never changes it.

const DONE_MARK: String = "✓ "
const EMPTY_TEXT: String = "No quests yet. Folk in the village may need a hand."

## The quest whose page is shown (null when there are none).
var shown: QuestData

var _buttons: Dictionary[QuestData, Button] = {}

@onready var _active: VBoxContainer = %Active
@onready var _completed: VBoxContainer = %Completed
@onready var _completed_header: Label = %CompletedHeader
@onready var _detail: VBoxContainer = %Detail
@onready var _empty: Label = %Empty
@onready var _title: Label = %QuestTitle
@onready var _giver: Label = %Giver
@onready var _summary: Label = %Summary
@onready var _stage: Label = %Stage
@onready var _history: Label = %History


## Rebuilds the quest lists and shows `quest` (default: the shown one, else the first active one).
func refresh(quest: QuestData = null) -> void:
	for button: Button in _buttons.values():
		button.get_parent().remove_child(button)
		button.queue_free()
	_buttons.clear()
	var quests: QuestLog = GameState.quests
	var active: Array[QuestData] = quests.active_quests()
	var completed: Array[QuestData] = quests.completed_quests()
	for q: QuestData in active:
		_add_button(q, _active)
	for q: QuestData in completed:
		_add_button(q, _completed)
	_completed_header.visible = not completed.is_empty()
	var all: Array[QuestData] = active.duplicate()
	all.append_array(completed)
	_empty.visible = all.is_empty()
	_detail.visible = not all.is_empty()
	if all.is_empty():
		shown = null
		return
	var wanted: QuestData = quest if quest != null else shown
	var keep: QuestData = null
	for q: QuestData in all:
		if wanted != null and q.id == wanted.id:
			keep = q
	show_quest(keep if keep != null else all[0])


## Shows one quest's page.
func show_quest(quest: QuestData) -> void:
	shown = quest
	for q: QuestData in _buttons:
		_buttons[q].set_pressed_no_signal(q == quest)
	var quests: QuestLog = GameState.quests
	_title.text = quest.title
	_giver.text = "From %s" % quest.giver if not quest.giver.is_empty() else ""
	_giver.visible = not quest.giver.is_empty()
	_summary.text = quest.summary
	_stage.text = quests.stage_text(quest.id, GameState.flags)
	var done: PackedStringArray = []
	var reached: int = mini(quests.stage_index(quest.id), quest.stages.size())
	for i: int in reached:
		done.append(DONE_MARK + quest.stages[i].text)
	_history.text = "\n".join(done)
	_history.visible = not done.is_empty()


## The quest buttons in list order (tests).
func quest_buttons() -> Array[Button]:
	var out: Array[Button] = []
	for list: VBoxContainer in [_active, _completed]:
		for child: Node in list.get_children():
			if child is Button:
				out.append(child as Button)
	return out


## The shown page as plain text (tests).
func page_text() -> String:
	if shown == null:
		return _empty.text
	return "\n".join([_title.text, _giver.text, _summary.text, _stage.text, _history.text])


## The first quest button (the pause menu focuses it when the tab opens), or null.
func first_button() -> Button:
	var buttons: Array[Button] = quest_buttons()
	return buttons[0] if not buttons.is_empty() else null


func _add_button(quest: QuestData, list: VBoxContainer) -> void:
	var button: Button = Button.new()
	button.text = quest.title
	button.toggle_mode = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_entered.connect(show_quest.bind(quest))
	button.pressed.connect(show_quest.bind(quest))
	list.add_child(button)
	_buttons[quest] = button
