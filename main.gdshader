shader_type canvas_item;
render_mode unshaded;

#define ENABLE_DITHERING
#define ENABLE_PALETTE_MAPPING
#define ENABLE_PIXELATION
#define ENABLE_SHARPENING
#define ENABLE_COLOR_ADJUST
#define ENABLE_PS1
#define ENABLE_CRT
#define ENABLE_VHS

/** Allows both pixelation and sharpening to be applied simultaneously.
 * This is discouraged, as it often produces visual artifacts.
 */
//#define ALLOW_PIXELATION_SHARPEN_COMBO

/** Change from "Dithering -> Palette Mapping" to "Palette Mapping -> Dithering" */
//#define REVERSE_DITHER_PALETTE_MAPPING

/** Allows blending between color texture and LUT palette mapping.
 * Computes both mappings simultaneously - may impact performance on low-end GPUs.
 */
#define ALLOW_PALETTE_LUT_BLEND

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

#if defined(ENABLE_CRT) || defined(ENABLE_VHS)
#include "include/crt.gdshaderinc"
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

	#ifdef ENABLE_CRT
	uv = apply_crt_warp(uv);
	#endif

	#ifdef ENABLE_VHS
	vec3 color = apply_vhs_chromatic(screen_texture, uv);
	#else
	vec3 color = texture(screen_texture, uv).rgb;
	#endif

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
		#ifdef ALLOW_PALETTE_LUT_BLEND
		vec3 tex_color = u_palette_use_match_rgb
			? apply_palette_mapping_rgb(color)
			: apply_palette_mapping_luminance(color);

		if (u_palette_use_lut) {
			vec3 lut_color = apply_palette_mapping_lut(color);
			color = mix(tex_color, lut_color, u_palette_lut_blend);
		} else {
			color = tex_color;
		}
		#else
		if (u_palette_use_lut) {
			color = apply_palette_mapping_lut(color);
		} else if (u_palette_use_match_rgb) {
			color = apply_palette_mapping_rgb(color);
		} else {
			color = apply_palette_mapping_luminance(color);
		}
		#endif
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

	#ifdef ENABLE_CRT
	float pixel_scale = 1.0;
	#ifdef ENABLE_PIXELATION
	pixel_scale = u_pixelation_enabled ? float(u_pixelation_size) * SCREEN_PIXEL_SIZE.y : SCREEN_PIXEL_SIZE.y;
	#else
	pixel_scale = SCREEN_PIXEL_SIZE.y;
	#endif
	color = apply_crt_scanlines(color, SCREEN_UV, pixel_scale);
	#endif

	#ifdef ENABLE_VHS
	color = apply_vhs_tracking(color, SCREEN_UV, TIME);
	color = apply_vhs_noise(color, SCREEN_UV, TIME);
	#endif

	#ifdef ENABLE_CRT
	color = apply_crt_vignette(color, SCREEN_UV);
	color = apply_crt_black_bars(color, SCREEN_UV);
	#endif

	COLOR = vec4(color, 1.0);
}
