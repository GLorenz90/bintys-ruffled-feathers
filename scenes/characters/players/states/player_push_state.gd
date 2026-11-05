extends PlayerState
class_name PlayerPushState

# Holding a PushBlock (player.env.grabbed_block). Stick toward it pushes, away from it pulls,
# always straight along the face you grabbed. Let go of the stick for PUSH_RELEASE_TIME, or jump / roll,
# to step away. Stops if the block is blocked or starts falling.

var _block: PushBlock;
var _axis := Vector3.ZERO; # Direction that counts as "pushing".
var _idle_time := 0.0;

func enter(_previous: Enums.PLAYER_STATES) -> void:
  _block = player.env.grabbed_block.block;
  _axis = -player.env.grabbed_block.normal;
  _idle_time = 0.0;
  player.velocity = Vector3.ZERO;
  player.face_direction(_axis);
#/enter

func physics_update(delta: float) -> void:
  if !is_instance_valid(_block) || !_block.is_resting() || !player.is_on_floor():
    player.return_to_neutral();
    return;
  #/if
  if player.try_ground_actions(): return;

  var along := player.get_move_direction().dot(_axis);
  if absf(along) < 0.3:
    _idle_time += delta;
    player.velocity = Vector3(0.0, player.velocity.y, 0.0);
    if _idle_time >= CharStats.PUSH_RELEASE_TIME: player.change_state(Enums.PLAYER_STATES.GROUNDED);
    player.apply_gravity(delta);
    return;
  #/if
  _idle_time = 0.0;

  var motion := _axis * signf(along) * CharStats.PUSH_SPEED * delta;
  var pulling := along < 0.0;
  var moved := false;
  if pulling:
    moved = player.can_move_by(motion) && _block.try_move(motion);
  else:
    moved = _block.try_move(motion);
  #/if

  var walk := motion / delta if moved else Vector3.ZERO;
  player.velocity = Vector3(walk.x, player.velocity.y, walk.z);
  player.face_direction(_axis);
  player.apply_gravity(delta);
#/physics_update
