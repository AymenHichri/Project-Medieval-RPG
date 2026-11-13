class_name FadeOverlay
extends CanvasLayer
## Full-screen fade used by SceneManager for all transitions.

@onready var _rect: ColorRect = %Rect


## Fade the overlay alpha to `alpha` over `duration` seconds (0 = immediate).
func fade_to(alpha: float, duration: float) -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.0 else Control.MOUSE_FILTER_IGNORE
	if duration <= 0.0:
		_rect.modulate.a = alpha
		return
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
