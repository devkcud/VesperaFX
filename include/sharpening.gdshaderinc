#include "utils.gdshaderinc"

#ifndef SHARPENING
#define SHARPENING

group_uniforms Sharpening;
/** Sharpening enhances edge contrast, but may introduce ringing or noise,
 * especially on low-res or pixelated images.
 *
 * Recommended: Use sharpening only on high-res, unpixelated input.
 */
uniform int u_sharpen_kernel : hint_enum("Off", "Laplacian", "Unsharp Mask", "Bilateral", "High Boost") = 0;

uniform float u_sharpen_amount : hint_range(0.0, 10.0) = 0.8;
uniform float u_sharpen_edge_threshold : hint_range(0.0, 1.0, 0.05) = 0.05;
uniform float u_sharpen_boost_factor : hint_range(1.0, 5.0) = 1.5;
group_uniforms;

float _sobel_edge_strength(sampler2D tex, vec2 uv, vec2 pixel_size) {
	float tl = dot(texture(tex, uv + pixel_size * vec2(-1.0, -1.0)).rgb, LUMA);
	float t = dot(texture(tex, uv + pixel_size * vec2( 0.0, -1.0)).rgb, LUMA);
	float tr = dot(texture(tex, uv + pixel_size * vec2( 1.0, -1.0)).rgb, LUMA);

	float l = dot(texture(tex, uv + pixel_size * vec2(-1.0,  0.0)).rgb, LUMA);
	float r = dot(texture(tex, uv + pixel_size * vec2( 1.0,  0.0)).rgb, LUMA);

	float bl = dot(texture(tex, uv + pixel_size * vec2(-1.0,  1.0)).rgb, LUMA);
	float b = dot(texture(tex, uv + pixel_size * vec2( 0.0,  1.0)).rgb, LUMA);
	float br = dot(texture(tex, uv + pixel_size * vec2( 1.0,  1.0)).rgb, LUMA);

	float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
	float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;

	return length(vec2(gx, gy));
}

vec3 _gaussian_blur_3x3(sampler2D tex, vec2 uv, vec2 ps) {
	return texture(tex, uv + ps * vec2(-1, -1)).rgb * 0.0625
		 + texture(tex, uv + ps * vec2( 0, -1)).rgb * 0.125
		 + texture(tex, uv + ps * vec2( 1, -1)).rgb * 0.0625
		 + texture(tex, uv + ps * vec2(-1,  0)).rgb * 0.125
		 + texture(tex, uv + ps * vec2( 0,  0)).rgb * 0.25
		 + texture(tex, uv + ps * vec2( 1,  0)).rgb * 0.125
		 + texture(tex, uv + ps * vec2(-1,  1)).rgb * 0.0625
		 + texture(tex, uv + ps * vec2( 0,  1)).rgb * 0.125
		 + texture(tex, uv + ps * vec2( 1,  1)).rgb * 0.0625;
}

vec3 apply_sharpen_unsharp_mask(sampler2D tex, vec2 uv, vec2 ps) {
	vec3 orig = texture(tex, uv).rgb;
	vec3 blur = _gaussian_blur_3x3(tex, uv, ps);

	return clamp(orig + u_sharpen_amount * (orig - blur), 0.0, 1.0);
}

vec3 apply_sharpen_bilateral(sampler2D tex, vec2 uv, vec2 ps) {
	vec3 center = texture(tex, uv).rgb;
	float center_luma = dot(center, LUMA);

	vec3 blur_sum = vec3(0.0);
	float weight_sum = 0.0;

	float sigma_sq = 2.0 * u_sharpen_edge_threshold * u_sharpen_edge_threshold;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec3 sample_col = texture(tex, uv + ps * vec2(float(x), float(y))).rgb;
			float sample_luma = dot(sample_col, LUMA);
			float luma_diff = center_luma - sample_luma;
			float weight = exp(-luma_diff * luma_diff / sigma_sq);

			blur_sum += sample_col * weight;
			weight_sum += weight;
		}
	}

	vec3 bilateral_blur = blur_sum / weight_sum;
	return clamp(center + u_sharpen_amount * (center - bilateral_blur), 0.0, 1.0);
}

vec3 apply_sharpen_high_boost(sampler2D tex, vec2 uv, vec2 ps) {
	vec3 orig = texture(tex, uv).rgb;
	vec3 blur = _gaussian_blur_3x3(tex, uv, ps);
	vec3 mask = orig - blur;

	return clamp(u_sharpen_boost_factor * orig - blur + u_sharpen_amount * mask, 0.0, 1.0);
}

vec3 apply_sharpen_laplacian(sampler2D tex, vec2 uv, vec2 ps) {
	vec3 c = texture(tex, uv).rgb;

	vec3 neighbors = texture(tex, uv + ps * vec2( 0, -1)).rgb
				   + texture(tex, uv + ps * vec2(-1,  0)).rgb
				   + texture(tex, uv + ps * vec2( 1,  0)).rgb
				   + texture(tex, uv + ps * vec2( 0,  1)).rgb;

	vec3 lap = c - neighbors * 0.25;

	return clamp(c + u_sharpen_amount * lap, 0.0, 1.0);
}

vec3 apply_sharpen_by_kernel(sampler2D tex, vec2 uv, vec2 ps) {
	switch (u_sharpen_kernel) {
		case 1:
			return apply_sharpen_laplacian(tex, uv, ps);
		case 2:
			return apply_sharpen_unsharp_mask(tex, uv, ps);
		case 3:
			return apply_sharpen_bilateral(tex, uv, ps);
		case 4:
			return apply_sharpen_high_boost(tex, uv, ps);
		default:
			return texture(tex, uv).rgb;
	}
}

#endif
