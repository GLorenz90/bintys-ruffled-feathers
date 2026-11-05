extends CharacterBody3D
class_name PushBlock

# A heavy block players can push and pull along its own sides (never diagonally).
# It sits on the terrain layer, so you can stand on it, grab its ledges and the camera won't pass through it.
# It falls if pushed off an edge.

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity");

func _ready() -> void:
  collision_layer = 1;      # Terrain.
  collision_mask = 1 | 4;   # Terrain and enemies.
#/_ready

func _physics_process(delta: float) -> void:
  velocity = Vector3(0.0, 0.0 if is_on_floor() else velocity.y - _gravity * delta, 0.0);
  move_and_slide();
#/_physics_process

# Slides the block by `motion` if nothing's in the way (the floor it rests on doesn't count).
# Returns true if it moved.
func try_move(motion: Vector3) -> bool:
  var collision := move_and_collide(motion, true);
  if collision != null && absf(collision.get_normal().y) < 0.7: return false;
  global_position += motion;
  return true;
#/try_move

func is_resting() -> bool:
  return is_on_floor();
#/is_resting

# Turns any normal into the nearest of the block's four side directions, so pushing stays square.
func snap_to_face_normal(normal: Vector3) -> Vector3:
  var best := global_basis.x;
  for side in [global_basis.x, -global_basis.x, global_basis.z, -global_basis.z]:
    if side.dot(normal) > best.dot(normal): best = side;
  #/for
  best.y = 0.0;
  return best.normalized();
#/snap_to_face_normal
