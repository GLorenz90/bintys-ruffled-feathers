// toon_graffiti.gdshader
// Banded toon lighting with anti-aliased terminators and spray-paint grain.
// Use on every opaque mesh (characters + environment).
// Place at: res://shaders/graffiti/toon_graffiti.gdshader
shader_type spatial;
render_mode cull_back;

#include "res://shaders/graffiti/graffiti_common.gdshaderinc"

group_uniforms surface;
// Tick on character materials: the edge pass gives them the thick outer outline.
uniform bool is_character = false;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
// Tinted fill so shadows read as a paint colour instead of black.
// Keep the WorldEnvironment ambient low when using this.
uniform vec4 shadow_fill : source_color = vec4(0.34, 0.28, 0.48, 1.0);
uniform float shadow_fill_strength : hint_range(0.0, 1.0) = 0.5;

group_uniforms toon;
uniform int bands : hint_range(1, 4) = 2;
// Pushes the light/shadow line forward (+) or back (-).
uniform float terminator_wrap : hint_range(-0.5, 0.5) = 0.0;
// Width of the anti-aliasing fade, in roughly pixels.
uniform float edge_softness : hint_range(0.25, 4.0) = 1.25;
// Floor for the fade so flat surfaces under point lights don't alias.
uniform float min_edge_width : hint_range(0.0, 0.1) = 0.012;
// Softness of directional-light cast shadow edges (thresholded at 50% shadow).
uniform float shadow_softness : hint_range(0.01, 0.5) = 0.08;
uniform float specular_size : hint_range(0.0, 1.0) = 0.12;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.35;
uniform float rim_width : hint_range(0.0, 1.0) = 0.22;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.3;

group_uniforms overspray;
// Object space: grain sticks to moving characters. World space: seamless across tiled level pieces.
uniform bool grain_in_object_space = true;
uniform float mottle_scale = 3.0;
uniform float speckle_scale = 220.0; // fine colour grain (dots per unit)
uniform float value_variation : hint_range(0.0, 0.3) = 0.035;
uniform float hue_variation : hint_range(0.0, 0.3) = 0.02;
// Width of the dithered spray fade on light/shadow edges, in band units (0 = clean edge).
uniform float spray_fade : hint_range(0.0, 0.6) = 0.18;
group_uniforms;

varying vec3 v_grain_pos;
varying float v_edge_w;   // fragment -> light: AA width
varying float v_dither;   // fragment -> light: per-pixel dither, -0.5..0.5

void vertex() {
	v_grain_pos = grain_in_object_space ? VERTEX : (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo_color.rgb * texture(albedo_texture, UV).rgb;

	float footprint = length(fwidth(v_grain_pos));
	float mottle = gf_mottle(v_grain_pos, mottle_scale) - 0.5;
	float speckle = gf_speckle(v_grain_pos, speckle_scale, footprint) - 0.5;
	v_dither = gf_dither(FRAGCOORD.xy) - 0.5;

	base = gf_hue_shift(base, mottle * hue_variation * 6.2831);
	base *= 1.0 + mottle * 2.0 * value_variation + speckle * value_variation;

	ALBEDO = base;
	// Roughness doesn't affect this shader's lighting, so it carries the character tag
	// (0.5) to the edge pass through Godot's normal-roughness buffer.
	ROUGHNESS = is_character ? 0.5 : 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0; // no PBR reflections; highlights come from light()
	EMISSION = base * shadow_fill.rgb * shadow_fill_strength;

	// How fast the normal (and therefore N·L) changes per pixel.
	v_edge_w = max(length(fwidth(NORMAL)) * edge_softness, min_edge_width);
}

// Soft staircase: steps at integer x, each faded over +-w.
float toon_step(float x, float w) {
	float y = x - 0.5;
	return floor(y) + smoothstep(0.5 - w, 0.5 + w, fract(y));
}

void light() {
	float fb = float(bands);
	float ndl = dot(NORMAL, LIGHT);
	float ndl_w = (ndl + terminator_wrap) / (1.0 + terminator_wrap);
	float jitter = v_dither * spray_fade;
	float w = clamp(v_edge_w * fb, 0.001, 0.49);

	// Directional: bands from N·L only, cast shadows thresholded separately so they stay crisp.
	// Omni/spot: distance falloff goes through the bands too, giving toon light pools.
	float x = LIGHT_IS_DIRECTIONAL ? ndl_w : ndl_w * ATTENUATION;
	float shade = clamp(toon_step(x * fb + jitter * 2.0, w) + 1.0, 0.0, fb) / fb;
	float shadow = LIGHT_IS_DIRECTIONAL
		? smoothstep(0.5 - shadow_softness, 0.5 + shadow_softness, ATTENUATION + jitter)
		: 1.0;
	float occl = LIGHT_IS_DIRECTIONAL ? shadow : ATTENUATION;

	DIFFUSE_LIGHT += LIGHT_COLOR / PI * shade * shadow;

	// Hard-edged highlight.
	vec3 h = normalize(LIGHT + VIEW);
	float nh = max(dot(NORMAL, h), 0.0);
	float spec_th = 1.0 - specular_size * 0.15;
	float spec = smoothstep(spec_th - v_edge_w, spec_th + v_edge_w, nh) * smoothstep(0.0, 0.1, ndl) * occl;
	SPECULAR_LIGHT += LIGHT_COLOR / PI * spec * specular_strength;

	// Lit-side rim.
	float rim_x = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	float rim_th = 1.0 - rim_width;
	float rim = smoothstep(rim_th - v_edge_w, rim_th + v_edge_w, rim_x) * smoothstep(0.0, 0.2, ndl) * occl;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * rim * rim_strength;
}
