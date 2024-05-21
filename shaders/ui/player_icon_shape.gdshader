shader_type canvas_item;

uniform float radius = 0.5;
uniform vec4 bg_color: source_color = vec4(vec3(0.0), 0.5);

void fragment() {
	if (length(UV - vec2(0.5)) > radius) {
		COLOR = vec4(0.0);
	} else {
		vec3 alpha = vec3(texture(TEXTURE, UV).a);
		if (alpha.r == 0.0) {
			COLOR = vec4(alpha, 0.5);
		} else {
			COLOR = vec4(alpha, max(0.5, alpha.r));
		}
	}
}
