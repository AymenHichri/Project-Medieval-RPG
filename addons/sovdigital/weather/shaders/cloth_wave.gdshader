shader_type canvas_item;
// CLOTH WAVE (banners, flags, tents' loose flaps, laundry, sails, curtains, rope)
// Waves run through the cloth from the edge it hangs from to its free edge, with light and dark folds.
// Hanging banner: attach_edge = 0 (top). Flag on a pole flying right: attach_edge = 1 (left). Flying left: 2 (right).
// Only the cloth moves: set cloth_rect to the cloth's box inside the sprite (0..1 of the sprite), or give a cloth_mask
// (white = cloth). Poles, crossbars and the rest of the piece stay still.
// Pole pinned (1.2.1): the attached edge never moves, and a pole running through the cloth box stays straight:
//   - pole: x = the pole's centre (0..1 of the sprite width, negative = no pole), y = half its width (0..1 of the sprite
//     width), z = how far down the cloth box (0..1) the pole shows below the cloth; from there down the pole band is still.
//     A banner on a centre pole: pole = vec3(0.49, 0.05, 0.62).
//   - or a cloth_mask with grey levels: the grey is how much a pixel may move (black = still, white = free).
// For sprite sheets add scripts/sprite_shader_region.gd as a child (region_uv).

uniform int attach_edge : hint_range(0, 2) = 0;               // 0 top (hanging), 1 left (flag flying right), 2 right
uniform vec4 cloth_rect = vec4(0.0, 0.0, 1.0, 1.0);           // x, y, width, height of the cloth inside the sprite (0..1)
uniform bool use_cloth_mask = false;
uniform sampler2D cloth_mask : hint_default_white, filter_linear;
uniform float wave_px : hint_range(0.0, 32.0) = 4.0;          // how far the free edge moves, in texture pixels
uniform float waves : hint_range(0.2, 4.0) = 1.3;             // waves along the cloth at once
uniform float speed : hint_range(0.0, 4.0) = 0.9;             // waves per second
uniform float stiff : hint_range(0.0, 0.8) = 0.08;            // share of the cloth next to the attached edge that barely moves
uniform float swing_px : hint_range(0.0, 24.0) = 1.5;         // slow sideways swing of a hanging banner
uniform float shade : hint_range(0.0, 1.0) = 0.35;            // fold light and shadow
uniform vec3 pole = vec3(-1.0, 0.05, 0.6);                    // pole pin: centre x, half width (sprite width 0..1), start down the box
uniform float pole_soft : hint_range(0.0, 0.5) = 0.12;        // fade from still (on the pole) to free, in sprite width
uniform float phase_offset = 0.0;
uniform vec4 region_uv = vec4(0.0, 0.0, 1.0, 1.0);

varying vec4 tint;
varying float cloth_phase;

void vertex() {
	tint = COLOR;
	vec2 origin = MODEL_MATRIX[3].xy;
	cloth_phase = fract(sin(dot(origin, vec2(39.346, 11.135))) * 43758.5453) * 6.2832 + phase_offset;
}

vec2 local_of(vec2 uv) {
	return (uv - region_uv.xy) / region_uv.zw;
}

vec2 rect_of(vec2 l) {
	return (l - cloth_rect.xy) / max(cloth_rect.zw, vec2(0.0001));
}

// The cloth: the cloth box times the mask grey (0 = not cloth).
float cloth_of(vec2 l) {
	vec2 r = rect_of(l);
	float w = step(0.0, r.x) * step(r.x, 1.0) * step(0.0, r.y) * step(r.y, 1.0);
	if (use_cloth_mask) {
		w *= texture(cloth_mask, l).r;
	}
	return w;
}

// How much this pixel of the sprite may move (0 = pinned, 1 = free): the cloth, then the pole pin.
float move_weight(vec2 l) {
	vec2 r = rect_of(l);
	float w = cloth_of(l);
	if (pole.x >= 0.0) {
		float s_down = attach_edge == 0 ? r.y : 1.0;
		float off_pole = smoothstep(pole.y, pole.y + pole_soft, abs(l.x - pole.x));
		float below = smoothstep(pole.z - 0.3, pole.z, s_down);   // a long fade, so the cloth over the pole bends instead of shearing
		w *= mix(1.0, off_pole, below);
	}
	return w;
}

void fragment() {
	vec2 l = local_of(UV);
	vec2 r = rect_of(l);
	float mw = move_weight(l);
	float in_cloth = step(0.004, cloth_of(l));
	// s = distance from the attached edge (0) to the free edge (1)
	float s = attach_edge == 0 ? r.y : (attach_edge == 1 ? r.x : 1.0 - r.x);
	// The attached edge is pinned: 0 at the edge, rising after the stiff share.
	float wgt = smoothstep(0.0, 1.0, clamp((s - stiff) / max(1.0 - stiff, 0.001), 0.0, 1.0));
	float ph = 6.2832 * (s * waves - TIME * speed) + cloth_phase;
	float wave = sin(ph) + 0.3 * sin(ph * 2.1 + 1.3);
	float d = wave_px * wgt * wave;
	vec2 disp_px;
	if (attach_edge == 0) {
		float swing = swing_px * wgt * sin(TIME * speed * 0.37 * 6.2832 + cloth_phase);
		disp_px = vec2(d + swing, 0.0);
	} else {
		float dir = attach_edge == 1 ? 1.0 : -1.0;
		disp_px = vec2(-dir * abs(d) * 0.15, d);   // the cloth shortens a little where it waves
	}
	disp_px *= clamp(mw, 0.0, 1.0);
	vec2 uv = UV - disp_px * TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, uv);
	// Pixels pulled in from outside the cloth (pole, background) stay transparent inside the cloth.
	if (in_cloth > 0.5) {
		c.a *= step(0.004, cloth_of(local_of(uv)));
		// Folds: the slope of the wave lights one side of each fold and shades the other.
		float slope = cos(ph) * wgt * mw;
		c.rgb *= 1.0 + shade * 0.5 * slope;
	}
	float inside = step(region_uv.x, uv.x) * step(uv.x, region_uv.x + region_uv.z)
		* step(region_uv.y, uv.y) * step(uv.y, region_uv.y + region_uv.w);
	COLOR = c * tint * inside;
}
