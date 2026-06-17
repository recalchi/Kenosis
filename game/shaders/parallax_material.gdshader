shader_type canvas_item;

uniform vec2 parallax_offset = vec2(0.0);
uniform float depth : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec2 shifted_uv = UV + parallax_offset * depth * TEXTURE_PIXEL_SIZE;
	COLOR = texture(TEXTURE, shifted_uv) * COLOR;
}
