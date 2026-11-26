# Graffiti toon shader set

Toon shading with a spray-paint look, plus one full-screen pass for all outlines.
Tested in Godot 4.4.1 (Forward+) on a test scene: a critter built from basic shapes in a long alley.

**Requirements:** Godot 4.3+ with the **Forward+** renderer. The edge pass reads the normal-roughness screen buffer, which only Forward+ provides.

## Files (`res://shaders/graffiti/`)
- `toon_graffiti.gdshader`: material for every opaque mesh. It gives banded toon lighting with anti-aliased edges between light and shadow, and a dithered spray-dot fade on those edges and on cast shadows. It also adds fine colour grain and light colour mottling.
- `graffiti_edges.gdshader`: one full-screen pass that draws:
  - **Character outlines.** Thick (6 px up close, never thinner than 2 px), drawn outside the figure, and smoothly anti-aliased. The pass measures the true distance from each pixel to the nearest character pixel, so the edge is a smooth curve instead of a pixel staircase.
  - **Scenery outlines.** 2 px, drawn on the object's side. A plane-distance test keeps floors and walls seen edge-on from filling with lines.
  - **Detail lines.** Creases and small depth steps. They fade with distance (8–30 m by default) and at glancing angles.
  - **Grain on scenery and detail lines.** Present up close, faded out between 5 and 15 m, so distant lines are clean single strokes.
- `graffiti_common.gdshaderinc`: shared noise (value noise, speckle, hue shift, per-pixel dither).
- `graffiti_edge_overlay.gd`: add as a child of the Camera3D and assign a ShaderMaterial using `graffiti_edges.gdshader`. The script builds the full-screen quad.

## Setup
1. Put the toon material on every opaque mesh.
2. On character materials, tick **`is_character`**. On scenery materials, turn off `grain_in_object_space`, so the grain is seamless across tiled level pieces.
3. Keep the WorldEnvironment's ambient light low; `shadow_fill` provides the shadow colour.
4. Add the overlay node under the camera.

## How characters are found
The toon shader writes `ROUGHNESS = 0.5` on character materials and `1.0` on everything else. The shader's own lighting doesn't use roughness, and `SPECULAR = 0` turns off reflections. The edge pass reads the roughness value from Godot's normal-roughness buffer. In 4.4 the value is stored as-is, and moving objects store it the same way as static ones.

**Keep non-toon materials out of the 0.3–0.7 roughness range**, or they will be treated as characters.

## Key parameters
- **Character overlap:** a character part must be at least `character_overlap_gap` (0.5 m) in front of another character part to get the thick outline over it. An arm crossing its own body gets a thin detail line instead.
- **Spray fade:** `spray_fade` (toon shader) sets how wide the dithered fade is (0 = clean edge). The dither is fixed to the screen, which keeps it pixel-fine.
- **Character outline grain:** `character_grain` adds a sprayed fringe to character outlines; the default 0 keeps them clean.
- **Outline width and softness:** `character_outline_width` and `character_outline_softness` (anti-aliasing fade, 1.2 px).
- **Distant rooftops:** if rooftop lines against the sky look dotted far away, raise `min_width_scale` (e.g. to 0.45).
- **Shadow acne:** crisp shadow edges make acne more visible. If you see dashed shadow lines on a mesh, raise the light's shadow bias or `shadow_softness`.

## Known trade-offs
- **Feet:** the character outline fades where a character touches the floor, because the floor next to the feet is at almost the same depth.
- **Cost:** pixels near a character do about 250 texture reads each. The rest of the screen does about 40. If that becomes a problem, shrinking the 5×5 exact-distance searches to 3×3 roughly halves the extra cost.
- **Overlapping characters:** characters aren't individually identified. If two characters overlap at a similar depth (within `character_overlap_gap`), the front one gets no thick outline against the other.
