shader_type canvas_item;

uniform float value = 1.0;

vec3 hsv2rgb(vec3 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    // Calculate polar coordinates
    float angle = atan(UV.y - 0.5, UV.x - 0.5);
    float radius = length(UV - vec2(0.5));
    // Map angle to hue
    float hue = (angle + 3.1416) / (2.0 * 3.1416);

    // Calculate saturation and value
    float saturation = radius * 2.0;

    // Convert HSV to RGB
    vec3 rgb = hsv2rgb(vec3(hue, saturation, value));

    COLOR = vec4(rgb, texture(TEXTURE, UV).a);
}