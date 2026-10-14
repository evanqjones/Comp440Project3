shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform vec4 aura_color : source_color = vec4(0.55, 0.8, 1.0, 1.0);

void fragment() {
	float radius = length(UV * 2.0 - vec2(1.0));
	float edge_fade = 1.0 - smoothstep(0.12, 1.0, radius);
	float center_softness = mix(0.72, 1.0, smoothstep(0.0, 0.42, radius));
	ALBEDO = aura_color.rgb;
	EMISSION = aura_color.rgb * 1.6;
	ALPHA = edge_fade * center_softness * 0.52;
}
