shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.35, 1.0, 0.95, 1.0);
uniform float width : hint_range(0.5, 4.0) = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * width;
	float around = 0.0;
	around = max(around, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	around = max(around, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
	vec4 outlined = mix(outline_color, base, base.a);
	outlined.a = max(base.a, around * (1.0 - base.a));
	COLOR = outlined * COLOR;
}
