class_name DamagePopup
extends Label
## A rising number or word over a battler (PROJECT_PLAN.md §3): damage white, healing pale green,
## weakness crimson, MP blue. Frees itself when done.

enum Kind { DAMAGE, CRITICAL, HEAL, MP, WEAK, INFO }

const PALETTE: UIPalette = preload("res://scenes/ui/theme/ui_palette.tres")
## Rise (px) and duration (s); the popup fades out over the last FADE_SECONDS.
const RISE: float = 64.0
const SECONDS: float = 0.9
const FADE_SECONDS: float = 0.3
## Size of each kind relative to the DamageNumber style (48 px).
const SCALES: Dictionary[Kind, float] = {
	Kind.DAMAGE: 1.0, Kind.CRITICAL: 1.3, Kind.HEAL: 1.0, Kind.MP: 0.85, Kind.WEAK: 0.7, Kind.INFO: 0.6,
}


## Colour of a popup kind (statuses pass their own colour to `show_at`).
static func color_of(kind: Kind) -> Color:
	match kind:
		Kind.HEAL:
			return PALETTE.heal.lightened(0.35)
		Kind.MP:
			return PALETTE.mana.lightened(0.3)
		Kind.WEAK:
			return PALETTE.blood_bright
		Kind.CRITICAL:
			return PALETTE.gold
		Kind.INFO:
			return PALETTE.parchment
	return Color.WHITE


## Shows `message` centred on `at` (canvas px) and starts rising. `color` overrides the kind colour.
func show_at(message: String, kind: Kind, at: Vector2, color: Color = Color.TRANSPARENT) -> void:
	text = message
	add_theme_color_override(&"font_color", color if color.a > 0.0 else color_of(kind))
	scale = Vector2.ONE * SCALES[kind]
	reset_size()
	pivot_offset = size / 2.0
	position = at - size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"position:y", position.y - RISE, SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(self, ^"modulate:a", 0.0, FADE_SECONDS).set_delay(SECONDS - FADE_SECONDS)
	tween.finished.connect(queue_free)
