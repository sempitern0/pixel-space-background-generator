shader_type canvas_item;
render_mode blend_mix, unshaded;

// Five 21x21 glyphs in the shared star atlas: x = 2 + 25 * index, y = 2.
uniform sampler2D colorscheme;
uniform vec2 camera_offset = vec2(0.0);
varying float glyph_index;

void vertex() {
	glyph_index = floor(INSTANCE_CUSTOM.r * 4.0 + 0.5);
	float depth = INSTANCE_CUSTOM.g * 2.0;
	VERTEX -= camera_offset * depth;
}

void fragment() {
	vec2 atlas_size = vec2(textureSize(TEXTURE, 0));
	vec2 atlas_uv = (vec2(2.0 + glyph_index * 25.0, 2.0) + UV * vec2(21.0)) / atlas_size;
	vec4 glyph = texture(TEXTURE, atlas_uv);
	vec3 mapped = texture(colorscheme, vec2(round(glyph.r * 7.0) / 7.0, 0.0)).rgb;
	COLOR = vec4(mapped, glyph.a);
}
