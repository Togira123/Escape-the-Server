shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a > 0.4) {
		if (tex.r == 1.0 && tex.g == 1.0 && tex.b == 1.0) {
			COLOR = vec4(0.0, 0.0, 1.0 - UV.x, 1.0);
		} else {
			COLOR = vec4(1.0);
		}
	} else {
		COLOR = vec4(0.0);
	}
}
