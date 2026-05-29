shader_type canvas_item;
render_mode unshaded;

// Palette comparison path for transitioning between texture mapping and a LUT.
// This intentionally computes two palette paths when LUT use is enabled.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "../include/palette.gdshaderinc"

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;

	if (u_palette_shading_enabled) {
		vec3 texture_color = u_palette_use_match_rgb
			? apply_palette_mapping_rgb(color)
			: apply_palette_mapping_luminance(color);

		if (u_palette_use_lut) {
			vec3 lut_color = apply_palette_mapping_lut(color);
			color = mix(texture_color, lut_color, u_palette_lut_blend);
		} else {
			color = texture_color;
		}
	}

	COLOR = vec4(color, 1.0);
}
