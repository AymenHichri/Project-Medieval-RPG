shader_type canvas_item;

// Seamless weather / ambient overlay. Put it on a ColorRect (or any CanvasItem) that covers the view.
// mask:     the greyscale <name>_mask.png (brightness = opacity); tint gives the colour.
// tiles:    how many 1024 px tiles fit across the rect (rect size / 1024 keeps the art at 1:1).
// speed:    scroll in tiles per second (x, y); y > 0 falls, y < 0 rises.
uniform sampler2D mask : repeat_enable, filter_linear;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 tiles = vec2(1.0, 1.0);
uniform vec2 speed = vec2(0.0, 0.5);
uniform float strength : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	float m = texture(mask, UV * tiles - speed * TIME).r;
	COLOR = vec4(tint.rgb, clamp(m * strength, 0.0, 1.0) * tint.a);
}
