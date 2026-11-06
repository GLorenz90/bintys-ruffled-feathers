extends PlayerState
class_name PlayerClimbState

# On a ladder or rope (player.env.grabbed_climbable).
#   Up / down on the stick climbs up / down, whatever the camera is doing.
#   Left / right on the stick moves round a rope (and does nothing on a ladder).
#   The top of a ladder climbs off onto whatever it leans on.
# If you grabbed it while holding down (walking into it toward the camera), down is ignored until you
# let the stick go back to the middle, so you don't climb straight back off.
#   Jump: leap off, away from it.   Roll: let go.

const LADDER_CLIMB_OFF_DISTANCE := 0.8; # How far past the top of a ladder you step when climbing off.
const TOP_MARGIN := 1.2;                # Feet stop this far below the top, so your head doesn't poke above it.
const STICK_THRESHOLD := 0.3;

var _climbable: Climbable;
var _height := 0.0;      # Feet height on the climbable.
var _rope_angle := 0.0;  # Where round the rope we are (radians).
var _ignore_down := false;

func enter(_previous: Enums.PLAYER_STATES) -> void:
  _climbable = player.env.grabbed_climbable;
  player.velocity = Vector3.ZERO;
  player.can_flap = true;
  player.carried_speed = 0.0;
  _height = clampf(player.global_position.y, _climbable.get_bottom_height(), _get_top_limit());

  var offset := player.global_position - _climbable.get_axis_point(player.global_position.y);
  _rope_angle = atan2(offset.x, offset.z);
  _ignore_down = _get_climb_input() < -STICK_THRESHOLD;
  _snap_to_climbable();
#/enter

func exit(_next: Enums.PLAYER_STATES) -> void:
  player.env.time_since_climb_exit = 0.0;
#/exit

func physics_update(delta: float) -> void:
  if player.jump.is_buffered():
    player.jump.consume();
    var away := _get_away_direction();
    player.velocity = away * CharStats.CLIMB_JUMP_AWAY_SPEED;
    player.face_direction(away);
    player.change_state(Enums.PLAYER_STATES.JUMP);
    return;
  #/if
  if player.roll.is_buffered():
    player.roll.consume();
    player.change_state(Enums.PLAYER_STATES.FALL);
    return;
  #/if

  var climb_input := _get_climb_input();
  if _ignore_down:
    if climb_input > -STICK_THRESHOLD: _ignore_down = false;
    climb_input = maxf(climb_input, 0.0);
  #/if
  _height += climb_input * CharStats.CLIMB_SPEED * delta;

  if _height > _get_top_limit():
    if _climbable.kind == Climbable.KINDS.LADDER:
      _climb_off_top();
      return;
    #/if
    _height = _get_top_limit();
  #/if
  if _height < _climbable.get_bottom_height():
    player.change_state(Enums.PLAYER_STATES.FALL); # Climbed off the bottom.
    return;
  #/if

  if _climbable.kind == Climbable.KINDS.ROPE: _rope_angle += player.move_input.x * CharStats.ROPE_ORBIT_SPEED * delta;
  player.velocity = Vector3.ZERO;
  _snap_to_climbable();
#/physics_update

func _snap_to_climbable() -> void:
  var away := _get_away_direction();
  var offset := CharStats.LADDER_OFFSET if _climbable.kind == Climbable.KINDS.LADDER else CharStats.ROPE_OFFSET;
  player.global_position = _climbable.get_axis_point(_height) + away * offset;
  player.face_direction(-away);
#/_snap_to_climbable

# Up on the stick is positive. (Raw stick, so the camera angle doesn't matter.)
func _get_climb_input() -> float:
  return -player.move_input.y;
#/_get_climb_input

# From the ladder or rope toward the climber.
func _get_away_direction() -> Vector3:
  if _climbable.kind == Climbable.KINDS.LADDER: return _climbable.get_front();
  return Vector3(sin(_rope_angle), 0.0, cos(_rope_angle));
#/_get_away_direction

func _get_top_limit() -> float:
  return _climbable.get_top_height() - TOP_MARGIN;
#/_get_top_limit

func _climb_off_top() -> void:
  var top := _climbable.get_axis_point(_climbable.get_top_height());
  player.global_position = top - _climbable.get_front() * LADDER_CLIMB_OFF_DISTANCE + Vector3.UP * 0.05;
  player.change_state(Enums.PLAYER_STATES.GROUNDED);
#/_climb_off_top
