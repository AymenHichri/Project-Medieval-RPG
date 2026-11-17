class_name UiSounds
extends RefCounted
## Wires the UI sounds into Theme-driven widgets (PROJECT_PLAN.md Phase 7): `UiSounds.attach(root)`
## makes every BaseButton and Slider under `root` play "focus" when focused and "confirm" when
## pressed. Screens play "cancel" themselves when they close on `cancel`. The sounds are the
## named UI sets of `SFXManager.library` (silent until the slice audio is added).

const ATTACHED_META: StringName = &"ui_sounds_attached"


## Connects every button and slider under `root` (once per control).
static func attach(root: Node) -> void:
	for node: Node in root.find_children("*", "Control", true, false):
		_attach_control(node as Control)
	if root is Control:
		_attach_control(root as Control)


static func focus() -> void:
	AudioManager.sfx.play_ui_named(&"focus")


static func confirm() -> void:
	AudioManager.sfx.play_ui_named(&"confirm")


static func cancel() -> void:
	AudioManager.sfx.play_ui_named(&"cancel")


static func tick() -> void:
	AudioManager.sfx.play_ui_named(&"tick")


static func _attach_control(control: Control) -> void:
	if not (control is BaseButton or control is Slider) or control.has_meta(ATTACHED_META):
		return
	control.set_meta(ATTACHED_META, true)
	control.focus_entered.connect(focus)
	if control is BaseButton:
		(control as BaseButton).pressed.connect(confirm)
