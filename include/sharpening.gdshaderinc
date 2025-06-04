#include "utils.gdshaderinc"

#ifndef SHARPENING
#define SHARPENING

group_uniforms Sharpening;
/** Sharpening enhances edge contrast, but may introduce ringing or noise,
 * especially on low-res or pixelated images.
 *
 * Recommended: Use sharpening only on high-res, unpixelated input.
 */
uniform int u_sharpen_kernel : hint_enum("Off", "Naive", "Unsharp Mask", "Edge Aware", "High Boost") = 0;

uniform float u_sharpen_amount : hint_range(0.0, 10.0) = 0.8;
uniform float u_sharpen_edge_threshold : hint_range(0.0, 1.0, 0.05) = 0.05;
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

vec3 _box_blur(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec3 sum = vec3(0.0);

	for (int y = -1; y <= 1; ++y) {
		for (int x = -1; x <= 1; ++x) {
			sum += texture(tex, uv + pixel_size * vec2(float(x), float(y))).rgb;
		}
	}

	return sum / 9.0;
}

vec3 apply_sharpen_unsharp_mask(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec3 orig = texture(tex, uv).rgb;
	vec3 blur = _box_blur(tex, uv, pixel_size);

	vec3 sharpened = orig + u_sharpen_amount * (orig - blur);

	return clamp(sharpened, 0.0, 1.0);
}

vec3 apply_sharpen_edge_aware(sampler2D tex, vec2 uv, vec2 pixel_size) {
	float edge_strength = _sobel_edge_strength(tex, uv, pixel_size);
	if (edge_strength < u_sharpen_edge_threshold) return texture(tex, uv).rgb;

	return apply_sharpen_unsharp_mask(tex, uv, pixel_size);
}

vec3 apply_sharpen_high_boost(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec3 orig = texture(tex, uv).rgb;
	vec3 blur = _box_blur(tex, uv, pixel_size);

	vec3 mask = orig - blur;
	vec3 result = orig + u_sharpen_amount * mask;

	return clamp(result, 0.0, 1.0);
}

vec3 apply_sharpen_naive(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec3 center = texture(tex, uv).rgb;

	vec3 lap = vec3(0.0);
	lap += texture(tex, uv + pixel_size * vec2(-1, -1)).rgb * -1.0;
	lap += texture(tex, uv + pixel_size * vec2( 0, -1)).rgb * -1.0;
	lap += texture(tex, uv + pixel_size * vec2( 1, -1)).rgb * -1.0;

	lap += texture(tex, uv + pixel_size * vec2(-1,  0)).rgb * -1.0;
	lap += center * 9.0;
	lap += texture(tex, uv + pixel_size * vec2( 1,  0)).rgb * -1.0;

	lap += texture(tex, uv + pixel_size * vec2(-1,  1)).rgb * -1.0;
	lap += texture(tex, uv + pixel_size * vec2( 0,  1)).rgb * -1.0;
	lap += texture(tex, uv + pixel_size * vec2( 1,  1)).rgb * -1.0;

	vec3 mask = lap - center;
	vec3 sharpened = center + (u_sharpen_amount * mask) / 9.0;

	vec3 diff = abs(sharpened - center);
	float edge_strength = max(max(diff.r, diff.g), diff.b);
	if (edge_strength < u_sharpen_edge_threshold) {
		return center;
	}

	return clamp(sharpened, 0.0, 1.0);
}

vec3 apply_sharpen_by_kernel(sampler2D tex, vec2 uv, vec2 pixel_size) {
	switch (u_sharpen_kernel) {
		case 1:
			return apply_sharpen_naive(tex, uv, pixel_size);
		case 2:
			return apply_sharpen_unsharp_mask(tex, uv, pixel_size);
		case 3:
			return apply_sharpen_edge_aware(tex, uv, pixel_size);
		case 4:
			return apply_sharpen_high_boost(tex, uv, pixel_size);
		default:
			return texture(tex, uv).rgb;
	}
}

#endif
