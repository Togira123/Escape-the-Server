shader_type canvas_item;

const float LEN = 0.18;
const float LEN_INV = 1.0 / LEN;
const float LEN2 = 1.0 - LEN;

void fragment() {
	if (UV.y > UV.x * LEN_INV || 1.0 - UV.y < (UV.x - LEN2) * LEN_INV) {
		COLOR = vec4(0.0);
	}
}
