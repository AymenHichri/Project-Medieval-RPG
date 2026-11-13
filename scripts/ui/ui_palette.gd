class_name UIPalette
extends Resource
## Semantic colour tokens (ART_GUIDELINES.md §3), sampled from the Gimble's kit palette.
## Scenes and code use these tokens; never hard-code hex colours elsewhere.

const TOKENS: Array[StringName] = [
	&"bg_abyss", &"panel_slate", &"panel_iron", &"iron_edge", &"wood_dark", &"wood",
	&"parchment", &"parchment_light", &"parchment_dim", &"gold", &"gold_muted", &"bronze",
	&"blood", &"blood_bright", &"blood_dark", &"mana", &"arcane", &"curse", &"heal", &"ember",
]

@export var bg_abyss: Color = Color("#120F14")
@export var panel_slate: Color = Color("#191A23")
@export var panel_iron: Color = Color("#393333")
@export var iron_edge: Color = Color("#4B4B51")
@export var wood_dark: Color = Color("#3C2D28")
@export var wood: Color = Color("#643E2E")
@export var parchment: Color = Color("#D5C8B3")
@export var parchment_light: Color = Color("#ECE8DF")
@export var parchment_dim: Color = Color("#9C958E")
@export var gold: Color = Color("#DCAE4F")
@export var gold_muted: Color = Color("#A47B4F")
@export var bronze: Color = Color("#99693E")
@export var blood: Color = Color("#8C2821")
@export var blood_bright: Color = Color("#BB322C")
@export var blood_dark: Color = Color("#5D201D")
@export var mana: Color = Color("#4277A9")
@export var arcane: Color = Color("#723D96")
@export var curse: Color = Color("#5C3266")
@export var heal: Color = Color("#819F57")
@export var ember: Color = Color("#E56425")


func token(token_name: StringName) -> Color:
	return get(token_name) as Color
