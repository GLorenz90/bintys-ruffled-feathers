extends PlayerState
class_name PlayerClimbState

# On a ladder or rope (player.env.grabbed_climbable).
#   Push toward it to climb up, away from it to climb down. This works whatever the camera angle, and
#   means walking into a ladder and keeping the stick held carries straight on up it.
#   The top of a ladder climbs off onto whatever it leans on.
#   Left / right (relative to the way you're facing) moves round a rope.
#   Jump: leap off, away from it.   Roll: let go.

const LADDER_CLIMB_OFF_DISTANCE := 0.8; # How far past the top of a ladder you step when climbing off.
const TOP_MARGIN := 1.2;                # Feet stop this far below the top, so your head doesn't poke above it.

var _climbable: Climbable;
var _height := 0.0;      # Feet height on the climbable.
var _rope_angle := 0.0;  # Where round the rope we are (radians).

func enter(_previous: Enums.PLAYER_STATES) -> void:
  _climbable = player.env.grabbed_climbable;
  player.velocity = Vector3.ZERO;
  player.can_flap = true;
  player.carried_speed = 0.0;
  _height = clampf(player.global_position.y, _climbable.get_bottom_height(), _get_top_limit());

  var offset := player.global_position - _climbable.get_axis_point(player.global_position.y);
  _rope_angle = atan2(offset.x, offset.z);
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

  var toward := -_get_away_direction();
  var right := toward.cross(Vector3.UP);
  var stick := player.get_move_direction();
  _height += stick.dot(toward) * CharStats.CLIMB_SPEED * delta;

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

  if _climbable.kind == Climbable.KINDS.ROPE: _rope_angle += stick.dot(right) * CharStats.ROPE_ORBIT_SPEED * delta;
  player.velocity = Vector3.ZERO;
  _snap_to_climbable();
#/physics_update

func _snap_to_climbable() -> void:
  var away := _get_away_direction();
  var offset := CharStats.LADDER_OFFSET if _climbable.kind == Climbable.KINDS.LADDER else CharStats.ROPE_OFFSET;
  player.global_position = _climbable.get_axis_point(_height) + away * offset;
  player.face_direction(-away);
#/_snap_to_climbable

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
