// Map page (Phase 10): grades a captured map picture into an old sepia print. Luminance (lifted,
// since the maps are dusk and night scenes) is mapped from `dark_tone` to `light_tone`; the page
// sets both from UIPalette tokens.
shader_type canvas_item;

uniform vec4 dark_tone : source_color = vec4(0.07, 0.06, 0.08, 1.0);
uniform vec4 light_tone : source_color = vec4(0.84, 0.78, 0.70, 1.0);
uniform float lift : hint_range(0.0, 1.0) = 0.04;
// Set per picture by the page (auto-exposure).
uniform float gain : hint_range(0.5, 8.0) = 1.0;

void fragment() {
	vec4 colour = texture(TEXTURE, UV);
	float luma = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
	luma = clamp(lift + luma * gain, 0.0, 1.0);
	// The incoming COLOR already holds the texture's colours: replace it, don't multiply.
	COLOR = vec4(mix(dark_tone.rgb, light_tone.rgb, luma), colour.a);
}
