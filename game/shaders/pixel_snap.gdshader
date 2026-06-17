shader_type canvas_item;

uniform float virtual_width : hint_range(160.0, 1920.0) = 640.0;
uniform float virtual_height : hint_range(90.0, 1080.0) = 360.0;

void vertex() {
	vec2 virtual_size = vec2(virtual_width, virtual_height);
	VERTEX = floor(VERTEX * virtual_size + 0.5) / virtual_size;
}

void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
}
