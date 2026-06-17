shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.25, 0.95, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 3.0) = 1.2;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed);
	vec3 energized = base.rgb + glow_color.rgb * base.a * glow_strength * pulse;
	COLOR = vec4(energized, base.a * COLOR.a);
}
