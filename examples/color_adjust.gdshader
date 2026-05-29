shader_type canvas_item;
render_mode unshaded;

// Guarded color correction pass. Defaults skip no-op gamma/hue/saturation/contrast work.
#define ENABLE_COLOR_ADJUST

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "../include/rendering.gdshaderinc"

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;

	if (u_rendering_gamma_correction_input_enabled && u_rendering_gamma > 0.0001 && abs(u_rendering_gamma - 1.0) > 0.0001) {
		color = gamma_correction_input(color, u_rendering_gamma);
	}
	if (u_rendering_hue_shift != 0.0) {
		color = adjust_hue_shift(color, u_rendering_hue_shift);
	}
	if (u_rendering_saturation != 1.0) {
		color = adjust_saturation(color, u_rendering_saturation);
	}
	if (u_rendering_contrast != 1.0) {
		color = adjust_contrast(color, u_rendering_contrast);
	}
	if (u_rendering_gamma_correction_output_enabled && u_rendering_gamma > 0.0001 && abs(u_rendering_gamma - 1.0) > 0.0001) {
		color = gamma_correction_output(color, u_rendering_gamma);
	}

	COLOR = vec4(color, 1.0);
}
