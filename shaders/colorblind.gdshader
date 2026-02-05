shader_type canvas_item;

// Colorblind correction mode:
// 0 = Off (no correction)
// 1 = Deuteranopia/Protanopia friendly (red-green)
uniform int mode : hint_range(0, 1) = 0;

// Sample the screen behind this node for post-processing
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);

	if (mode == 1) {
		// Deuteranopia/Protanopia friendly mode
		// Shifts reds toward orange/yellow and greens toward cyan/blue
		// This makes red vs green more distinguishable

		float r = color.r;
		float g = color.g;
		float b = color.b;

		// Increase separation between red and green channels
		// by shifting red toward orange and green toward cyan
		float new_r = r * 0.8 + g * 0.2;
		float new_g = g * 0.7 + b * 0.3;
		float new_b = b * 0.9 + r * 0.1;

		// Also increase overall saturation for better distinction
		vec3 gray = vec3(dot(vec3(new_r, new_g, new_b), vec3(0.299, 0.587, 0.114)));
		vec3 saturated = mix(gray, vec3(new_r, new_g, new_b), 1.3);

		COLOR = vec4(clamp(saturated, 0.0, 1.0), color.a);
	} else {
		COLOR = color;
	}
}
