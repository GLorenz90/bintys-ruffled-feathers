extends Area3D
class_name KillZone

# Instantly kills a living player who enters (bottomless pits, deep water before swimming exists).
# Ghosts pass through it.

func _ready() -> void:
  collision_layer = 16; # Hazard layer.
  collision_mask = 2;   # Player layer.
  body_entered.connect(_on_body_entered);
#/_ready

func _on_body_entered(body: Node3D) -> void:
  if body is PlayerCharacter: body.kill();
#/_on_body_entered
