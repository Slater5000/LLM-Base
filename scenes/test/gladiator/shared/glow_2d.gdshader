shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform bool enable_pulse = true;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	float pulse = 1.0;
	if (enable_pulse) {
		pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
	}

	// Add glow based on alpha
	col.rgb = mix(col.rgb, glow_color.rgb, 0.5);
	col.rgb += glow_color.rgb * glow_intensity * pulse * col.a;

	COLOR = col;
}
