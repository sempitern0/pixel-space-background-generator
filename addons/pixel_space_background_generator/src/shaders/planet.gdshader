shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float size = 50.0;
uniform int OCTAVES : hint_range(0, 20, 1);
uniform float seed: hint_range(1, 10);
uniform float pixels = 100.0;
uniform sampler2D colorscheme;
uniform vec2 light_origin;
uniform int surface_type = 0;
uniform float surface_detail : hint_range(0.0, 1.0) = 0.65;
// Optional organic direction. Zero strengths preserve classic pixels.
uniform float organic_strength : hint_range(0.0, 1.0) = 0.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform float organic_phase = 0.0;


float rand(vec2 coord) {
	return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * 15.5453 * seed);
}

float noise(vec2 coord){
	vec2 i = floor(coord);
	vec2 f = fract(coord);
		
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVES ; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

bool dither(vec2 uv1, vec2 uv2) {
	return mod(uv1.y+uv2.x,2.0/pixels) <= 1.0 / pixels;
}

float circleNoise(vec2 uv) {
    float uv_y = floor(uv.y);
    uv.x += uv_y*.31;
    vec2 f = fract(uv);
	float h = rand(vec2(floor(uv.x),floor(uv_y)));
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

vec2 spherify(vec2 uv) {
	vec2 centered = uv *2.0-1.0;
	float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
//	float z = pow(1.0 - dot(centered.xy, centered.xy), 0.5);
	vec2 sphere = centered/(z + 1.0);
	
	return sphere * 0.5+0.5;
}

float cloud_alpha(vec2 uv) {
	float c_noise = 0.0;
	
	// more iterations for more turbulence
	int iters = 2;
	for (int i = 0; i < iters; i++) {
		float relative = (float(i)/float(iters));
		vec2 c_uv = rotate(uv, relative * 6.28);
		c_noise += circleNoise((uv * 0.3) + (float(i+1)+10.));
	}
	float fbm = fbm(uv+c_noise);
	
	return fbm;
}


void fragment() {
	/// pixelzing and dithering
	vec2 uv = floor(UV * pixels) / pixels;
	bool dith = dither(UV, uv);
	
	// distance from center, to create a circle
	float d_to_center = distance(uv , vec2(0.5));
	uv = spherify(uv);
	
	// distance from light source, to create shading
	float d_to_light = distance(uv, light_origin);
	// bit of contrast
	d_to_light += pow(d_to_center * 3.0, 4.0) * 0.05;
	
	// noise for the planet
	float n = fbm(uv * size);
	float n2 = fbm(uv * size + n*3.0);
	float mixed = n2 * d_to_light;
	if (organic_strength > 0.0) {
		// Slowly warped sampled terrain, no extra FBM call.
		float flow = sin(uv.x * 18.0 + n * 7.0 + organic_phase * 6.28318);
		float grain = sin((uv.y + flow * 0.045) * 27.0 + organic_phase * 4.0);
		float patch = smoothstep(0.24, 0.78, n2 + flow * 0.15 + grain * 0.08);
		mixed = mix(mixed, (0.12 + patch * 0.79) * d_to_light, organic_strength * 0.48);
	}
	if (surface_type == 1) {
		// Crust and highland breakup: two noise scales and coarse crater contrast.
		float crust = fbm(uv * size * 2.4 + vec2(seed * 0.17));
		float highlands = smoothstep(0.39, 0.61, crust);
		mixed = mix(mixed, (0.30 + highlands * 0.48 + n * 0.22) * d_to_light, surface_detail);
	} else if (surface_type == 2) {
		// Broad latitudinal cloud bands warped by low-frequency flow.
		float latitude = uv.y + (n - 0.5) * 0.19 * surface_detail;
		float bands = sin(latitude * (19.0 + seed * 0.7)) * 0.5 + 0.5;
		mixed = mix(mixed, (0.24 + bands * 0.62 + n2 * 0.14) * d_to_light, surface_detail);
	} else if (surface_type == 3) {
		// Ice fields: smooth snowcaps above darker fissures.
		float cracks = 1.0 - smoothstep(0.045, 0.15, abs(n - 0.48));
		float polar = smoothstep(0.19, 0.50, abs(uv.y - 0.5));
		mixed = mix(mixed, (0.70 + polar * 0.25 - cracks * 0.38) * d_to_light, surface_detail);
	}
	
	if (organic_strength > 0.0 && surface_type == 2) {
		// Gas bands meander instead of following identical latitudes.
		float warped_latitude = uv.y + (n - 0.5) * (0.13 + organic_strength * 0.22);
		float swirling = sin(warped_latitude * 24.0 + n2 * organic_strength * 5.0 + organic_phase * 3.0);
		mixed = mix(mixed, (0.45 + swirling * 0.27) * d_to_light, organic_strength * 0.42);
	}

	// optionally create some contrast with this
//	mixed = pow(mixed, 1.0);

	// apply dithering
	if (dith) {
		mixed *= 0.95;
	}
	
	// choose and apply colors
	float col_val = floor(mixed * 15.0) / 7.0;
	vec3 col = texture(colorscheme, vec2(col_val, 0.0)).rgb;
	if (rim_strength > 0.0) {
		float limb = smoothstep(0.34, 0.50, d_to_center);
		float glow = rim_strength * limb * (0.11 + 0.11 * organic_strength);
		col = mix(col, texture(colorscheme, vec2(0.90, 0.0)).rgb, glow);
	}
	
	// apply alpha
	float a = step(d_to_center, 0.5);
	COLOR = vec4(col, a);
}