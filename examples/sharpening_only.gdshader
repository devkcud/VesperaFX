shader_type canvas_item;
render_mode unshaded;

// Isolated sharpening pass.
#define ENABLE_SHARPENING

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "../include/sharpening.gdshaderinc"

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 color = texture(screen_texture, uv).rgb;

	if (u_sharpen_kernel != 0) {
		color = apply_sharpen_by_kernel(screen_texture, uv, SCREEN_PIXEL_SIZE);
	}

	COLOR = vec4(color, 1.0);
}
