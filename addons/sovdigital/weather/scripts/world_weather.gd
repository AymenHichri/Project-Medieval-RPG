extends Node
## One node that runs wind, rain and snow for a whole scene with the four world shaders
## (wind_sway, cloth_wave, wet_surface, snow_cover).
##
## Use:
##   1. Add a WorldWeather node to your level.
##   2. Put sprites (Sprite2D, AnimatedSprite2D, TileMapLayer, ...) in groups:
##        "wind_sway"  plants and trees: WorldWeather gives them a wind_sway material (preset from the node's
##                     "wind_preset" meta: tree, bush, grass, reeds; default bush)
##        "cloth_wave" banners and flags: a cloth_wave material ("cloth_preset" meta: banner or flag; set the
##                     cloth box with a "cloth_rect" meta, Vector4(x, y, w, h) in 0..1 of the sprite; a pole that runs
##                     through the cloth box stays still with a "cloth_pole" meta, Vector3(centre x, half width, start
##                     down the box), e.g. Vector3(0.49, 0.05, 0.62) for a banner on a centre pole; or give a
##                     "cloth_mask" meta, a Texture2D whose grey says how much each pixel may move)
##        "weather"    everything that gets wet or snowed on (buildings, props, ground; give grounds the meta
##                     "ground" = true)
##   3. Call start_rain(), stop_rain(), start_snow(), thaw() or set wind_strength from your game.
## A sprite has one material: plants and cloth keep their wind material; rain and snow apply to "weather" sprites.
## Sprites that already have a ShaderMaterial with one of these shaders are left as they are and only driven.

const WIND := preload("../shaders/wind_sway.gdshader")
const CLOTH := preload("../shaders/cloth_wave.gdshader")
const WET := preload("../shaders/wet_surface.gdshader")
const SNOW := preload("../shaders/snow_cover.gdshader")

const PRESETS := {
	"tree": {"sway_px": 7.0, "bend": 1.8, "rooted": 0.3, "speed": 0.45, "flutter_px": 0.8, "margin_px": 20.0},
	"bush": {"sway_px": 3.0, "bend": 1.3, "rooted": 0.05, "speed": 0.7, "flutter_px": 0.6},
	"grass": {"sway_px": 5.0, "bend": 1.3, "rooted": 0.05, "speed": 0.8, "flutter_px": 0.6},
	"reeds": {"sway_px": 6.0, "bend": 1.6, "rooted": 0.05, "speed": 0.6, "flutter_px": 0.4},
	"banner": {"attach_edge": 0, "wave_px": 4.0, "speed": 1.0, "swing_px": 2.0},
	"flag": {"attach_edge": 1, "wave_px": 6.0, "speed": 1.4, "waves": 1.6},
}

@export_range(0.0, 3.0) var wind_strength := 1.0:
	set(v):
		wind_strength = v
		_apply_wind()
@export_range(-1.0, 1.0) var wind_direction := 1.0:
	set(v):
		wind_direction = v
		_apply_wind()
@export var drips_in_rain := 0.4          ## water streaks on buildings while it rains (0 = off)

var wetness := 0.0
var snow := 0.0
var _tween: Tween


func _ready() -> void:
	for n in get_tree().get_nodes_in_group("wind_sway"):
		_setup(n, WIND, PRESETS.get(n.get_meta("wind_preset", "bush"), PRESETS["bush"]))
	for n in get_tree().get_nodes_in_group("cloth_wave"):
		var p: Dictionary = PRESETS.get(n.get_meta("cloth_preset", "banner"), PRESETS["banner"]).duplicate()
		if n.has_meta("cloth_rect"):
			p["cloth_rect"] = n.get_meta("cloth_rect")
		if n.has_meta("cloth_pole"):
			p["pole"] = n.get_meta("cloth_pole")
		if n.has_meta("cloth_mask"):
			p["cloth_mask"] = n.get_meta("cloth_mask")
			p["use_cloth_mask"] = true
		_setup(n, CLOTH, p)
	_apply_wind()


## Rain soaks in over `seconds`.
func start_rain(seconds := 3.0) -> Tween:
	return _weather_to(WET, "wetness", 1.0, seconds)


## The rain stops and everything dries over `seconds`.
func stop_rain(seconds := 8.0) -> Tween:
	return _weather_to(WET, "wetness", 0.0, seconds)


## Snow settles over `seconds` (roofs, tree tops and ground first).
func start_snow(seconds := 10.0, heavy := 1.0) -> Tween:
	return _weather_to(SNOW, "amount", heavy, seconds)


## The snow melts away over `seconds`.
func thaw(seconds := 10.0) -> Tween:
	return _weather_to(SNOW, "amount", 0.0, seconds)


func _setup(n: Node, shader: Shader, params: Dictionary) -> void:
	var ci := n as CanvasItem
	if ci == null:
		return
	var m := ci.material as ShaderMaterial
	if m == null or m.shader != shader:
		m = ShaderMaterial.new()
		m.shader = shader
		for k in params:
			m.set_shader_parameter(k, params[k])
		ci.material = m
	else:
		ci.material = m.duplicate()


func _apply_wind() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("wind_sway"):
		var m := (n as CanvasItem).material as ShaderMaterial
		if m and m.shader == WIND:
			var base: Dictionary = PRESETS.get(n.get_meta("wind_preset", "bush"), PRESETS["bush"])
			m.set_shader_parameter("sway_px", float(base["sway_px"]) * wind_strength)
			m.set_shader_parameter("wind_direction", wind_direction)
	for n in get_tree().get_nodes_in_group("cloth_wave"):
		var m := (n as CanvasItem).material as ShaderMaterial
		if m and m.shader == CLOTH:
			var base: Dictionary = PRESETS.get(n.get_meta("cloth_preset", "banner"), PRESETS["banner"])
			m.set_shader_parameter("wave_px", float(base["wave_px"]) * clampf(wind_strength, 0.2, 2.0))
			m.set_shader_parameter("speed", float(base["speed"]) * clampf(0.6 + 0.4 * wind_strength, 0.3, 2.0))


func _weather_to(shader: Shader, param: String, target: float, seconds: float) -> Tween:
	if _tween and _tween.is_running():
		_tween.kill()
	var start := wetness if shader == WET else snow
	# Switch "weather" sprites to the right material, keeping their current look.
	for n in get_tree().get_nodes_in_group("weather"):
		var ci := n as CanvasItem
		if ci == null:
			continue
		var m := ci.material as ShaderMaterial
		if m == null or m.shader != shader:
			if not ci.has_meta("_dry_material"):
				ci.set_meta("_dry_material", ci.material)
			m = ShaderMaterial.new()
			m.shader = shader
			m.set_shader_parameter(param, start)
			m.set_shader_parameter("ground_mode", bool(ci.get_meta("ground", false)))
			if shader == WET and not bool(ci.get_meta("ground", false)):
				m.set_shader_parameter("drips", drips_in_rain)
			ci.material = m
	_tween = create_tween()
	_tween.tween_method(func(v: float) -> void: _set_weather(shader, param, v), start, target, maxf(seconds, 0.01))
	_tween.finished.connect(_on_weather_done.bind(target))
	return _tween


func _on_weather_done(target: float) -> void:
	if target <= 0.0:
		_restore()


func _set_weather(shader: Shader, param: String, v: float) -> void:
	if shader == WET:
		wetness = v
	else:
		snow = v
	for n in get_tree().get_nodes_in_group("weather"):
		var m := (n as CanvasItem).material as ShaderMaterial
		if m and m.shader == shader:
			m.set_shader_parameter(param, v)


func _restore() -> void:
	for n in get_tree().get_nodes_in_group("weather"):
		var ci := n as CanvasItem
		if ci and ci.has_meta("_dry_material"):
			ci.material = ci.get_meta("_dry_material")
			ci.remove_meta("_dry_material")
