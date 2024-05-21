shader_type canvas_item;

uniform float radius = 0.5;

void fragment() {
	if (length(UV - vec2(0.5)) > radius) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, UV);
	}
}
