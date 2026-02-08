shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.2, 0.9, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;
uniform float glow_size : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 0.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float pulse = 1.0 + pulse_amount * sin(TIME * pulse_speed);

	// Core color with glow intensity
	COLOR = tex_color * glow_color * glow_intensity * pulse;
	COLOR.a = tex_color.a;
}
