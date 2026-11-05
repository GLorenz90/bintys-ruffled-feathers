extends Area3D
class_name WaterVolume

# A body of water. Give it a CollisionShape3D with a BoxShape3D; the top of the box is the surface.
# Players swim at the surface and dive under it (see the Swim and Dive player states).

@onready var _shape: CollisionShape3D = $Collision;

func _ready() -> void:
  collision_layer = 0;
  collision_mask = 2; # Player layer.
  body_entered.connect(_on_body_entered);
  body_exited.connect(_on_body_exited);
#/_ready

func get_surface_height() -> float:
  var box: BoxShape3D = _shape.shape;
  return _shape.global_position.y + box.size.y * 0.5 * _shape.global_basis.get_scale().y;
#/get_surface_height

func _on_body_entered(body: Node3D) -> void:
  if body is PlayerCharacter: body.env.enter_water(self);
#/_on_body_entered

func _on_body_exited(body: Node3D) -> void:
  if body is PlayerCharacter: body.env.exit_water(self);
#/_on_body_exited
