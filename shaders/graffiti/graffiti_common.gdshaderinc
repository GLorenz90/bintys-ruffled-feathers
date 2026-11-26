// graffiti_common.gdshaderinc
// Shared, texture-free noise for the graffiti-toon look.
// Place at: res://shaders/graffiti/graffiti_common.gdshaderinc

float gf_hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

// Smooth 3D value noise, 0..1.
float gf_value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float n000 = gf_hash13(i);
	float n100 = gf_hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = gf_hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = gf_hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = gf_hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = gf_hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = gf_hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = gf_hash13(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
		mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y),
		u.z);
}

// Large, soft blotches: uneven paint coverage. 0..1.
float gf_mottle(vec3 p, float scale) {
	return gf_value_noise(p * scale);
}

// Fine overspray speckle, 0..1.
// footprint = world (or object) size of one screen pixel at this point.
// Fades to neutral 0.5 when the speckle would be smaller than a pixel,
// so distant surfaces don't sparkle or shimmer.
float gf_speckle(vec3 p, float scale, float footprint) {
	float n = smoothstep(0.25, 0.75, gf_value_noise(p * scale));
	float alias = smoothstep(0.35, 1.0, footprint * scale);
	return mix(n, 0.5, alias);
}

// Small hue rotation (radians) around the grey axis.
vec3 gf_hue_shift(vec3 c, float a) {
	const vec3 k = vec3(0.57735);
	float ca = cos(a);
	return c * ca + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - ca);
}

// Interleaved gradient noise: a fine, even per-pixel dither pattern, 0..1.
// Used to fade light/shadow edges as a spray-dot gradient.
float gf_dither(vec2 frag_coord) {
	return fract(52.9829189 * fract(dot(frag_coord, vec2(0.06711056, 0.00583715))));
}
