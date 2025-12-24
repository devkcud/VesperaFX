#include "utils.gdshaderinc"

#ifndef PALETTE
#define PALETTE

group_uniforms Palette;
uniform sampler2D u_palette_color_texture : filter_nearest;
/** Optional precomputed LUT texture for fast RGB palette lookups.
 * The texture should be laid out as a 3D LUT where the width is
 * `size * size` and the height is `size * rows`.
 * When enabled, the LUT is used instead of brute-force RGB matching.
 */
uniform sampler2D u_palette_lut_texture : filter_nearest;

uniform bool u_palette_shading_enabled = true;
uniform float u_palette_invert : hint_range(0.0, 1.0, 0.01) = 0.0;

/** Use LUT mapping when true. */
uniform bool u_palette_use_lut = false;

/** Enables brute-force RGB color matching against the palette.
 * This is significantly slower than luminance-based mapping, particularly with large palettes.
 *
 * Recommended: Use only when precise color fidelity is needed (e.g. stylized or vibrant palettes).
 */
uniform bool u_palette_use_match_rgb = false;
/** Max number of colors to compare in RGB palette matching.
 * Higher values = more accurate color match, but worse performance.
 * 64 is a practical upper limit. Beyond this, performance tanks hard on most GPUs.
 * Tested on low-end (11+ yr old) hardware: 64 was a sweet spot.
 */
uniform int u_palette_match_rgb_max_colors = 0;

/** Controls palette animation step.
 * Even steps use base row (0), odd steps cycle through alt rows.
 */
uniform float u_palette_loop_step = 0.0;
group_uniforms;

/** Loops through palette rows with a bounce pattern:
 * Even steps: base palette (row 0)
 * Odd steps: successive alternate palettes (rows 1, 2, 3, ...)
 * This allows switching between base and variations over time.
 */
float _get_looped_palette_row(float step_float) {
	int step_index = int(max(0.0, step_float));

	return (step_index % 2 == 0) ? 0.0 : float((step_index + 1) / 2);
}

struct PaletteAnimState {
	float row_a;
	float row_b;
	float blend;
};

PaletteAnimState _get_palette_anim_state(float max_rows) {
	float val = max(0.0, u_palette_loop_step);
	float step = floor(val);

	float row_a = clamp(_get_looped_palette_row(step), 0.0, max_rows - 1.0);
	float row_b = clamp(_get_looped_palette_row(step + 1.0), 0.0, max_rows - 1.0);

	return PaletteAnimState(row_a, row_b, fract(val));
}

vec3 _get_palette_color(float palette_index, float uv_x, float rows) {
	palette_index = clamp(palette_index, 0.0, max(0.0, rows - 1.0));
	float uv_y = (palette_index + 0.5) / rows;

	return texture(u_palette_color_texture, vec2(uv_x, uv_y)).rgb;
}

vec3 _sample_palette_lut(vec3 color_index, float palette_row, float size, float rows) {
	float x = (color_index.r + color_index.b * size + 0.5) / (size * size);
	float y = (color_index.g + palette_row * size + 0.5) / (size * rows);

	return texture(u_palette_lut_texture, vec2(x, y)).rgb;
}

vec3 apply_palette_mapping_lut(vec3 color) {
	ivec2 lut_dim = textureSize(u_palette_lut_texture, 0);
	int size = int(sqrt(float(lut_dim.x)));
	int rows = lut_dim.y / size;

	if (size < 2 || lut_dim.x <= 0 || rows <= 0) {
		return color;
	}

	vec3 clamped = clamp(color, 0.0, 1.0);
	vec3 lut_input = mix(clamped, vec3(1.0) - clamped, u_palette_invert);

	vec3 scaled = lut_input * float(size - 1);

	PaletteAnimState anim = _get_palette_anim_state(float(rows));

	vec3 col_a = _sample_palette_lut(scaled, anim.row_a, float(size), float(rows));
	vec3 col_b = _sample_palette_lut(scaled, anim.row_b, float(size), float(rows));

	return mix(col_a, col_b, anim.blend);
}

vec3 apply_palette_mapping_rgb(vec3 color) {
	ivec2 palette_tex_size = textureSize(u_palette_color_texture, 0);
	int cols = palette_tex_size.x;
	int rows = palette_tex_size.y;

	if (cols <= 0 || rows <= 0) {
		return color;
	}

	vec3 match_color = mix(color, vec3(1.0) - color, u_palette_invert);

	PaletteAnimState anim = _get_palette_anim_state(float(rows));

	vec3 closest_a = vec3(0.0);
	vec3 closest_b = vec3(0.0);
	float best_distance_a = FLT_MAX;
	float best_distance_b = FLT_MAX;

	int max_colors = (u_palette_match_rgb_max_colors > 0)
		? min(cols, u_palette_match_rgb_max_colors)
		: min(cols, 64);

	for (int i = 0; i < max_colors; i++) {
		float uv_x = (float(i) + 0.5) / float(cols);

		vec3 col_a = _get_palette_color(anim.row_a, uv_x, float(rows));
		vec3 col_b = _get_palette_color(anim.row_b, uv_x, float(rows));

		vec3 diff_a = match_color - col_a;
		float d_a = dot(diff_a, diff_a);

		vec3 diff_b = match_color - col_b;
		float d_b = dot(diff_b, diff_b);

		if (d_a < best_distance_a) {
			best_distance_a = d_a;
			closest_a = col_a;
		}
		if (d_b < best_distance_b) {
			best_distance_b = d_b;
			closest_b = col_b;
		}
	}

	return mix(closest_a, closest_b, anim.blend);
}

vec3 apply_palette_mapping_luminance(vec3 color) {
	float color_luminance = dot(color, LUMA);
	ivec2 color_palette_tex = textureSize(u_palette_color_texture, 0);

	float cols = float(color_palette_tex.x);
	float rows = float(color_palette_tex.y);

	if (cols <= 0.0 || rows <= 0.0) {
		return color;
	}

	float col_idx = clamp(floor(color_luminance * cols), 0.0, max(0.0, cols - 1.0));
	float uv_x = (col_idx + 0.5) / cols;
	uv_x = mix(uv_x, 1.0 - uv_x, u_palette_invert);

	PaletteAnimState anim = _get_palette_anim_state(rows);

	vec3 color_a = _get_palette_color(anim.row_a, uv_x, rows);
	vec3 color_b = _get_palette_color(anim.row_b, uv_x, rows);

	return mix(color_a, color_b, anim.blend);
}

#endif
