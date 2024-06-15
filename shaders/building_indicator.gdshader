shader_type spatial;
render_mode cull_disabled;

uniform vec4 color : source_color = vec4(1);

void fragment() {
	ALBEDO = color.rgb;
	if (UV.y > 0.24825 && UV.y < 0.25125 || UV.y > 0.49825 && UV.y < 0.5025 || UV.y > 0.74825 && UV.y < 0.75125 || UV.y > 0.99825 || UV.y < 0.0025) {
		ALPHA = 1.0;
		EMISSION = color.rgb;
	} else {
		ALPHA = (0.62 - UV.x) * 4.1666 * 0.5;
	}
}
