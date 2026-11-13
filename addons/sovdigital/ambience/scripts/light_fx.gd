extends PointLight2D
## LIGHT FX - makes a PointLight2D behave like a real light source. Attach to the light, pick a mode:
##   torch         flame flicker, strong, warm                 candle       small quick flicker
##   lamp          oil lantern: gentle flicker                 street_lamp  steady; warms up with a short flicker
##   neon          steady with a faint buzz and rare dips      broken       sputters: dark gaps, bursts of flicker
##   alarm_strobe  double flash, pause, double flash ...       beacon_spin  turns round (use a cone texture)
##   searchlight   sweeps back and forth (cone texture)        headlights   steady beams (parent it to the vehicle)
##   hologram      cold shimmer for a hologram projector       pulse        slow breathing glow (screens, crystals)
## Light textures for it: textures/lights/ (light_radial, light_cone_narrow / wide, light_headlights, light_strip).
## follow_time_of_day: with an ambience_controller.gd in the scene the light is off by day and switches on at dusk
## (each light at its own moment: switch_on_at); without a controller it is always on.
## The light keeps its own colour, energy (= its strength at night) and texture; this script only animates them.

@export_enum("torch", "candle", "lamp", "street_lamp", "neon", "broken", "alarm_strobe", "beacon_spin", "searchlight",
	"headlights", "hologram", "pulse") var mode := "torch"
@export var follow_time_of_day := true
@export_range(0.0, 1.0) var switch_on_at := -1.0        ## lamp level at which it switches on (-1 = random 0.3-0.6)
@export var speed := 1.0                                ## animation speed
@export var sweep_degrees := 70.0                       ## searchlight: sweep width
@export var spin_degrees_per_second := 240.0            ## beacon_spin
@export var seed := -1                                  ## -1 = random

var _energy := 1.0
var _scale := 1.0
var _rot := 0.0
var _t := 0.0
var _noise := FastNoiseLite.new()
var _ctrl: Node
var _on := -1.0                                         ## 0..1 switch-on progress
var _warm := 0.0                                        ## time since switching on
var _gap := 0.0                                         ## broken: time left in the current dark gap


func _ready() -> void:
	set_meta("ambience_fx", true)                       # the controller leaves this light to us
	_energy = energy
	_scale = texture_scale
	_rot = rotation
	if seed < 0:
		seed = randi() % 10000
	_noise.seed = seed
	_noise.frequency = 1.0
	_t = float(seed % 97)
	if switch_on_at < 0.0:
		switch_on_at = 0.3 + 0.3 * float(seed % 101) / 100.0


func _controller() -> Node:
	if _ctrl == null or not is_instance_valid(_ctrl):
		_ctrl = get_tree().get_first_node_in_group("ambience_controller")
	return _ctrl


func _process(delta: float) -> void:
	_t += delta * speed
	var level := 1.0
	var c := _controller() if follow_time_of_day else null
	if c:
		var lamps: float = c.lamp_level()
		var want := 1.0 if lamps >= switch_on_at else 0.0
		if mode in ["alarm_strobe", "beacon_spin", "headlights", "hologram", "neon", "pulse", "searchlight"]:
			want = 1.0 if lamps >= 0.15 else 0.0       # powered lights: on whenever it is darker than broad day
		if want > 0.5 and _on < 0.5:
			_warm = 0.0
		_on = want
		level = clampf(lamps, 0.35, 1.0) if mode in ["torch", "candle", "lamp"] else 1.0
		if _on < 0.5:
			enabled = false
			return
	enabled = true
	_warm += delta
	var e := 1.0
	var n := _noise.get_noise_1d(_t * 3.0)
	match mode:
		"torch":
			e = 1.0 + 0.2 * n + 0.08 * _noise.get_noise_1d(_t * 11.0 + 50.0)
			texture_scale = _scale * (1.0 + 0.05 * n)
		"candle":
			e = 1.0 + 0.14 * _noise.get_noise_1d(_t * 7.0) + 0.06 * _noise.get_noise_1d(_t * 19.0 + 9.0)
			texture_scale = _scale * (1.0 + 0.03 * n)
		"lamp":
			e = 1.0 + 0.07 * n
		"street_lamp":
			e = 1.0 + 0.015 * n
			if _warm < 0.8:                           # warm-up: two quick blinks, then full
				e *= 0.35 if fmod(_warm, 0.3) < 0.12 else 0.85
		"neon":
			e = 1.0 + 0.04 * sin(_t * 120.0) * 0.5
			if _noise.get_noise_1d(_t * 0.7 + 200.0) > 0.42:
				e *= 0.55 if fmod(_t * 17.0, 1.0) < 0.5 else 1.0
			if _warm < 0.5:
				e *= 0.2 if fmod(_warm, 0.16) < 0.08 else 1.0
		"broken":
			if _gap > 0.0:
				_gap -= delta
				e = 0.04
			else:
				var s := _noise.get_noise_1d(_t * 2.2 + 400.0)
				if s > 0.35:
					e = 0.15 if fmod(_t * 23.0, 1.0) < 0.55 else 1.0
				if randf() < delta * 0.35:
					_gap = randf_range(0.25, 1.4)
		"alarm_strobe":
			var p := fmod(_t, 1.4)
			e = 1.0 if (p < 0.07 or (p > 0.16 and p < 0.23)) else 0.0
		"beacon_spin":
			rotation += deg_to_rad(spin_degrees_per_second) * delta * speed
		"searchlight":
			rotation = _rot + deg_to_rad(sweep_degrees * 0.5) * sin(_t * 0.9) + deg_to_rad(4.0) * sin(_t * 2.3)
			e = 1.0 + 0.02 * n
		"headlights":
			e = 1.0 + 0.01 * n
		"hologram":
			e = 0.85 + 0.12 * sin(_t * 9.0) * 0.5 + (0.0 if fmod(_t * 13.0, 7.0) > 0.4 else -0.35)
		"pulse":
			e = 0.75 + 0.25 * sin(_t * 1.6)
	energy = _energy * maxf(e, 0.0) * level
