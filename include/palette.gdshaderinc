#include "utils.gdshaderinc"

#ifndef PALETTE
#define PALETTE

uniform sampler2D u_palette_color_texture : filter_nearest;
/** Optional precomputed LUT texture for fast RGB palette lookups.
 * The texture should be laid out as a 3D LUT where the width is
 * `size * size` and the height is `size * rows`.
 * When enabled, the LUT is used instead of brute-force RGB matching.
 */
uniform sampler2D u_palette_lut_texture : filter_nearest;

uniform bool u_palette_shading_enabled = true;

/** Use LUT mapping when true. */
uniform bool u_palette_use_lut = false;
/** Dimension size for the LUT texture layout. */
uniform int u_palette_lut_size = 16;

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
uniform int u_palette_match_rgb_max_colors = 64;

/** Controls palette animation step.
 * Even steps use base row (0), odd steps cycle through alt rows.
 */
uniform float u_palette_loop_step = 0.0;

/** Loops through palette rows with a bounce pattern:
 * Even steps: base palette (row 0)
 * Odd steps: successive alternate palettes (rows 1, 2, 3, ...)
 * This allows switching between base and variations over time.
 */
float _get_looped_palette_row(float step_float) {
	int step_index = int(max(0.0, step_float));

	return (step_index % 2 == 0) ? 0.0 : float((step_index + 1) / 2);
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
	ivec2 lut_size = textureSize(u_palette_lut_texture, 0);
	int size = int(u_palette_lut_size);
	int rows = lut_size.y / size;

	if (size <= 0 || lut_size.x <= 0 || rows <= 0) {
		return color;
	}

	vec3 scaled = clamp(color, 0.0, 1.0) * float(size - 1);

	float current_val = max(0.0, u_palette_loop_step);
	float current_step = floor(current_val);
	float t = fract(current_val);

	float palette_a_index = clamp(_get_looped_palette_row(current_step), 0.0, float(rows - 1));
	float palette_b_index = clamp(_get_looped_palette_row(current_step + 1.0), 0.0, float(rows - 1));

	vec3 col_a = _sample_palette_lut(scaled, palette_a_index, float(size), float(rows));
	vec3 col_b = _sample_palette_lut(scaled, palette_b_index, float(size), float(rows));

	return mix(col_a, col_b, t);
}

vec3 apply_palette_mapping_rgb(vec3 color) {
	ivec2 palette_tex_size = textureSize(u_palette_color_texture, 0);
	int cols = palette_tex_size.x;
	int rows = palette_tex_size.y;

	if (cols <= 0 || rows <= 0) {
		return color;
	}

	float current_val = max(0.0, u_palette_loop_step);
	float current_step = floor(current_val);
	float t = fract(current_val);

	float palette_a_index = _get_looped_palette_row(current_step);
	float palette_b_index = _get_looped_palette_row(current_step + 1.0);

	vec3 closest_a = vec3(0.0);
	vec3 closest_b = vec3(0.0);
	float best_distance_a = FLT_MAX;
	float best_distance_b = FLT_MAX;

	// Hard cap at colors per palette row to avoid GPU infinite loop risk.
	int max_colors = min(cols, u_palette_match_rgb_max_colors);

	for (int i = 0; i < max_colors; i++) {
		float uv_x = (float(i) + 0.5) / float(cols);

		vec3 col_a = _get_palette_color(palette_a_index, uv_x, float(rows));
		vec3 col_b = _get_palette_color(palette_b_index, uv_x, float(rows));

		vec3 diff_a = color - col_a;
		float d_a = dot(diff_a, diff_a);

		vec3 diff_b = color - col_b;
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

	return mix(closest_a, closest_b, t);
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

	float current_val = max(0.0, u_palette_loop_step);

	float current_step = floor(current_val);
	float t = fract(current_val);

	float palette_a_index = _get_looped_palette_row(current_step);
	float palette_b_index = _get_looped_palette_row(current_step + 1.0);

	vec3 color_a = _get_palette_color(palette_a_index, uv_x, rows);
	vec3 color_b = _get_palette_color(palette_b_index, uv_x, rows);

	return mix(color_a, color_b, t);
}

#endif