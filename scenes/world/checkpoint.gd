extends Area3D
class_name Checkpoint

# Touch it (while alive) to make it the respawn point. In co-op it also brings a ghost partner back.
# Players respawn either side of it, P1 on the left and P2 on the right (as seen facing its -Z).

const INACTIVE_COLOR := Color(0.45, 0.45, 0.5);
const ACTIVE_COLOR := Color(1.0, 0.85, 0.2);
const SPAWN_SIDE_OFFSET := 1.5;
# A touch only counts this close to the pole. When a level reloads, physics can briefly report a player
# who was standing here before the reload, even though they've already been moved to the spawn.
const TOUCH_RADIUS := 2.0;

var _flag_material := StandardMaterial3D.new();

func _ready() -> void:
  collision_layer = 0;
  collision_mask = 2; # Player layer.
  body_entered.connect(_on_body_entered);
  $Flag.material_override = _flag_material;
  set_active(false);
#/_ready

func set_active(active: bool) -> void:
  _flag_material.albedo_color = ACTIVE_COLOR if active else INACTIVE_COLOR;
#/set_active

func get_spawn_transform(player_id: int) -> Transform3D:
  var side := -SPAWN_SIDE_OFFSET if player_id == 1 else SPAWN_SIDE_OFFSET;
  return global_transform.translated_local(Vector3(side, 0.1, 0.0));
#/get_spawn_transform

func _on_body_entered(body: Node3D) -> void:
  if !(body is PlayerCharacter) || !body.is_alive(): return;
  if body.global_position.distance_to(global_position) > TOUCH_RADIUS: return;
  GameState.set_checkpoint(self);
  Signals.checkpoint_reached.emit(self, body);
#/_on_body_entered
