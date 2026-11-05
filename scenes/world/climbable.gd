extends Area3D
class_name Climbable

# A ladder or rope. Give it a CollisionShape3D covering where players can grab it.
#   LADDER: climbed from one side, the side this node's blue (+Z) axis points to. Up and down only.
#   ROPE:   climbed from any side. Left / right on the stick moves round the rope.
# It runs from this node's origin up to `height`. Reaching the top of a ladder climbs off onto it.

enum KINDS { LADDER, ROPE }

@export var kind: KINDS = KINDS.LADDER;
@export var height := 4.5;

func _ready() -> void:
  collision_layer = 0;
  collision_mask = 2; # Player layer.
  body_entered.connect(_on_body_entered);
  body_exited.connect(_on_body_exited);
#/_ready

func get_bottom_height() -> float:
  return global_position.y;
#/get_bottom_height

func get_top_height() -> float:
  return global_position.y + height;
#/get_top_height

# Flat direction a ladder is climbed from (points from the ladder toward the climber).
func get_front() -> Vector3:
  var front := global_basis.z;
  front.y = 0.0;
  return front.normalized();
#/get_front

# The vertical line the climber hangs from, at a given height.
func get_axis_point(at_height: float) -> Vector3:
  return Vector3(global_position.x, at_height, global_position.z);
#/get_axis_point

func _on_body_entered(body: Node3D) -> void:
  if body is PlayerCharacter: body.env.enter_climbable(self);
#/_on_body_entered

func _on_body_exited(body: Node3D) -> void:
  if body is PlayerCharacter: body.env.exit_climbable(self);
#/_on_body_exited
