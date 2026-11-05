extends Area3D
class_name Hazard

# Hurts any living player standing in it (spikes, fire, nettles...). The player's invulnerability
# after a hit stops it from draining all their health at once.

@export var damage := 1;

func _ready() -> void:
  collision_layer = 16; # Hazard layer.
  collision_mask = 2;   # Player layer.
#/_ready

func _physics_process(_delta: float) -> void:
  for body in get_overlapping_bodies():
    if body is PlayerCharacter && body.is_alive(): body.hit(damage, global_position);
  #/for
#/_physics_process
