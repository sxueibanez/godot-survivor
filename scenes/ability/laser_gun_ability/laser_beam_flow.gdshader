shader_type canvas_item;
render_mode blend_add;

uniform float flow_speed = 16.0;
uniform float flow_bands = 8.0;
const float FRAME_TIME = 0.07;


void fragment() {
	vec4 tint = COLOR;
	float frame = mod(floor(TIME / FRAME_TIME), 8.0);
	float column = mod(frame, 2.0);
	float row = floor(frame / 2.0);
	vec2 frame_uv = vec2(
		column * 0.5 + 0.015625 + UV.x * 0.46875,
		row * 0.25 + 0.0625 + UV.y * 0.125
	);
	vec4 beam = texture(TEXTURE, frame_uv);
	float moving_band = pow(0.5 + 0.5 * sin(UV.x * 6.283185 * flow_bands - TIME * flow_speed), 6.0);
	float flicker = 0.94 + 0.06 * sin(TIME * 31.0 + UV.x * 17.0);
	beam.rgb *= (0.82 + moving_band * 0.75) * flicker;
	beam.rgb += vec3(0.08, 0.65, 1.0) * moving_band * beam.a * 0.35;
	beam.a *= 0.9 + moving_band * 0.1;
	COLOR = beam * tint;
}
