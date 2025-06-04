#include "utils.gdshaderinc"

#ifndef RENDERING
#define RENDERING

group_uniforms Rendering;
uniform bool u_rendering_gamma_correction_input_enabled = true;
uniform bool u_rendering_gamma_correction_output_enabled = false;
uniform float u_rendering_gamma : hint_range(0.0, 5.0) = 1.0;
uniform float u_rendering_contrast : hint_range(0.0, 2.0) = 1.0;
uniform float u_rendering_saturation : hint_range(0.0, 2.0) = 1.0;
uniform float u_rendering_hue_shift : hint_range(0, 6.28) = 0.0;
group_uniforms;

mat3 _hue_shift_matrix(float angle) {
	float c = cos(angle);
	float s = sin(angle);

	return mat3(
		vec3(0.299 + 0.701 * c + 0.168 * s, 0.587 - 0.587 * c + .330 * s, 0.114 - 0.114 * c - 0.497 * s),
		vec3(0.299 - 0.299 * c - 0.328 * s, 0.587 + 0.413 * c + .035 * s, 0.114 - 0.114 * c + 0.292 * s),
		vec3(0.299 - 0.3 * c + 1.25 * s, 0.587 - 0.588 * c - 1.05 * s, 0.114 + 0.886 * c - 0.203 * s)
	);
}

vec3 adjust_hue_shift(vec3 color, float shift) {
	return _hue_shift_matrix(shift) * color;
}

vec3 adjust_contrast(vec3 color, float contrast) {
	return clamp((color - 0.5) * contrast + 0.5, 0.0, 1.0);
}

vec3 adjust_saturation(vec3 color, float saturation) {
	float gray = dot(color, LUMA);
	return clamp(mix(vec3(gray), color, saturation), 0.0, 1.0);
}

vec3 gamma_correction_input(vec3 color, float gamma) {
	return pow(color, vec3(1.0 / gamma));
}

vec3 gamma_correction_output(vec3 color, float gamma) {
	return pow(color, vec3(gamma));
}

#endif
