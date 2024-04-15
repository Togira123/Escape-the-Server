shader_type spatial;

uniform vec3 base_color = vec3(6.897, 0.833, 0.912);
uniform vec3 fresnel_color = vec3(0.149, 0.141, 0.824);
uniform float exponent = 3;
uniform float intensity = 10;
uniform bool turned_on = false;

vec3 fresnel_glow(float expo, float inten, vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(normalize(normal), normalize(view))), exponent) * color * intensity;
}

void fragment()
{
	vec3 fresnel = fresnel_glow(exponent, intensity, fresnel_color, NORMAL, VIEW);
	ALBEDO = base_color + fresnel;
	EMISSION = fresnel;
	if (turned_on) {
		ALPHA = 1.0;
	} else {
		ALPHA = 0.0;
	}
}