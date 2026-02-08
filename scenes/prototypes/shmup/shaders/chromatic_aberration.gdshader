shader_type canvas_item;

uniform float intensity : hint_range(0.0, 10.0) = 0.0;
uniform float max_offset : hint_range(0.0, 0.05) = 0.01;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 offset = vec2(max_offset * intensity, 0.0);

	float r = texture(screen_texture, SCREEN_UV - offset).r;
	float g = texture(screen_texture, SCREEN_UV).g;
	float b = texture(screen_texture, SCREEN_UV + offset).b;

	COLOR = vec4(r, g, b, 1.0);
}
