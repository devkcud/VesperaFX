shader_type canvas_item;
render_mode unshaded;

// Cheap retro base: screen sample -> optional dither -> optional palette mapping.
#define ENABLE_DITHERING
#define ENABLE_PALETTE_MAPPING

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "../include/dither.gdshaderinc"
#include "../include/palette.gdshaderinc"

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 pixel_coord = FRAGCOORD.xy;
	vec3 color = texture(screen_texture, uv).rgb;

	if (u_dither_mode != 0) {
		color = apply_dithering_by_mode(color, pixel_coord, u_dither_blue_noise_texture);
	}

	if (u_palette_shading_enabled) {
		if (u_palette_use_lut) {
			color = apply_palette_mapping_lut(color);
		} else if (u_palette_use_match_rgb) {
			color = apply_palette_mapping_rgb(color);
		} else {
			color = apply_palette_mapping_luminance(color);
		}
	}

	COLOR = vec4(color, 1.0);
}
