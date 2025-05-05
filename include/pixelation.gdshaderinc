#ifndef PIXELATION
#define PIXELATION

/** Pixelation removes sub-pixel detail, which reduces or negates the visual effect of sharpening.
 * Since sharpening is applied *after* pixelation, enabling both can waste performance and cause artifacts.
 *
 * Recommended: Use either pixelation OR sharpening, not both.
 */
uniform bool u_pixelation_enabled = false;
uniform int u_pixelation_size : hint_range(1, 16) = 2;

vec2 get_pixelated_coord(vec2 pixel_coord, int pixel_chunk_size) {
	if (pixel_chunk_size <= 1) return pixel_coord;

	return floor(pixel_coord / float(pixel_chunk_size)) * float(pixel_chunk_size) + float(pixel_chunk_size) * 0.5;
}

vec2 to_pixelated_uv(vec2 pixel_size, vec2 uv, int pixel_chunk_size) {
	// Convert UV coordinates to "virtual pixel" space based on u_pixel_size.
	// This snaps UVs to the center of the nearest virtual pixel block:
	// 1. Multiply UVs by virtual grid size -> scales up to a virtual pixel grid
	// 2. floor() -> snaps to the bottom-left corner of that block
	// 3. +0.5 -> moves to the center of the block
	// 4. Divide by grid size -> scales back to normal UV space

	float pixelation_scale = float(pixel_chunk_size);
	vec2 virtual_pixel_grid_size = (1.0 / pixel_size) / pixelation_scale;
	vec2 snapped_uv = (floor(uv * virtual_pixel_grid_size) + 0.5) / virtual_pixel_grid_size;

	return snapped_uv;
}

#endif