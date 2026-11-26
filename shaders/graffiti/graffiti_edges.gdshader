// graffiti_edges.gdshader
// One full-screen pass that draws all outlines:
//   * Character outlines: drawn OUTSIDE the figure, measured as a sub-pixel distance to the
//     character's edge, so they're smooth and anti-aliased at any width. Characters are found
//     through a tag written by toon_graffiti.gdshader (is_character = true).
//   * Environment silhouettes: thinner, drawn on the object's side.
//   * Details (creases and small depth steps): thin, fade with distance and at glancing angles.
//   * Overspray grain in the soft fringe of every stroke.
// Requires Godot 4.3+ with the Forward+ renderer (needs the normal-roughness buffer).
// Place at: res://shaders/graffiti/graffiti_edges.gdshader
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

#include "res://shaders/graffiti/graffiti_common.gdshaderinc"

uniform sampler2D depth_texture : hint_depth_texture, filter_linear, repeat_disable;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, filter_linear, repeat_disable;

group_uniforms character_outline;
uniform vec4 character_outline_color : source_color = vec4(0.05, 0.04, 0.08, 1.0);
uniform float character_outline_width : hint_range(0.0, 12.0) = 6.0;   // px at reference_distance
uniform float character_min_width : hint_range(0.0, 4.0) = 2.0;        // px, never thinner than this
uniform float character_outline_softness : hint_range(0.25, 3.0) = 1.2; // AA ramp, px
// A character part must be at least this much (metres) in front of another part of a
// character before it gets the thick outline over it. Stops arms getting thick outlines over
// their own body; a second character standing further back still gets outlined against.
uniform float character_overlap_gap = 0.5;
// 0 = clean anti-aliased outline. Raise for a sprayed fringe.
uniform float character_grain : hint_range(0.0, 1.0) = 0.0;

group_uniforms silhouette;
uniform vec4 silhouette_color : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform float silhouette_width : hint_range(0.0, 8.0) = 2.0;      // px at reference_distance
uniform float silhouette_threshold : hint_range(0.0, 0.5) = 0.04; // gap behind, relative to depth
uniform float silhouette_fade_start = 40.0;
uniform float silhouette_fade_end = 120.0;

group_uniforms details;
uniform vec4 detail_color : source_color = vec4(0.1, 0.08, 0.14, 0.85);
uniform float detail_width : hint_range(0.0, 4.0) = 1.25;
uniform float crease_threshold : hint_range(0.0, 1.0) = 0.25;      // 1 - cos(angle between normals)
uniform float step_threshold : hint_range(0.0, 0.2) = 0.008;
uniform float detail_fade_start = 8.0;
uniform float detail_fade_end = 30.0;
uniform float glancing_cutoff : hint_range(0.0, 1.0) = 0.25;

group_uniforms distance;
uniform float reference_distance = 4.0;   // full width at or nearer than this
uniform float min_width_scale : hint_range(0.05, 1.0) = 0.35;
uniform float max_line_distance = 200.0;

group_uniforms overspray;
uniform float grain_scale = 2.5;
uniform float speckle_scale = 70.0;
uniform float edge_overspray : hint_range(0.0, 1.0) = 0.25;
uniform float opacity_variation : hint_range(0.0, 0.5) = 0.08;
uniform float value_variation : hint_range(0.0, 0.5) = 0.1;
uniform float softness : hint_range(0.1, 1.0) = 0.7;
// Grain on scenery lines fades out over this range, leaving clean single lines in the distance.
uniform float grain_fade_start = 5.0;
uniform float grain_fade_end = 15.0;
group_uniforms;

// Must match the ROUGHNESS that toon_graffiti writes for characters.
const float CHARACTER_TAG = 0.5;

const vec2 TAPS8[8] = {
	vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
	vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071), vec2(0.7071, -0.7071), vec2(-0.7071, -0.7071)
};
const vec2 DIR12[12] = {
	vec2(1.0, 0.0), vec2(0.866025, 0.5), vec2(0.5, 0.866025), vec2(0.0, 1.0),
	vec2(-0.5, 0.866025), vec2(-0.866025, 0.5), vec2(-1.0, 0.0), vec2(-0.866025, -0.5),
	vec2(-0.5, -0.866025), vec2(0.0, -1.0), vec2(0.5, -0.866025), vec2(0.866025, -0.5)
};

vec3 view_pos(vec2 uv, mat4 inv_proj) {
	float raw = texture(depth_texture, uv).r;
	vec4 p = inv_proj * vec4(uv * 2.0 - 1.0, raw, 1.0);
	return p.xyz / p.w;
}

vec3 view_normal(vec2 uv) {
	return normalize(texture(normal_roughness_texture, uv).xyz * 2.0 - 1.0);
}

// 1 on characters, 0 elsewhere. Bilinear filtering gives a sub-pixel ramp across the edge,
// since environment (1.0) and sky (0.0) are both 0.5 away from the tag.
float char_mask(vec2 uv) {
	float w = texture(normal_roughness_texture, uv).w;
	return 1.0 - clamp(abs(w - CHARACTER_TAG) * 2.0, 0.0, 1.0);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / VIEWPORT_SIZE;
	mat4 ip = INV_PROJECTION_MATRIX;

	bool is_sky = texture(depth_texture, uv).r <= 0.0; // reverse-Z far plane
	vec3 p0 = view_pos(uv, ip);
	float d0 = -p0.z;
	float c0 = char_mask(uv);
	bool center_is_char = c0 > 0.5;

	// ------------------------------------------------------------------ character outline
	float char_a = 0.0;
	float char_depth = d0;
	float R = character_outline_width + character_outline_softness + 1.0;
	float gap = center_is_char ? max(character_overlap_gap, d0 * 0.02) : d0 * 0.02;

	// Cheap ring test first: most pixels are nowhere near a character.
	float near_char = 0.0;
	for (int i = 0; i < 12; i++) {
		near_char = max(near_char, char_mask(uv + DIR12[i] * R * px));
		near_char = max(near_char, char_mask(uv + DIR12[i] * R * 0.5 * px));
	}

	if (near_char > 0.0 || center_is_char) {
		// 1) Coarse: march outward in 12 directions to find roughly where the nearest
		//    "character in front of me" pixel is.
		float best = 1e6;
		vec2 best_off = vec2(0.0);
		int steps = int(ceil(R));
		for (int i = 0; i < 12; i++) {
			for (int s = 1; s <= steps; s++) {
				if (float(s) >= best) { break; }
				vec2 off = DIR12[i] * float(s);
				vec2 tuv = uv + off * px;
				float dt = -view_pos(tuv, ip).z;
				if (char_mask(tuv) * smoothstep(gap * 0.5, gap, d0 - dt) >= 0.5) {
					best = float(s);
					best_off = off;
					break;
				}
			}
		}
		// 2) Exact: search the 5x5 pixels around that hit for the true nearest character pixel.
		//    The outline edge is then a smooth offset curve, not the character's pixel staircase.
		if (best < 1e5) {
			ivec2 tex_size = textureSize(normal_roughness_texture, 0);
			ivec2 base = ivec2(uv * vec2(tex_size));
			ivec2 hit = base + ivec2(round(best_off));
			float exact = 1e6;
			for (int dy = -2; dy <= 2; dy++) {
				for (int dx = -2; dx <= 2; dx++) {
					ivec2 t = clamp(hit + ivec2(dx, dy), ivec2(0), tex_size - 1);
					float m = 1.0 - clamp(abs(texelFetch(normal_roughness_texture, t, 0).w - CHARACTER_TAG) * 2.0, 0.0, 1.0);
					if (m < 0.5) { continue; }
					vec2 tuv = (vec2(t) + 0.5) / vec2(tex_size);
					vec4 vp = ip * vec4(tuv * 2.0 - 1.0, texelFetch(depth_texture, t, 0).r, 1.0);
					float dt = -vp.z / vp.w;
					if (d0 - dt < gap * 0.75) { continue; }
					float d = length(vec2(t - base)) - 0.5; // to the pixel's edge, not its centre
					if (d < exact) { exact = d; char_depth = dt; }
				}
			}
			if (exact < 1e5) {
				float cs = clamp(reference_distance / char_depth, min_width_scale, 1.0);
				float wpx = max(character_outline_width * cs, character_min_width);
				float hs = character_outline_softness * 0.5;
				char_a = 1.0 - smoothstep(wpx - hs, wpx + hs, exact);
				char_a *= 1.0 - smoothstep(silhouette_fade_start, silhouette_fade_end, char_depth);
			}
		}

		// Inner edge: the character's own pixels are a staircase too. Measure exact distance to
		// the nearest background pixel and let the outline cover a smooth ~1px band inside.
		if (center_is_char) {
			ivec2 tex_size = textureSize(normal_roughness_texture, 0);
			ivec2 base = ivec2(uv * vec2(tex_size));
			float in_dist = 1e6;
			for (int dy = -2; dy <= 2; dy++) {
				for (int dx = -2; dx <= 2; dx++) {
					ivec2 t = clamp(base + ivec2(dx, dy), ivec2(0), tex_size - 1);
					float m = 1.0 - clamp(abs(texelFetch(normal_roughness_texture, t, 0).w - CHARACTER_TAG) * 2.0, 0.0, 1.0);
					vec2 tuv = (vec2(t) + 0.5) / vec2(tex_size);
					vec4 vp = ip * vec4(tuv * 2.0 - 1.0, texelFetch(depth_texture, t, 0).r, 1.0);
					float dt = -vp.z / vp.w;
					// Outside = not a character, and clearly behind us (so feet on the floor stay clean).
					if (m < 0.5 && dt - d0 > d0 * 0.03) {
						in_dist = min(in_dist, length(vec2(t - base)));
					}
				}
			}
			float in_a = 1.0 - smoothstep(0.6, 1.8, in_dist);
			in_a *= 1.0 - smoothstep(silhouette_fade_start, silhouette_fade_end, d0);
			if (in_a > char_a) { char_a = in_a; char_depth = d0; }
		}
	}

	// ------------------------------------------------------------------ environment + detail lines
	float sil = 0.0;
	float det = 0.0;
	vec3 n0 = view_normal(uv);
	if (!is_sky && d0 < max_line_distance) {
		float ndv = clamp(dot(n0, normalize(-p0)), 0.0, 1.0);
		float dist_scale = clamp(reference_distance / d0, min_width_scale, 1.0);
		float r_sil = silhouette_width * dist_scale;
		float r_det = detail_width * dist_scale;
		float sil_cov = clamp(r_sil, 0.0, 1.0);
		float det_cov = clamp(r_det, 0.0, 1.0);
		r_sil = max(r_sil, 1.0);
		r_det = max(r_det, 1.0);

		for (int i = 0; i < 8; i++) {
			// Environment silhouette (characters get the outer outline instead).
			if (!center_is_char) {
				vec2 suv = uv + TAPS8[i] * r_sil * px;
				vec3 ps = view_pos(suv, ip);
				vec3 ns = view_normal(suv);
				vec3 dp = ps - p0;
				float behind = (-ps.z - d0) / d0;
				float off_plane = max(abs(dot(dp, n0)), abs(dot(dp, ns))) / d0;
				sil = max(sil, smoothstep(silhouette_threshold, silhouette_threshold * 2.0, min(behind, off_plane)));
			}
			// Details: axis taps only.
			if (i < 4) {
				vec2 duv = uv + TAPS8[i] * r_det * px;
				vec3 pd = view_pos(duv, ip);
				vec3 nd = view_normal(duv);
				float crease = smoothstep(crease_threshold, crease_threshold * 1.6 + 0.02, 1.0 - dot(n0, nd));
				float stepd = smoothstep(step_threshold, step_threshold * 2.0, abs(dot(pd - p0, n0)) / d0);
				float we_are_behind = smoothstep(silhouette_threshold, silhouette_threshold * 2.0, (d0 + pd.z) / d0);
				det = max(det, max(crease, stepd) * (1.0 - we_are_behind));
			}
		}
		det *= det_cov
			* smoothstep(glancing_cutoff * 0.5, glancing_cutoff, ndv)
			* (1.0 - smoothstep(detail_fade_start, detail_fade_end, d0));
		sil *= sil_cov * (1.0 - smoothstep(silhouette_fade_start, silhouette_fade_end, d0));
	}

	float a_sil = sil * silhouette_color.a;
	float a_det = det * detail_color.a;
	float a_chr = char_a * character_outline_color.a;
	if (max(max(a_sil, a_det), a_chr) < 0.003) { discard; }

	// ------------------------------------------------------------------ overspray
	// Grain is anchored in world space; character outlines use the character's depth so the
	// grain sits with the character rather than the wall behind it.
	vec3 grain_view = p0 * (char_a > 0.0 ? char_depth / max(d0, 1e-4) : 1.0);
	float gd = -grain_view.z;
	vec3 wpos = (INV_VIEW_MATRIX * vec4(grain_view, 1.0)).xyz;
	float footprint = 2.0 * gd * px.y / PROJECTION_MATRIX[1][1];
	float mottle = gf_mottle(wpos, grain_scale);
	float speck = gf_speckle(wpos, speckle_scale, footprint) - 0.5;

	// Environment/detail strokes: grain in the fringe up close, clean lines in the distance.
	float near_grain = 1.0 - smoothstep(grain_fade_start, grain_fade_end, d0);
	float a_lines = max(a_sil, a_det);
	float fl = a_lines * (1.0 - a_lines) * 4.0;
	a_lines = clamp(a_lines + speck * edge_overspray * near_grain * fl, 0.0, 1.0);
	float soft_eff = mix(1.0, softness, near_grain); // no crisp-up on thin distant lines
	a_lines = smoothstep(0.5 - soft_eff * 0.5, 0.5 + soft_eff * 0.5, a_lines);
	a_lines *= 1.0 - mottle * opacity_variation * near_grain;
	vec3 col_lines = mix(detail_color.rgb, silhouette_color.rgb, a_sil / (a_sil + a_det + 1e-4));
	col_lines *= 1.0 + (mottle - 0.5) * 2.0 * value_variation * near_grain;

	// Character outline: analytic AA ramp; grain only if character_grain > 0.
	float fc = a_chr * (1.0 - a_chr) * 4.0;
	a_chr = clamp(a_chr + speck * character_grain * fc, 0.0, 1.0);
	a_chr *= 1.0 - mottle * opacity_variation * character_grain;

	float a = max(a_chr, a_lines);
	vec3 col = mix(col_lines, character_outline_color.rgb, a_chr / (a_chr + a_lines + 1e-4));

	ALBEDO = col;
	ALPHA = a;
}
