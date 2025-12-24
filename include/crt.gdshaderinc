#ifndef CRT
#define CRT

group_uniforms Crt;
uniform float u_crt_vignette_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float u_crt_vignette_smoothness : hint_range(0.01, 1.0, 0.01) = 0.5;

uniform float u_crt_scanline_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float u_crt_scanline_thickness : hint_range(1.0, 8.0, 1.0) = 2.0;

uniform float u_crt_warp_x : hint_range(-0.5, 0.5, 0.01) = 0.0;
uniform float u_crt_warp_y : hint_range(-0.5, 0.5, 0.01) = 0.0;

uniform float u_crt_bars_horizontal : hint_range(0.0, 0.5, 0.01) = 0.0;
uniform float u_crt_bars_vertical : hint_range(0.0, 0.5, 0.01) = 0.0;
group_uniforms;

group_uniforms Vhs;
uniform float u_vhs_chroma_offset : hint_range(0.0, 0.02, 0.001) = 0.0;
uniform float u_vhs_tracking_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float u_vhs_tracking_speed : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float u_vhs_noise_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
group_uniforms;

vec2 apply_crt_warp(vec2 uv) {
	vec2 centered = uv - 0.5;
	float r2 = dot(centered, centered);

	vec2 warp = vec2(u_crt_warp_x, u_crt_warp_y);
	vec2 warped = centered * (1.0 + warp * r2);

	return warped + 0.5;
}

vec3 apply_crt_vignette(vec3 color, vec2 uv) {
	if (u_crt_vignette_intensity <= 0.0) {
		return color;
	}

	vec2 centered = uv - 0.5;
	float dist = length(centered) * 2.0;
	float vignette = smoothstep(1.0, 1.0 - u_crt_vignette_smoothness, dist);
	vignette = mix(1.0, vignette, u_crt_vignette_intensity);

	return color * vignette;
}

vec3 apply_crt_scanlines(vec3 color, vec2 uv, float pixel_scale) {
	if (u_crt_scanline_intensity <= 0.0) {
		return color;
	}

	float y = uv.y / pixel_scale;
	float line = mod(y, u_crt_scanline_thickness * 2.0);
	float scanline = step(u_crt_scanline_thickness, line);
	scanline = mix(1.0, scanline, u_crt_scanline_intensity);

	return color * scanline;
}

vec3 apply_crt_black_bars(vec3 color, vec2 uv) {
	if (u_crt_bars_horizontal <= 0.0 && u_crt_bars_vertical <= 0.0) {
		return color;
	}

	float h_bar = step(u_crt_bars_horizontal, uv.y) * step(uv.y, 1.0 - u_crt_bars_horizontal);
	float v_bar = step(u_crt_bars_vertical, uv.x) * step(uv.x, 1.0 - u_crt_bars_vertical);

	return color * h_bar * v_bar;
}

float _vhs_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 apply_vhs_chromatic(sampler2D tex, vec2 uv) {
	if (u_vhs_chroma_offset <= 0.0) {
		return texture(tex, uv).rgb;
	}

	float r = texture(tex, uv + vec2(u_vhs_chroma_offset, 0.0)).r;
	float g = texture(tex, uv).g;
	float b = texture(tex, uv - vec2(u_vhs_chroma_offset, 0.0)).b;

	return vec3(r, g, b);
}

vec3 apply_vhs_tracking(vec3 color, vec2 uv, float time) {
	if (u_vhs_tracking_intensity <= 0.0) {
		return color;
	}

	float line_y = fract(time * u_vhs_tracking_speed * 0.1);
	float dist = abs(uv.y - line_y);
	float band = smoothstep(0.05, 0.0, dist);

	float offset = band * u_vhs_tracking_intensity * 0.1;
	float distortion = sin(uv.y * 100.0 + time * 10.0) * offset;

	return mix(color, color * (1.0 + distortion), band * u_vhs_tracking_intensity);
}

vec3 apply_vhs_noise(vec3 color, vec2 uv, float time) {
	if (u_vhs_noise_intensity <= 0.0) {
		return color;
	}

	float noise = _vhs_hash(uv * 1000.0 + time);
	noise = (noise - 0.5) * u_vhs_noise_intensity;

	return color + noise;
}

#endif
