shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.001, 0.2) = 0.06;
uniform vec4 edge_color : source_color = vec4(0.55, 0.95, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float noise = hash(floor(UV * 96.0));
	float alpha_mask = step(progress, noise);
	float edge = step(progress, noise) - step(progress + edge_width, noise);
	base.rgb = mix(base.rgb, edge_color.rgb, edge);
	base.a *= alpha_mask;
	COLOR = base * COLOR;
}
