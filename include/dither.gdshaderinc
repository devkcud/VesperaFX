#ifndef DITHER
#define DITHER

group_uniforms Dithering;
uniform sampler2D u_dither_blue_noise_texture : filter_nearest;

uniform int u_dither_mode : hint_enum("Off", "Bayer", "Noise", "Pseudo F-S", "Blue Noise") = 1;
uniform int u_dither_level = 16;
group_uniforms;

const int BAYER_MATRIX_SIZE = 8;
const float BAYER_MATRIX[BAYER_MATRIX_SIZE * BAYER_MATRIX_SIZE] = float[](
	 0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0,
	48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
	12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0,
	60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
	 3.0, 35.0, 11.0, 43.0,  1.0, 33.0,  9.0, 41.0,
	51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
	15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0,
	63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
);

const float BAYER_DIVISOR = 1.0 / float(BAYER_MATRIX_SIZE * BAYER_MATRIX_SIZE);

float _get_bayer_threshold(vec2 pixel_coord) {
	vec2 block_pos = floor(pixel_coord);
	ivec2 bayer_coord = ivec2(mod(block_pos, float(BAYER_MATRIX_SIZE)));
	int idx = bayer_coord.x + bayer_coord.y * BAYER_MATRIX_SIZE;

	return BAYER_MATRIX[idx] * BAYER_DIVISOR;
}

vec3 dither_bayer(vec3 color, vec2 pixel_coord, float range_scale, float quantize_scale) {
	float threshold = _get_bayer_threshold(pixel_coord);
	vec3 adjusted = color + (threshold - 0.5) * range_scale;

	return floor(adjusted * quantize_scale + 0.5) * range_scale;
}

vec3 dither_noise(vec3 color, vec2 pixel_coord, float range_scale, float quantize_scale) {
	float noise = fract(sin(dot(pixel_coord, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 adjusted = color + (noise - 0.5) * range_scale;

	return floor(adjusted * quantize_scale + 0.5) * range_scale;
}

vec3 dither_floyd_steinberg(vec3 color, vec2 pixel_coord, float range_scale, float quantize_scale) {
	vec2 pos = floor(pixel_coord);
	bool odd_row = bool(int(pos.y) & 1);

	bool right = odd_row ? (int(pos.x) & 1) == 0 : (int(pos.x) & 1) == 1;

	float spread = 0.0;
	if (!odd_row) {
		spread = right ? 0.125 : -0.375;
	} else {
		spread = right ? -0.125 : 0.375;
	}

	vec3 adjusted = color + spread * range_scale;

	return floor(adjusted * quantize_scale + 0.5) * range_scale;
}

vec3 dither_blue_noise(vec3 color, vec2 pixel_coord, float range_scale, float quantize_scale, sampler2D blue_noise_texture) {
	ivec2 blue_noise_size = textureSize(blue_noise_texture, 0);

	if (blue_noise_size.x > 0 && blue_noise_size.y > 0 && blue_noise_size.x == blue_noise_size.y) {
		vec2 blue_uv = mod(pixel_coord / float(blue_noise_size.x), 1.0);
		float noise = texture(blue_noise_texture, blue_uv).r;
		vec3 adjusted = color + (noise - 0.5) * range_scale;

		return floor(adjusted * quantize_scale + 0.5) * range_scale;
	}

	return color;
}

vec3 apply_dithering_by_mode(vec3 color, vec2 pixel_coord, sampler2D blue_noise_texture) {
	if (u_dither_level < 1) {
		return color;
	}

	float range_scale = 1.0 / float(u_dither_level - 1);
	float quantize_scale = float(u_dither_level - 1);
	vec3 dithered = color;

	switch (u_dither_mode) {
		case 1: // Bayer
			dithered = dither_bayer(color, pixel_coord, range_scale, quantize_scale);
			break;
		case 2: // Noise
			dithered = dither_noise(color, pixel_coord, range_scale, quantize_scale);
			break;
		case 3: // Pseudo Floyd-Steinberg
			dithered = dither_floyd_steinberg(color, pixel_coord, range_scale, quantize_scale);
			break;
		case 4: // Blue Noise
			dithered = dither_blue_noise(color, pixel_coord, range_scale, quantize_scale, blue_noise_texture);
			break;
	}

	return clamp(dithered, 0.0, 1.0);
}

#endif
