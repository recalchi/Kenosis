shader_type canvas_item;

uniform float strength : hint_range(0.0, 0.08) = 0.012;
uniform float speed : hint_range(0.0, 8.0) = 2.0;
uniform vec4 corruption_tint : source_color = vec4(0.55, 0.12, 0.82, 1.0);

void fragment() {
	vec2 wave = vec2(
		sin(UV.y * 34.0 + TIME * speed),
		cos(UV.x * 29.0 - TIME * speed * 0.8)
	) * strength;
	vec4 base = texture(TEXTURE, UV + wave);
	base.rgb = mix(base.rgb, corruption_tint.rgb, 0.18 * base.a);
	COLOR = base * COLOR;
}
