shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1);
uniform float alpha = 0.0;
const float line_thickness = 0.05;
const float aspect = 30.0 / 157.0;

void fragment() {
	float max_x = 1.0 - line_thickness;
	float min_x = line_thickness;
	float min_y = min_x * aspect;
	float max_y = 1.0 - min_y;
	if (UV.x < max_x && UV.x > min_x && UV.y < max_y && UV.y > min_y) {
		// inside rect
		float r = 0.0;
		float g = 0.0;
		if (UV.y > 0.5) {
			g = 1.0;
			r = (1.0 - UV.y) * 2.0;
		} else {
			g = UV.y * 2.0;
			r = 1.0;
		}
		COLOR = vec4(r, g, 0.0, alpha);
	} else {
		COLOR = vec4(vec3(0.0), alpha);
	}
}
