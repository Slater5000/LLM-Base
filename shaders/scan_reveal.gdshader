shader_type canvas_item;

// Pixelate reveal shader for scanning mechanic
// As scan_progress increases, the image becomes clearer
// Heavy distortion at low progress makes creature identity harder to guess

uniform float scan_progress : hint_range(0.0, 1.0) = 0.0;
uniform float max_pixel_size : hint_range(4.0, 64.0) = 48.0;
uniform float min_pixel_size : hint_range(1.0, 4.0) = 1.0;
uniform bool show_silhouette = true;
uniform vec4 silhouette_color : source_color = vec4(0.15, 0.2, 0.3, 1.0);
uniform vec4 silhouette_outline_color : source_color = vec4(0.5, 0.7, 0.9, 1.0);
uniform float time : hint_range(0.0, 1000.0) = 0.0;

// Hash function for pseudo-random values
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth noise
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// More aggressive pixel size curve - stays chunky longer
	float progress_curve = pow(scan_progress, 2.0);
	float pixel_size = mix(max_pixel_size, min_pixel_size, progress_curve);

	// Get texture size
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));

	// === UV DISTORTION ===
	// Distortion strength decreases as scan progresses
	float distort_strength = (1.0 - scan_progress) * 0.15;

	// Animated wave distortion
	float wave_x = sin(UV.y * 8.0 + time * 3.0) * distort_strength;
	float wave_y = cos(UV.x * 6.0 + time * 2.5) * distort_strength;

	// Random jitter that changes over time (more at low progress)
	float jitter_strength = (1.0 - scan_progress) * 0.08;
	float jitter_x = (noise(UV * 10.0 + time * 0.5) - 0.5) * jitter_strength;
	float jitter_y = (noise(UV * 10.0 + time * 0.7 + 100.0) - 0.5) * jitter_strength;

	// Stretch/squash distortion (randomized per-instance via time seed)
	float stretch_amount = (1.0 - scan_progress) * 0.2;
	float stretch_x = 1.0 + sin(time * 0.1) * stretch_amount;
	float stretch_y = 1.0 + cos(time * 0.13) * stretch_amount;

	// Apply all distortions to UV
	vec2 distorted_uv = UV;
	distorted_uv.x += wave_x + jitter_x;
	distorted_uv.y += wave_y + jitter_y;
	distorted_uv = (distorted_uv - 0.5) * vec2(stretch_x, stretch_y) + 0.5;

	// Calculate organic edge fade (instead of hard clamp)
	// Use noise to create wavy, organic edges
	float edge_noise = noise(UV * 15.0 + time * 0.5) * 0.15;
	float edge_threshold = 0.08 + edge_noise;  // Wavy edge threshold

	// Soft fade near edges with noise
	float edge_fade = 1.0;
	edge_fade *= smoothstep(0.0, edge_threshold, distorted_uv.x);
	edge_fade *= smoothstep(0.0, edge_threshold, distorted_uv.y);
	edge_fade *= smoothstep(0.0, edge_threshold, 1.0 - distorted_uv.x);
	edge_fade *= smoothstep(0.0, edge_threshold, 1.0 - distorted_uv.y);

	// Clamp UV for sampling (but we'll use edge_fade for alpha)
	distorted_uv = clamp(distorted_uv, 0.0, 1.0);

	// === PIXELATION ===
	vec2 pixel_uv = floor(distorted_uv * tex_size / pixel_size) * pixel_size / tex_size;

	// Add per-pixel-block offset for extra scrambling at low progress
	float block_offset_strength = (1.0 - scan_progress) * 0.03;
	vec2 block_id = floor(distorted_uv * tex_size / pixel_size);
	float block_hash = hash(block_id + floor(time * 2.0));
	pixel_uv += (block_hash - 0.5) * block_offset_strength;
	pixel_uv = clamp(pixel_uv, 0.0, 1.0);

	vec4 tex_color = texture(TEXTURE, pixel_uv);

	if (show_silhouette && scan_progress < 1.0) {
		// Check for outline (sample neighboring pixels)
		float outline_size = 2.5 / tex_size.x;  // 2.5 pixel outline for visibility
		float neighbor_alpha = 0.0;
		neighbor_alpha += texture(TEXTURE, pixel_uv + vec2(outline_size, 0.0)).a;
		neighbor_alpha += texture(TEXTURE, pixel_uv + vec2(-outline_size, 0.0)).a;
		neighbor_alpha += texture(TEXTURE, pixel_uv + vec2(0.0, outline_size)).a;
		neighbor_alpha += texture(TEXTURE, pixel_uv + vec2(0.0, -outline_size)).a;
		// Also check diagonals for fuller outline
		neighbor_alpha += texture(TEXTURE, pixel_uv + vec2(outline_size, outline_size)).a;
		neighbor_alpha += texture(TEXTURE, pixel_uv + vec2(-outline_size, outline_size)).a;
		neighbor_alpha += texture(TEXTURE, pixel_uv + vec2(outline_size, -outline_size)).a;
		neighbor_alpha += texture(TEXTURE, pixel_uv + vec2(-outline_size, -outline_size)).a;

		bool is_outline = (tex_color.a < 0.1 && neighbor_alpha > 0.1);

		if (tex_color.a > 0.1) {
			// Inner silhouette - solid dark color
			float color_noise = noise(UV * 20.0 + time) * (1.0 - scan_progress) * 0.15;
			vec3 noisy_color = silhouette_color.rgb + vec3(color_noise);

			// Flicker alpha slightly
			float alpha_flicker = 1.0 - (noise(UV * 5.0 + time * 2.0) * (1.0 - scan_progress) * 0.15);

			// Apply organic edge fade
			COLOR = vec4(noisy_color, tex_color.a * alpha_flicker * edge_fade);
		} else if (is_outline && edge_fade > 0.3) {
			// Outline - lighter color for visibility (only show if not at faded edge)
			float outline_flicker = 0.8 + noise(UV * 10.0 + time * 3.0) * 0.2;
			COLOR = vec4(silhouette_outline_color.rgb, outline_flicker * edge_fade);
		} else {
			COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		}
	} else {
		COLOR = tex_color;
	}
}
