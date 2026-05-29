shader_type canvas_item;
render_mode unshaded;

// Motion-heavy stylization: warp UVs, split chroma, optionally accumulate trails.
#define ENABLE_VHS
#define ENABLE_WARP
#define ENABLE_TRAILS

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "../include/crt.gdshaderinc"
#include "../include/warp.gdshaderinc"
#include "../include/trails.gdshaderinc"

void fragment() {
	vec2 uv = SCREEN_UV;

	if (u_warp_enabled) {
		uv = apply_warp(uv, TIME);
	}

	vec3 color = apply_vhs_chromatic(screen_texture, uv);

	if (u_trails_enabled) {
		color = apply_trails(screen_texture, color, uv, TIME);
	}

	color = apply_vhs_tracking(color, SCREEN_UV, TIME);
	color = apply_vhs_noise(color, SCREEN_UV, TIME);

	COLOR = vec4(color, 1.0);
}
