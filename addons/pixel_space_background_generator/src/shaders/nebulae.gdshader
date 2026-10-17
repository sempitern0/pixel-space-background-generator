shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform float size = 50.0;
uniform int OCTAVES : hint_range(0, 20, 1);
uniform float seed: hint_range(1, 10);
uniform float pixels = 100.0;
uniform sampler2D colorscheme;
uniform vec4 background_color : source_color;
uniform bool should_tile = false;
uniform bool reduce_background = false;
uniform vec2 uv_correct = vec2(1.0);
// Pixel-space layer scroll; zero reproduces the original static shader.
uniform vec2 parallax_uv_offset = vec2(0.0);
uniform float filament_strength : hint_range(0.0, 1.0) = 0.0;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.5;
// Classic 0 retains the original output. Alternate shapes reuse sampled noise.
uniform int nebula_profile : hint_range(0, 4) = 0;
uniform float organic_strength : hint_range(0.0, 1.0) = 0.0;
uniform float flow_angle = 0.0;

float rand(vec2 coord, float tilesize) {
	if (should_tile) {
		coord = mod(coord / uv_correct, tilesize);
	}

	return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * (15.5453 + seed));
}

float noise(vec2 coord, float tilesize){
	vec2 i = floor(coord);
	vec2 f = fract(coord);

	float a = rand(i, tilesize);
	float b = rand(i + vec2(1.0, 0.0), tilesize);
	float c = rand(i + vec2(0.0, 1.0), tilesize);
	float d = rand(i + vec2(1.0, 1.0), tilesize);

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord, float tilesize){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVES ; i++){
		value += noise(coord, tilesize ) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

bool dither(vec2 uv1, vec2 uv2) {
	return mod(uv1.y+uv2.x,2.0/pixels) <= 1.0 / pixels;
}

float circleNoise(vec2 uv, float tilesize) {
	if (should_tile) {
		uv = mod(uv, tilesize / uv_correct);
	}

    float uv_y = floor(uv.y);
    uv.x += uv_y*.31;
    vec2 f = fract(uv);
	float h = rand(vec2(floor(uv.x),floor(uv_y)), tilesize);
    float m = (length(f-0.25-(h*0.5)));
    float r = h*0.25;
    return smoothstep(0.0, r, m*0.75);
}

vec2 rotate(vec2 vec, float angle) {
	vec -=vec2(0.5);
	vec *= mat2(vec2(cos(angle),-sin(angle)), vec2(sin(angle),cos(angle)));
	vec += vec2(0.5);
	return vec;
}

float cloud_alpha(vec2 uv, float tilesize) {
	float c_noise = 0.0;

	// more iterations for more turbulence
	int iters = 2;
	for (int i = 0; i < iters; i++) {
		c_noise += circleNoise(uv * 0.5 + (float(i+1)) + vec2(-0.3, 0.0), ceil(tilesize * 0.5));
	}
	float fbm = fbm(uv+c_noise, tilesize);

	return fbm;
}

void fragment() {
	// pixelizing and dithering
	vec2 uv = floor((UV + parallax_uv_offset) * pixels) / pixels;

	// distance from center
	float d =  distance(uv, vec2(0.5)) * 0.4;

	uv *= uv_correct;
	bool dith = dither(uv, UV);

	// noise for the inside of the nebulae
	float n = cloud_alpha(uv * size, size);
	float n2 = fbm(uv * size + vec2(1, 1), size);
	float n_lerp = n2 * n;
	float n_dust = n; // The two expressions are identical; reuse the existing FBM.
	float n_dust_lerp = n_dust * n_lerp;
	if (organic_strength > 0.0) {
		// Organic flows reuse existing samples, avoiding additional FBM loops.
		vec2 direction = vec2(cos(flow_angle), sin(flow_angle));
		float sweep = dot(uv * size, direction);
		float turbulence = sin(sweep * 0.37 + n * 7.0 + seed);
		float folds = smoothstep(0.20, 0.78, n2 + turbulence * 0.21);
		n_dust_lerp = mix(n_dust_lerp, n_dust_lerp * (0.48 + folds * 1.19), organic_strength);
	}
	if (nebula_profile == 1) { // thin atmospheric wisps
		n_dust_lerp *= smoothstep(0.25, 0.66, abs(n - n2) * 2.0);
	} else if (nebula_profile == 2) { // broad translucent veils
		n_dust_lerp = mix(n_dust_lerp, n * 0.50, 0.65);
	} else if (nebula_profile == 3) { // dense continuous banks
		n_dust_lerp = mix(n_dust_lerp, n2 * n2, 0.58);
	} else if (nebula_profile == 4) { // dark cavities and ring-like boundaries
		n_dust_lerp *= smoothstep(0.15, 0.42, abs(n2 - 0.50));
	}
	if (filament_strength > 0.0) {
		// Domain-warped filaments mix with the original soft cloud field.
		float turbulence = fbm(uv * size * 2.0 + vec2(4.1, 9.3), size * 2.0);
		float warped = fbm(uv * size * 1.6 + vec2(turbulence * 6.0), size * 1.6);
		float filaments = 1.0 - smoothstep(0.04, 0.22, abs(warped - 0.53));
		n_dust_lerp = mix(n_dust_lerp, n_dust_lerp * (0.45 + filaments * 1.35), filament_strength);
	}

	// apply dithering
	if (dith) {
		n_dust_lerp *= 0.95;
		n_lerp *= 0.95;
		d*= 0.98;
	}

	// slightly offset alpha values to create thin bands around the nebulae
	float a = step(n2, 0.1 + d);
	float a2 = step(n2, 0.115 + d);
	if (should_tile) {
		a = step(n2, 0.3);
		a2 = step(n2, 0.315);
	}

	// choose colors
	if (reduce_background) {
		n_dust_lerp = pow(n_dust_lerp, 1.2) * 0.7;
	}
	float col_value = 0.0;
	if (a2 > a) {
		col_value = floor(n_dust_lerp * 35.0) / 7.0;
	} else {
		col_value = floor(n_dust_lerp * 14.0) / 7.0;
	}

	// apply colors
	vec3 col = texture(colorscheme, vec2(col_value, 0.0)).rgb;
	if (col_value < 0.1) {
		col = background_color.rgb;
	}

	// Keep the historical alpha mask at 0.5 coverage, retaining old seeds.
	float threshold_shift = (0.5 - cloud_coverage) * 0.26;
	if (nebula_profile == 1) {
		threshold_shift += 0.045;
	} else if (nebula_profile == 2) {
		threshold_shift -= 0.025;
	} else if (nebula_profile == 3) {
		threshold_shift -= 0.060;
	} else if (nebula_profile == 4) {
		threshold_shift += 0.025;
	}
	COLOR = vec4(col, step(n2, (should_tile ? 0.315 : 0.115 + d) - threshold_shift));
}