shader_type canvas_item;

// Renders sprite as a solid dark silhouette with a lighter outline
// Used for undiscovered creatures in the Deck UI and scanning

uniform vec4 silhouette_color : source_color = vec4(0.15, 0.2, 0.3, 1.0);
uniform vec4 outline_color : source_color = vec4(0.5, 0.7, 0.9, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));

	// Check for outline (sample neighboring pixels)
	float outline_size = 2.5 / tex_size.x;  // 2.5 pixel outline for visibility
	float neighbor_alpha = 0.0;
	neighbor_alpha += texture(TEXTURE, UV + vec2(outline_size, 0.0)).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_size, 0.0)).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(0.0, outline_size)).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(0.0, -outline_size)).a;
	// Also check diagonals for fuller outline
	neighbor_alpha += texture(TEXTURE, UV + vec2(outline_size, outline_size)).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_size, outline_size)).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(outline_size, -outline_size)).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_size, -outline_size)).a;

	bool is_outline = (tex_color.a < 0.1 && neighbor_alpha > 0.1);

	if (tex_color.a > 0.1) {
		// Inner silhouette
		COLOR = vec4(silhouette_color.rgb, tex_color.a);
	} else if (is_outline) {
		// Visible outline
		COLOR = vec4(outline_color.rgb, 0.9);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
