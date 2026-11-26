@tool
extends MeshInstance3D
## Add as a child of your Camera3D and assign a ShaderMaterial using graffiti_edges.gdshader.
## Builds the full-screen quad the edge pass draws on.

@export var edge_material: ShaderMaterial:
	set(value):
		edge_material = value
		_apply()

func _ready() -> void:
	_apply()

func _apply() -> void:
	if not is_inside_tree():
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	quad.flip_faces = true
	mesh = quad
	extra_cull_margin = 16384.0  # never frustum-culled
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if edge_material:
		edge_material.render_priority = Material.RENDER_PRIORITY_MAX  # draw after other transparents
		material_override = edge_material
