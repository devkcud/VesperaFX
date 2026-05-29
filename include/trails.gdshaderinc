#ifndef TRAILS
#define TRAILS

group_uniforms Trails;
uniform bool u_trails_enabled = false;
uniform float u_trails_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform int u_trails_samples : hint_range(1, 10, 1) = 3;
uniform float u_trails_speed : hint_range(0.0, 10.0, 0.1) = 2.0;
group_uniforms;

vec3 apply_trails(sampler2D tex, vec3 base_color, vec2 uv, float time) {
	vec3 trail_accum = vec3(0.0);
	for (int i = 1; i <= u_trails_samples; i++) {
		float t = float(i) / float(u_trails_samples + 1);
		float angle = t * 10.0 + time * u_trails_speed;
		float radius = t * u_trails_intensity * 0.05;
		vec2 sample_uv = mix(uv, vec2(0.5), t * u_trails_intensity) + vec2(cos(angle), sin(angle)) * radius;
		trail_accum += textureLod(tex, sample_uv, 0.0).rgb;
	}

	trail_accum /= float(u_trails_samples);

	return mix(base_color, trail_accum, u_trails_intensity);
}

#endif
