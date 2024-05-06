shader_type canvas_item;

uniform float alpha = 0.0;

void fragment() {
	if (texture(TEXTURE, UV).a > 0.0) {
		COLOR = vec4(0.345, 0.051, 0.525, alpha);
	}
}
