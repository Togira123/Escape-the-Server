shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.555, 0.0, 0.555, 1.0);
uniform vec4 inside_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);

void fragment() {
	// 3.0 is the line thickness
	vec2 size = TEXTURE_PIXEL_SIZE * 3.0;

	float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	outline = min(outline, 1.0);

	vec4 color = texture(TEXTURE, UV);
	if (color.a > 0.3) {
		COLOR = inside_color;
	} else {
		COLOR = mix(color, line_color, outline - color.a);
	}
}