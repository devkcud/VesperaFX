shader_type canvas_item;
render_mode unshaded;

// Pixelation with CRT scanlines, vignette, warp, and black bars.
#define ENABLE_PIXELATION
#define ENABLE_CRT

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "../include/pixelation.gdshaderinc"
#include "../include/crt.gdshaderinc"

void fragment() {
	vec2 uv = SCREEN_UV;

	if (u_pixelation_enabled) {
		uv = to_pixelated_uv(SCREEN_PIXEL_SIZE, uv, u_pixelation_size);
	}

	if (u_crt_warp_x != 0.0 || u_crt_warp_y != 0.0) {
		uv = apply_crt_warp(uv);
	}

	vec3 color = texture(screen_texture, uv).rgb;

	float pixel_scale = u_pixelation_enabled
		? float(u_pixelation_size) * SCREEN_PIXEL_SIZE.y
		: SCREEN_PIXEL_SIZE.y;

	color = apply_crt_scanlines(color, SCREEN_UV, pixel_scale);
	color = apply_crt_vignette(color, SCREEN_UV);
	color = apply_crt_black_bars(color, SCREEN_UV);

	COLOR = vec4(color, 1.0);
}
