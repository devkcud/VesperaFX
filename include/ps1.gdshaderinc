#ifndef PS1
#define PS1

group_uniforms PS1_Jitter;
uniform bool u_ps1_jitter_enabled = false;
uniform float u_ps1_jitter_intensity : hint_range(0.6, 10.0, 0.1) = 0.6;
uniform float u_ps1_jitter_speed : hint_range(0.0, 60.0, 1.0) = 4.0;
uniform int u_ps1_resolution : hint_range(1, 512) = 40;
group_uniforms;

vec2 ps1_jitter_uv(vec2 uv, vec2 pixel_size, float time) {
	vec2 snapped = floor(uv / pixel_size) * pixel_size;

	float res = float(u_ps1_resolution);
	vec2 grid_pos = floor(snapped * res);

	float t = floor(time * u_ps1_jitter_speed);
	float noise_x = fract(sin(dot(grid_pos + t, vec2(12.9898, 78.233))) * 43758.5453);
	float noise_y = fract(sin(dot(grid_pos + t, vec2(93.9898, 67.345))) * 24634.6345);

	vec2 jitter = (vec2(noise_x, noise_y) - 0.5) * 2.0;
	jitter *= pixel_size * u_ps1_jitter_intensity;

	return uv + jitter;
}

#endif
