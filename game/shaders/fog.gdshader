shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.55, 0.68, 0.78, 0.35);
uniform float density : hint_range(0.0, 1.0) = 0.4;
uniform float speed : hint_range(0.0, 2.0) = 0.15;

void fragment() {
	float wave = sin((UV.x + TIME * speed) * 10.0) * 0.5 + 0.5;
	float vertical = smoothstep(0.05, 0.95, UV.y);
	float alpha = fog_color.a * density * mix(0.45, 1.0, wave) * vertical;
	COLOR = vec4(fog_color.rgb, alpha) * COLOR;
}
