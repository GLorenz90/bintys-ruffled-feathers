extends PlayerState
class_name PlayerLedgeHangState

# Hanging from a ledge (player.env.grabbed_ledge).
#   Jump, or push toward the wall:   pull up onto it
#   Roll, or pull away from the wall: let go
#   Left / right:                     shimmy along it, as long as the ledge carries on

func enter(_previous: Enums.PLAYER_STATES) -> void:
  var ledge: Dictionary = player.env.grabbed_ledge;
  player.velocity = Vector3.ZERO;
  player.global_position = player.env.get_hang_position(ledge);
  player.face_direction(-ledge.normal);
  player.can_flap = true;
  player.carried_speed = 0.0;
#/enter

func physics_update(delta: float) -> void:
  var ledge: Dictionary = player.env.grabbed_ledge;
  var toward_wall: Vector3 = -ledge.normal;
  var right := toward_wall.cross(Vector3.UP);
  var stick := player.get_move_direction();
  var forward := stick.dot(toward_wall);
  var can_use_stick := time_in_state >= CharStats.LEDGE_DROP_DELAY;

  if player.jump.is_buffered() || (can_use_stick && forward > 0.6):
    player.jump.consume();
    player.change_state(Enums.PLAYER_STATES.LEDGE_CLIMB);
    return;
  #/if
  if player.roll.is_buffered() || (can_use_stick && forward < -0.6):
    player.roll.consume();
    player.env.time_since_ledge_drop = 0.0;
    player.change_state(Enums.PLAYER_STATES.FALL);
    return;
  #/if

  player.velocity = Vector3.ZERO;
  var side := stick.dot(right);
  if absf(side) > 0.3: _shimmy(right * side * CharStats.LEDGE_SHIMMY_SPEED * delta, toward_wall);
#/physics_update

# Moves along the ledge only if there's still a ledge to hold at the new spot.
func _shimmy(step: Vector3, toward_wall: Vector3) -> void:
  var next := player.env.find_ledge(player.global_position + step, toward_wall);
  if next.is_empty(): return;
  player.env.grabbed_ledge = next;
  player.global_position = player.env.get_hang_position(next);
#/_shimmy
