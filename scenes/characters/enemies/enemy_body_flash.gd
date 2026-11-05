extends RefCounted
class_name EnemyBodyFlash

# Shared by enemies: gives a mesh its own material and flashes it white for a moment when hit.

const FLASH_COLOR := Color(1.0, 1.0, 1.0);
const FLASH_TIME := 0.08;

var _material := StandardMaterial3D.new();
var _base_color: Color;

func _init(mesh: MeshInstance3D, base_color: Color) -> void:
  _base_color = base_color;
  _material.albedo_color = base_color;
  mesh.material_override = _material;
#/_init

func flash(owner_node: Node) -> void:
  _material.albedo_color = FLASH_COLOR;
  var tween := owner_node.create_tween();
  tween.tween_property(_material, "albedo_color", _base_color, FLASH_TIME).set_delay(FLASH_TIME);
#/flash
