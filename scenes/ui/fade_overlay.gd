class_name FadeOverlay
extends CanvasLayer
## Full-screen fade used by SceneManager for all transitions.

## The running fade. A new fade first jumps it to its end (so whoever awaits it resumes):
## a battle starts while its fade-in still runs.
var _tween: Tween

@onready var _rect: ColorRect = %Rect


## Fade the overlay alpha to `alpha` over `duration` seconds (0 = immediate).
func fade_to(alpha: float, duration: float) -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.0 else Control.MOUSE_FILTER_IGNORE
	if _tween != null and _tween.is_valid() and _tween.is_running():
		_tween.custom_step(1000.0)
	if duration <= 0.0:
		_rect.modulate.a = alpha
		return
	var tween: Tween = create_tween()
	_tween = tween
	tween.tween_property(_rect, "modulate:a", alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


## Battle intro: `count` quick pale flashes over the screen, then the fade colour is restored.
func flash(count: int = 2, duration: float = 0.12, color: Color = Color(0.92, 0.88, 0.82)) -> void:
	if duration <= 0.0 or count <= 0:
		return
	var base: Color = _rect.color
	_rect.color = color
	for i: int in count:
		var tween: Tween = create_tween()
		tween.tween_property(_rect, "modulate:a", 0.85, duration * 0.5)
		tween.tween_property(_rect, "modulate:a", 0.0, duration * 0.5)
		await tween.finished
	_rect.color = base
