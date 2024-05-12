shader_type canvas_item;

const float radius = 0.3;
const float outer_radius = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float x_square = (UV.x - 0.5) * (UV.x - 0.5);
	float y_square = (UV.y - 0.5) * (UV.y - 0.5);
	if (sqrt(x_square + y_square) < outer_radius) {
		if (sqrt(x_square + y_square) < radius) {
			COLOR = vec4(0.0);
		} else {
			COLOR = vec4(vec3(0.0), tex.a);
		}
	} else {
		COLOR = vec4(0.0);
	}
}