shader_type canvas_item;
uniform vec4 color : source_color = vec4(1.0, 0.224, 0.0, 1);
uniform float alpha = 0.0;

uniform float MULTIPLIER = 0.56;
uniform float SCALE = 1.3;
uniform float SOFTNESS = 0.45;

void fragment(){
	float val = distance(vec2(UV.x , UV.y * MULTIPLIER), vec2(0.5 ,0.5 * MULTIPLIER));
	val = val / SCALE;
	float vignette = smoothstep(0.2, SOFTNESS, val);
	COLOR = vec4(color.rgb, vignette * alpha);
}