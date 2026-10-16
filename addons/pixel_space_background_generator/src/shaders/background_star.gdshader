shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D colorscheme;

void fragment() {
	float col_val = texture(TEXTURE, UV).r;
	float a = texture(TEXTURE, UV).a;
	vec4 replace_col = texture(colorscheme, vec2(round(col_val * 7.0) / 7.0, 0.0));
	COLOR = vec4(replace_col.rgb, a);
}