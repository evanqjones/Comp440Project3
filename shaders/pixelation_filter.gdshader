shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_size : hint_range(1.0, 8.0, 0.5) = 3.0;

void fragment() {
	vec2 screen_size = vec2(1.0) / SCREEN_PIXEL_SIZE;
	vec2 pixel_grid = max(screen_size / pixel_size, vec2(1.0));
	vec2 snapped_uv = (floor(SCREEN_UV * pixel_grid) + vec2(0.5)) / pixel_grid;
	COLOR = texture(screen_texture, snapped_uv);
}
