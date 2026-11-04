extends Area3D
class_name CameraZone

# Drop one of these into a level and give it a CollisionShape3D. While a player stands inside,
# the camera following them uses these settings instead of its defaults, and lets go when they leave.
# Good for set pieces: a fixed side-on view, a top-down puzzle room, a wide boss arena.

## Lock the camera to the angle below (player steering is still allowed, then it eases back).
@export var fixed_angle := false;
@export_range(-180.0, 180.0) var yaw_degrees := 0.0;

@export var override_pitch := false;
@export_range(-89.0, 30.0) var pitch_degrees := -22.0;

@export var override_distance := false;
@export var distance := 9.0;

func _ready() -> void:
  collision_layer = 0;
  collision_mask = 2; # Player layer.
  body_entered.connect(_on_body_entered);
  body_exited.connect(_on_body_exited);
#/_ready

func _on_body_entered(body: Node3D) -> void:
  if body is PlayerCharacter: body.enter_camera_zone(self);
#/_on_body_entered

func _on_body_exited(body: Node3D) -> void:
  if body is PlayerCharacter: body.exit_camera_zone(self);
#/_on_body_exited
