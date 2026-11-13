extends Node
## AMBIENCE CONTROLLER (time of day + weather moods) - one node per level.
##
## Presets: day, golden_hour, dusk, night, storm, fog, blood_moon. A preset sets, in one smooth blend:
##   - the CanvasModulate colour (how light or dark the whole level is) and the screen grade (exposure, contrast,
##     saturation, shadow / highlight tint, vignette),
##   - every lamp, torch and fire light (PointLight2D below `lights_root` or in the group "ambience_lamps"): their
##     strength follows the time of day and they flicker like flames,
##   - the kit's other nodes by group: "ambience_fog" (fog_layer), "ambience_clouds" (cloud_shadows),
##     "ambience_sun" / "ambience_moon" (sunbeams, moonlight, light_shafts), "ambience_smoke" (smoke_plume),
##     plus light_fx.gd lights (street lamps, neon ...) that switch on at dusk,
##   - the global shader parameter `tod_night` (0 day .. 1 night) for shaders that read it (for example lit_windows of
##     Free Godot 4 Sprite Shaders: building windows light up by themselves),
##   - lightning flashes in the storm preset.
##
## Use:
##   1. Add a Node to your level, attach this script (no class name, so any number of our downloads can share a project).
##   2. It finds the level's CanvasModulate, a screen grade ColorRect and a "Lights" node by itself (or set the paths);
##      without a CanvasModulate or grade it makes its own.
##   3. From your game:  $Ambience.set_preset("dusk", 6.0)        # blend to dusk over 6 seconds
##                       $Ambience.start_day_cycle(6.0)           # run the clock from 06:00 (cycle_minutes per day)
##                       $Ambience.time_of_day = 19.5             # jump the clock
##   keep_scene_look = true keeps the colours the scene already has as its look for `preset` (nothing changes at start).
## A command-line argument `ambience=<preset>` (after `--`) picks the preset at start, for recordings.

signal preset_changed(name: String)

const ORDER: Array[String] = ["day", "golden_hour", "dusk", "night", "storm", "fog", "blood_moon"]
const GRADE_SHADER := preload("../shaders/screen_grade.gdshader")
const TOD := &"tod_night"

## canvas = CanvasModulate colour; grade = screen grade values; lamps = 0..1 share of each lamp's night strength;
## night = tod_night; sun / moon / clouds / fog / smoke = factors on those nodes' own strength.
const PRESETS := {
	"day": {"canvas": Color(1.0, 0.98, 0.94), "exposure": 1.06, "contrast": 1.08, "saturation": 1.06,
		"shadow_tint": Vector3(0.94, 0.97, 1.05), "highlight_tint": Vector3(1.05, 1.01, 0.94), "vignette": 0.3,
		"vignette_color": Vector3(0.0, 0.0, 0.0), "lamps": 0.22, "night": 0.0, "sun": 1.0, "moon": 0.0, "clouds": 1.0,
		"fog": 0.55, "smoke": 1.0, "sun_color": Color(1.0, 0.96, 0.88), "moon_tint": Color(0.75, 0.85, 1.0), "lightning": 0.0},
	"golden_hour": {"canvas": Color(1.0, 0.83, 0.64), "exposure": 1.06, "contrast": 1.06, "saturation": 1.12,
		"shadow_tint": Vector3(0.9, 0.88, 1.06), "highlight_tint": Vector3(1.1, 0.98, 0.84), "vignette": 0.36,
		"vignette_color": Vector3(0.05, 0.02, 0.0), "lamps": 0.4, "night": 0.15, "sun": 1.3, "moon": 0.0, "clouds": 0.75,
		"fog": 0.65, "smoke": 1.05, "sun_color": Color(1.0, 0.72, 0.42), "moon_tint": Color(0.75, 0.85, 1.0), "lightning": 0.0},
	"dusk": {"canvas": Color(0.66, 0.58, 0.76), "exposure": 1.1, "contrast": 1.05, "saturation": 0.94,
		"shadow_tint": Vector3(0.84, 0.86, 1.14), "highlight_tint": Vector3(1.1, 0.93, 0.9), "vignette": 0.42,
		"vignette_color": Vector3(0.02, 0.0, 0.05), "lamps": 0.78, "night": 0.6, "sun": 0.35, "moon": 0.3, "clouds": 0.45,
		"fog": 0.85, "smoke": 1.0, "sun_color": Color(1.0, 0.55, 0.45), "moon_tint": Color(0.75, 0.82, 1.0), "lightning": 0.0},
	"night": {"canvas": Color(0.42, 0.48, 0.7), "exposure": 1.2, "contrast": 1.07, "saturation": 0.92,
		"shadow_tint": Vector3(0.8, 0.88, 1.12), "highlight_tint": Vector3(1.1, 1.0, 0.9), "vignette": 0.46,
		"vignette_color": Vector3(0.0, 0.0, 0.02), "lamps": 1.0, "night": 1.0, "sun": 0.0, "moon": 1.0, "clouds": 0.18,
		"fog": 1.0, "smoke": 0.9, "sun_color": Color(0.6, 0.7, 1.0), "moon_tint": Color(0.75, 0.85, 1.0), "lightning": 0.0},
	"storm": {"canvas": Color(0.6, 0.65, 0.73), "exposure": 1.08, "contrast": 1.12, "saturation": 0.72,
		"shadow_tint": Vector3(0.86, 0.94, 1.1), "highlight_tint": Vector3(1.0, 1.0, 1.04), "vignette": 0.5,
		"vignette_color": Vector3(0.0, 0.01, 0.03), "lamps": 0.8, "night": 0.7, "sun": 0.0, "moon": 0.0, "clouds": 1.7,
		"fog": 0.8, "smoke": 0.8, "sun_color": Color(0.7, 0.78, 0.9), "moon_tint": Color(0.75, 0.85, 1.0), "lightning": 1.0},
	"fog": {"canvas": Color(0.8, 0.82, 0.86), "exposure": 1.05, "contrast": 0.9, "saturation": 0.74,
		"shadow_tint": Vector3(1.0, 1.02, 1.06), "highlight_tint": Vector3(1.0, 1.0, 1.0), "vignette": 0.4,
		"vignette_color": Vector3(0.6, 0.63, 0.67), "lamps": 0.6, "night": 0.35, "sun": 0.3, "moon": 0.0, "clouds": 0.3,
		"fog": 1.7, "smoke": 1.1, "sun_color": Color(0.95, 0.95, 0.92), "moon_tint": Color(0.8, 0.85, 0.95), "lightning": 0.0},
	"blood_moon": {"canvas": Color(0.48, 0.28, 0.3), "exposure": 1.16, "contrast": 1.08, "saturation": 0.92,
		"shadow_tint": Vector3(0.95, 0.84, 0.95), "highlight_tint": Vector3(1.12, 0.92, 0.88), "vignette": 0.52,
		"vignette_color": Vector3(0.07, 0.0, 0.01), "lamps": 1.0, "night": 1.0, "sun": 0.0, "moon": 0.9, "clouds": 0.18,
		"fog": 1.0, "smoke": 0.9, "sun_color": Color(1.0, 0.4, 0.35), "moon_tint": Color(1.0, 0.42, 0.36), "lightning": 0.0},
}
## the clock: hour -> preset, blended in between
const CLOCK := [[0.0, "night"], [4.5, "night"], [6.0, "dusk"], [7.5, "golden_hour"], [9.5, "day"], [16.5, "day"],
	[18.5, "golden_hour"], [20.0, "dusk"], [21.5, "night"], [24.0, "night"]]

@export_enum("day", "golden_hour", "dusk", "night", "storm", "fog", "blood_moon") var preset := "day":
	set(v):
		preset = v
		if is_node_ready() and not _internal and PRESETS.has(v):   # set from code: jump straight to it
			day_cycle = false
			_blend_to(_preset_values(v), 0.0)
@export var blend_seconds := 3.0                        ## default blend time of set_preset()
@export var keep_scene_look := false                    ## the scene's own colours become the look of `preset`
@export_group("Day cycle")
@export var day_cycle := false                          ## run the clock (presets follow time_of_day)
@export_range(0.0, 24.0, 0.25) var time_of_day := 12.0
@export var cycle_minutes := 4.0                        ## real minutes for a full 24 hours
@export_group("Nodes")
@export var canvas_modulate: NodePath                   ## empty: the first CanvasModulate in the level (made if none)
@export var grade_rect: NodePath                        ## empty: a ColorRect with a grade shader in the level (made if none)
@export var create_grade := true
@export var lights_root: NodePath                       ## empty: a child of the level named "Lights", if any
@export var sun_light: NodePath                         ## optional DirectionalLight2D tinted by the preset
@export_group("Lamps and weather")
@export_range(0.0, 1.0) var flicker := 0.14             ## flame flicker of the lamps (0 = steady)
@export var lightning := true                           ## flashes in the storm preset
@export var lightning_every := 7.0                      ## seconds between flashes (randomised)
@export var publish_tod_night := true                   ## set the global shader parameter tod_night
@export_group("Example scenes")
@export var demo_keys := false                          ## keys 1-7 = presets, C = day cycle on / off
@export var show_hint := false                          ## a small key hint in the corner

var values := {}                                        ## the current blended look (read by light_fx.gd)
var _from := {}
var _to := {}
var _blend := 1.0
var _blend_len := 1.0
var _own := {}                                          ## the scene's own look (keep_scene_look)
var _canvas: CanvasModulate
var _grade: ShaderMaterial
var _grade_names := {}
var _lamps: Array = []                                  ## [light, night energy, scale, phase]
var _sun: DirectionalLight2D
var _noise := FastNoiseLite.new()
var _t := 0.0
var _scan := 0.0
var _flash := 0.0
var _next_flash := 0.8
var _storm_on := false
var _dirty := true
var _hint: Label
var _internal := false
var _last_night := -1.0
var _uniforms := {}                                     ## shader -> {uniform name: true}
const BASE_MOON := Color(0.75, 0.85, 1.0)               ## moon_tint of the night preset: moon nodes keep their colour there


func _enter_tree() -> void:
	add_to_group("ambience_controller")
	# before any other node's _ready, so shaders and scripts that use tod_night find it. A project that lists it in
	# Project Settings > Shader Globals already has it; otherwise it is registered here, once.
	# (Engine meta: shared by every copy of this script, e.g. one from a tileset and one from Weather Effects)
	if publish_tod_night and not Engine.has_meta("ambience_tod_night") and not ProjectSettings.has_setting("shader_globals/" + TOD):
		RenderingServer.global_shader_parameter_add(TOD, RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)
		# for this run only (not saved): scripts that look for tod_night in the project settings find it too
		ProjectSettings.set_setting("shader_globals/" + TOD, {"type": "float", "value": 0.0})
	Engine.set_meta("ambience_tod_night", true)


func _ready() -> void:
	_noise.frequency = 2.0
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2 and kv[0] == "ambience" and PRESETS.has(kv[1]):
			_internal = true
			preset = kv[1]
			_internal = false
			keep_scene_look = false
	_find_nodes()
	if keep_scene_look:
		_capture_own()
	values = _preset_values(preset)
	if day_cycle:
		values = _clock_values(time_of_day)
	_to = values.duplicate()
	_rescan()
	_apply()
	_resend.call_deferred()                             # once every node of the level is ready
	if show_hint:
		_make_hint()


## Blend to a preset ("day", "golden_hour", "dusk", "night", "storm", "fog", "blood_moon"); stops the day cycle.
func set_preset(name: String, seconds := -1.0) -> void:
	if not PRESETS.has(name):
		push_warning("Ambience: no preset '%s' (%s)" % [name, ", ".join(ORDER)])
		return
	day_cycle = false
	_internal = true
	preset = name
	_internal = false
	_blend_to(_preset_values(name), blend_seconds if seconds < 0.0 else seconds)
	preset_changed.emit(name)


## Run the clock from `hour` (0-24); cycle_minutes real minutes make one day.
func start_day_cycle(hour := -1.0) -> void:
	if hour >= 0.0:
		time_of_day = hour
	day_cycle = true
	_blend_to(_clock_values(time_of_day), 1.5)


func stop_day_cycle() -> void:
	day_cycle = false


## 0 day .. 1 night, as published in tod_night
func night_amount() -> float:
	return float(values.get("night", 0.0))


## share of their night strength that lamps have now (light_fx.gd reads it)
func lamp_level() -> float:
	return float(values.get("lamps", 0.0))


func refresh() -> void:
	## call after adding lamps or kit nodes at runtime (it also rescans by itself every 2 seconds)
	_rescan()


# ---------------------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	if day_cycle and cycle_minutes > 0.0:
		time_of_day = fmod(time_of_day + delta * 24.0 / (cycle_minutes * 60.0), 24.0)
		if _blend >= 1.0:
			values = _clock_values(time_of_day)
			_dirty = true
	if _blend < 1.0:
		_blend = minf(1.0, _blend + delta / _blend_len)
		var target := _clock_values(time_of_day) if day_cycle else _to
		values = _lerp_values(_from, target, smoothstep(0.0, 1.0, _blend))
		_dirty = true
	_scan += delta
	if _scan > 2.0:
		_scan = 0.0
		_rescan()
		_dirty = true
	_update_lightning(delta)
	if _dirty:
		_apply()
		_dirty = false
	_update_lamps()


func _unhandled_input(event: InputEvent) -> void:
	if not demo_keys or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.keycode
	if k >= KEY_1 and k <= KEY_7:
		set_preset(ORDER[k - KEY_1])
	elif k == KEY_C:
		if day_cycle:
			stop_day_cycle()
		else:
			start_day_cycle(5.0)
	_update_hint()


func _blend_to(target: Dictionary, seconds: float) -> void:
	_from = values.duplicate()
	_to = target
	_blend_len = maxf(seconds, 0.001)
	_blend = 0.0 if seconds > 0.0 else 1.0
	if _blend >= 1.0:
		values = target.duplicate()
		_dirty = true
	_update_hint()


func _preset_values(name: String) -> Dictionary:
	if _own.has(name):
		return _own[name].duplicate()
	return PRESETS[name].duplicate()


func _clock_values(hour: float) -> Dictionary:
	for i in range(1, CLOCK.size()):
		if hour <= CLOCK[i][0]:
			var a: Array = CLOCK[i - 1]
			var b: Array = CLOCK[i]
			var u: float = 0.0 if b[0] == a[0] else (hour - a[0]) / (b[0] - a[0])
			return _lerp_values(_preset_values(a[1]), _preset_values(b[1]), smoothstep(0.0, 1.0, u))
	return _preset_values("night")


func _lerp_values(a: Dictionary, b: Dictionary, u: float) -> Dictionary:
	var out := {}
	for k in b:
		var va = a.get(k, b[k])
		var vb = b[k]
		if vb is Color or vb is Vector3:
			out[k] = va.lerp(vb, u)
		else:
			out[k] = lerpf(float(va), float(vb), u)
	return out


func _level() -> Node:
	return get_parent() if get_parent() else self


func _find_nodes() -> void:
	var level := _level()
	_canvas = get_node_or_null(canvas_modulate) as CanvasModulate if not canvas_modulate.is_empty() else null
	if _canvas == null:
		_canvas = _find_type(level, "CanvasModulate", 3) as CanvasModulate
	if _canvas == null:
		_canvas = CanvasModulate.new()
		_canvas.name = "AmbienceCanvasModulate"
		level.add_child.call_deferred(_canvas)
	var gr: CanvasItem = get_node_or_null(grade_rect) as CanvasItem if not grade_rect.is_empty() else null
	if gr == null:
		gr = _find_grade(level, 4)
	if gr == null and create_grade:
		var cl := CanvasLayer.new()
		cl.name = "AmbienceGrade"
		cl.layer = 10
		var cr := ColorRect.new()
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = GRADE_SHADER
		cr.material = m
		cl.add_child(cr)
		level.add_child.call_deferred(cl)
		gr = cr
	if gr and gr.material is ShaderMaterial:
		_grade = gr.material
		_grade_names.clear()
		for u in _grade.shader.get_shader_uniform_list():
			_grade_names[u["name"]] = true
	_sun = get_node_or_null(sun_light) as DirectionalLight2D if not sun_light.is_empty() else null


func _find_type(n: Node, type: String, depth: int) -> Node:
	for c in n.get_children():
		if c.is_class(type):
			return c
	if depth > 0:
		for c in n.get_children():
			var f := _find_type(c, type, depth - 1)
			if f:
				return f
	return null


func _find_grade(n: Node, depth: int) -> CanvasItem:
	for c in n.get_children():
		if c is ColorRect and c.material is ShaderMaterial and (c.material as ShaderMaterial).shader:
			for u in (c.material as ShaderMaterial).shader.get_shader_uniform_list():
				if u["name"] == "exposure":
					return c
	if depth > 0:
		for c in n.get_children():
			var f := _find_grade(c, depth - 1)
			if f:
				return f
	return null


func _capture_own() -> void:
	## the scene's tuned colours become its preset; lamp strengths are read back to their night strength
	var own: Dictionary = PRESETS[preset].duplicate()
	if _canvas:
		own["canvas"] = _canvas.color
	if _grade:
		for k in ["exposure", "contrast", "saturation", "vignette"]:
			var gv = _param(_grade, k) if _grade_names.has(k) else null
			if gv is float or gv is int:
				own[k] = float(gv)
		for k in ["shadow_tint", "highlight_tint", "vignette_color"]:
			if _grade_names.has(k):
				var v = _param(_grade, k)
				if v is Vector3:
					own[k] = v
	_own[preset] = own


func _rescan() -> void:
	var seen := {}
	for l in _lamps:
		if is_instance_valid(l[0]):
			seen[l[0]] = true
	var keep: Array = []
	for l in _lamps:
		if is_instance_valid(l[0]):
			keep.append(l)
	_lamps = keep
	var found: Array = []
	var root := get_node_or_null(lights_root) if not lights_root.is_empty() else _level().get_node_or_null("Lights")
	if root:
		_collect_lights(root, found)
	for n in get_tree().get_nodes_in_group("ambience_lamps"):
		if n is PointLight2D:
			found.append(n)
		else:
			_collect_lights(n, found)
	var own_lamps: float = maxf(float(_preset_values(preset).get("lamps", 1.0)), 0.05)
	for l in found:
		if seen.has(l) or l.has_meta("ambience_fx"):
			continue
		seen[l] = true
		var base: float = l.energy
		if l.has_meta("ambience_night_energy"):
			base = float(l.get_meta("ambience_night_energy"))
		elif keep_scene_look:
			base = l.energy / own_lamps          # the scene's lamps were tuned for its own preset
		l.set_meta("ambience_night_energy", base)
		_lamps.append([l, base, l.texture_scale, randf() * 100.0])


func _collect_lights(n: Node, out: Array) -> void:
	if n is PointLight2D:
		out.append(n)
	for c in n.get_children():
		_collect_lights(c, out)


func _base(n: Object, param: StringName, mat: ShaderMaterial) -> float:
	var key := "ambience_base_" + str(param)
	if not n.has_meta(key):
		var v = _param(mat, param)
		n.set_meta(key, float(v) if (v is float or v is int) else 1.0)
	return float(n.get_meta(key))


func _apply() -> void:
	var v := values
	var c: Color = v["canvas"]
	if _flash > 0.0:
		c = c.lerp(Color(0.92, 0.95, 1.0), _flash * 0.55)
	if is_instance_valid(_canvas):
		_canvas.color = c
	if _grade:
		for k in ["exposure", "contrast", "saturation", "vignette", "shadow_tint", "highlight_tint", "vignette_color"]:
			if _grade_names.has(k):
				var val = v[k]
				if k == "exposure":
					val = float(val) + _flash * 0.35
				_grade.set_shader_parameter(k, val)
	if _sun:
		_sun.color = v["sun_color"]
		_sun.enabled = float(v["sun"]) + float(v["moon"]) > 0.01
	if publish_tod_night:
		var night := float(v["night"])
		RenderingServer.global_shader_parameter_set(TOD, night)
		if absf(night - _last_night) > 0.001:
			_last_night = night
			# nodes that follow tod_night by script (e.g. NightLights of Free Godot 4 Sprite Shaders) get the value too
			get_tree().call_group("tod_night", "set_tod", night)
	_drive_group("ambience_fog", "density", float(v["fog"]))
	_drive_group("ambience_clouds", "darkness", float(v["clouds"]))
	_drive_group("ambience_smoke", "density", float(v["smoke"]))
	_drive_group("ambience_sun", "intensity", float(v["sun"]))
	_drive_group("ambience_moon", "intensity", float(v["moon"]))
	for n in get_tree().get_nodes_in_group("ambience_moon"):
		var m := _mat(n)
		if m:
			var t: Color = v["moon_tint"]
			for p in ["tint", "color"]:
				if _has_param(m, p):
					var pv = _param(m, p)
					var base_c: Color = n.get_meta("ambience_base_" + p, pv if pv is Color else Color.WHITE)
					n.set_meta("ambience_base_" + p, base_c)
					m.set_shader_parameter(p, Color(base_c.r * t.r / BASE_MOON.r, base_c.g * t.g / BASE_MOON.g,
						base_c.b * t.b / BASE_MOON.b, base_c.a))


func _drive_group(group: StringName, param: StringName, factor: float) -> void:
	for n in get_tree().get_nodes_in_group(group):
		var m := _mat(n)
		if m == null or not _has_param(m, param):
			continue
		var b := _base(n, param, m)
		m.set_shader_parameter(param, b * factor)
		if n is CanvasItem:
			(n as CanvasItem).visible = b * factor > 0.002 or not n.has_meta("ambience_hide_when_off")


func _mat(n: Node) -> ShaderMaterial:
	if n is CanvasItem and (n as CanvasItem).material is ShaderMaterial:
		return (n as CanvasItem).material
	return null


func _param(m: ShaderMaterial, p: StringName) -> Variant:
	## the material's value, or the shader's default when the material never set it
	var v = m.get_shader_parameter(p)
	if v == null and m.shader:
		v = RenderingServer.shader_get_parameter_default(m.shader.get_rid(), p)
	return v


func _has_param(m: ShaderMaterial, p: StringName) -> bool:
	if m.shader == null:
		return false
	if not _uniforms.has(m.shader):
		var names := {}
		for u in m.shader.get_shader_uniform_list():
			names[StringName(u["name"])] = true
		_uniforms[m.shader] = names
	return _uniforms[m.shader].has(StringName(p))


func _update_lamps() -> void:
	var level := float(values.get("lamps", 1.0))
	for l in _lamps:
		var light: PointLight2D = l[0]
		if not is_instance_valid(light):
			continue
		var n := _noise.get_noise_1d(_t * 3.0 + l[3]) * flicker / 0.14
		light.energy = l[1] * level * (1.0 + 0.18 * n) * (1.0 + _flash * 0.3)
		light.texture_scale = l[2] * (1.0 + 0.04 * n)
		light.enabled = level > 0.01


func _update_lightning(delta: float) -> void:
	var want := lightning and float(values.get("lightning", 0.0)) > 0.5
	if _flash > 0.0:
		_dirty = true
	if not want:
		_storm_on = false
		return
	if not _storm_on:
		_storm_on = true
		_next_flash = minf(_next_flash, 0.8)          # the first flash comes soon after the storm starts
	_next_flash -= delta
	if _next_flash <= 0.0:
		_next_flash = lightning_every + randf_range(-0.4, 0.4) * lightning_every
		var tw := create_tween()
		tw.tween_method(_set_flash, 0.0, 1.0, 0.05)
		tw.tween_method(_set_flash, 1.0, 0.15, 0.09)
		tw.tween_method(_set_flash, 0.15, 0.75, 0.05)
		tw.tween_method(_set_flash, 0.75, 0.0, 0.4)


func _resend() -> void:
	_last_night = -1.0
	_rescan()
	_dirty = true


func _set_flash(f: float) -> void:
	_flash = f
	_dirty = true


func _make_hint() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 20
	_hint = Label.new()
	_hint.position = Vector2(16, 12)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("shadow_offset_x", 2)
	_hint.add_theme_constant_override("shadow_offset_y", 2)
	cl.add_child(_hint)
	add_child(cl)
	_update_hint()


func _update_hint() -> void:
	if _hint == null:
		return
	var names := []
	for i in ORDER.size():
		names.append("%d %s" % [i + 1, ORDER[i].replace("_", " ")])
	_hint.text = "%s   |   C day cycle%s\nnow: %s" % ["   ".join(names), " (on)" if day_cycle else "",
		("clock %05.2f" % time_of_day) if day_cycle else preset.replace("_", " ")]
