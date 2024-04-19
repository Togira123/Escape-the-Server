shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 DefaultColor : source_color = vec4(0.250980, 0.611765, 0.741176, 1.000000);
uniform vec4 EmittingColor : source_color = vec4(0.000000, 0.180000, 1.000000, 1.000000);
uniform float progress = 0;
uniform float emit = 3;



void fragment() {
// ColorParameter:4
	vec4 n_out4p0 = DefaultColor;


// ColorParameter:6
	vec4 n_out6p0 = EmittingColor;


// FloatParameter:3
	float n_out3p0 = progress;


// Mix:5
	vec4 n_out5p0 = mix(n_out4p0, n_out6p0, vec4(n_out3p0));


// FloatParameter:7
	float n_out7p0 = emit;


// VectorOp:8
	vec4 n_out8p0 = n_out5p0 * vec4(n_out7p0);


// Output:0
	ALBEDO = vec3(n_out5p0.xyz);
	EMISSION = vec3(n_out8p0.xyz);


}