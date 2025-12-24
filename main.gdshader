shader_type canvas_item;
render_mode unshaded;

#define ENABLE_DITHERING
#define ENABLE_PALETTE_MAPPING
#define ENABLE_PIXELATION
#define ENABLE_SHARPENING
#define ENABLE_COLOR_ADJUST
#define ENABLE_PS1

/** Allows both pixelation and sharpening to be applied simultaneously.
 * This is discouraged, as it often produces visual artifacts.
 */
//#define ALLOW_PIXELATION_SHARPEN_COMBO

/** Change from "Dithering -> Palette Mapping" to "Palette Mapping -> Dithering" */
//#define REVERSE_DITHER_PALETTE_MAPPING

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#ifdef ENABLE_DITHERING
#include "include/dither.gdshaderinc"
#endif

#ifdef ENABLE_PALETTE_MAPPING
#include "include/palette.gdshaderinc"
#endif

#ifdef ENABLE_PIXELATION
#include "include/pixelation.gdshaderinc"
#endif

#ifdef ENABLE_SHARPENING
#include "include/sharpening.gdshaderinc"
#endif

#ifdef ENABLE_COLOR_ADJUST
#include "include/rendering.gdshaderinc"
#endif

#ifdef ENABLE_PS1
#include "include/ps1.gdshaderinc"
#endif

#ifdef ENABLE_SHARPENING
bool _should_sharpen() {
	#if defined(ENABLE_PIXELATION) && !defined(ALLOW_PIXELATION_SHARPEN_COMBO)
		return !u_pixelation_enabled;
	#else
		return true;
	#endif
}
#endif

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 pixel_coord = FRAGCOORD.xy;

	#ifdef ENABLE_PIXELATION
	if (u_pixelation_enabled) {
		pixel_coord = get_pixelated_coord(FRAGCOORD.xy, u_pixelation_size);
		uv = to_pixelated_uv(SCREEN_PIXEL_SIZE, SCREEN_UV, u_pixelation_size);
	}
	#endif

	#ifdef ENABLE_PS1
	if (u_ps1_jitter_enabled) {
		uv = ps1_jitter_uv(uv, SCREEN_PIXEL_SIZE, TIME);
	}
	#endif

	vec3 color = texture(screen_texture, uv).rgb;

	#ifdef ENABLE_COLOR_ADJUST
	if (u_rendering_gamma_correction_input_enabled) {
		color = gamma_correction_input(color, u_rendering_gamma);
	}
	#endif

	#ifdef ENABLE_SHARPENING
	if (u_sharpen_kernel != 0 && _should_sharpen()) {
		color = apply_sharpen_by_kernel(screen_texture, uv, SCREEN_PIXEL_SIZE);
	}
	#endif

	// Dithering -> Palette Mapping: First, the scene's lighting gets dithered, then palette mapping is applied on top of that.
	// Toggleable by defining REVERSE_DITHER_PALETTE_MAPPING

	#if not defined(REVERSE_DITHER_PALETTE_MAPPING) && defined(ENABLE_DITHERING)
	color = apply_dithering_by_mode(color, pixel_coord, u_dither_blue_noise_texture);
	#endif

	#ifdef ENABLE_PALETTE_MAPPING
	if (u_palette_shading_enabled) {
		if (u_palette_use_lut) {
			color = apply_palette_mapping_lut(color);
		} else if (u_palette_use_match_rgb) {
			color = apply_palette_mapping_rgb(color);
		} else {
			color = apply_palette_mapping_luminance(color);
		}
	}
	#endif

	#if defined(REVERSE_DITHER_PALETTE_MAPPING) && defined(ENABLE_DITHERING)
	color = apply_dithering_by_mode(color, pixel_coord, u_dither_blue_noise_texture);
	#endif

	#ifdef ENABLE_COLOR_ADJUST
	color = adjust_hue_shift(color, u_rendering_hue_shift);
	color = adjust_saturation(color, u_rendering_saturation);
	color = adjust_contrast(color, u_rendering_contrast);
	#endif

	#ifdef ENABLE_COLOR_ADJUST
	if (u_rendering_gamma_correction_output_enabled) {
		color = gamma_correction_output(color, u_rendering_gamma);
	}
	#endif

	COLOR = vec4(color, 1.0);
}
