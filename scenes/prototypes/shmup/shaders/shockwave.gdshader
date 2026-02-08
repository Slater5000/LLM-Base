shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float radius : hint_range(0.0, 1.0) = 0.0;
uniform float thickness : hint_range(0.0, 0.2) = 0.05;
uniform float distortion : hint_range(0.0, 0.1) = 0.02;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	float dist = distance(uv, center);
	float ring = smoothstep(radius - thickness, radius, dist) * smoothstep(radius + thickness, radius, dist);

	vec2 dir = normalize(uv - center);
	vec2 displaced_uv = uv + dir * ring * distortion * fade;

	COLOR = texture(screen_texture, displaced_uv);
}
