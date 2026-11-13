shader_type canvas_item;
// SCREEN GRADE (ambience kit): colour grade + vignette for the whole screen. The time-of-day controller drives it.
// Setup: a ColorRect filling a CanvasLayer (layer 10, above the level, below your UI), this shader as its material.
// The controller makes one itself when the scene has none. The same parameters as the map_grade shader of our tileset
// example scenes, plus vignette_color, so the controller drives either.
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float exposure = 1.0;
uniform float contrast = 1.0;
uniform float saturation = 1.0;
uniform vec3 shadow_tint = vec3(1.0);
uniform vec3 highlight_tint = vec3(1.0);
uniform float vignette = 0.35;
uniform vec3 vignette_color = vec3(0.0);
void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb * exposure;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c *= mix(shadow_tint, highlight_tint, smoothstep(0.05, 0.8, l));
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.0, 0.82);
	c = mix(c, vignette_color, vignette * smoothstep(0.25, 0.8, length(d) * 1.25));
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
