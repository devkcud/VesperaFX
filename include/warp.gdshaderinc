#ifndef WARP
#define WARP

group_uniforms Warp;
uniform bool u_warp_enabled = false;
uniform float u_warp_amount : hint_range(0.0, 10.0, 0.01) = 0.0;
uniform float u_warp_speed : hint_range(0.0, 10.0, 0.1) = 2.0;
uniform float u_warp_frequency : hint_range(1.0, 50.0, 0.5) = 10.0;
group_uniforms;

vec2 apply_warp(vec2 uv, float time) {
	uv.x += sin(uv.y * u_warp_frequency + time * u_warp_speed) * u_warp_amount * 0.01;
	uv.y += cos(uv.x * u_warp_frequency + time * u_warp_speed * 0.75) * u_warp_amount * 0.01;
	return uv;
}

#endif
