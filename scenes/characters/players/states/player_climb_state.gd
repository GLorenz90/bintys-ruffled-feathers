extends PlayerState
class_name PlayerClimbState

# On a ladder or rope (player.env.grabbed_climbable).
#   Up / down on the stick climbs up / down, whatever the camera is doing.
#   Left / right on the stick moves round a rope (and does nothing on a ladder).
#   Jump: leap off, away from it.   Roll: let go.
#
# Getting on and off is never a snap:
#   - Grabbing from the ground or the air eases you onto it over CLIMB_MOUNT_TIME.
#   - Stepping onto a ladder from the top of what it leans on: out over the edge, then down onto it
#     (the ledge pull-up in reverse, over LEDGE_CLIMB_TIME).
#   - Climbing off the top of a ladder uses the ledge pull-up (PlayerLedgeClimbState).
# Whichever way you were holding the stick when you got on is ignored until you centre it, so you don't
# climb straight back off (walking into a ladder toward the camera holds "down", stepping on from the top
# away from the camera holds "up").

const TOP_MARGIN := 1.2;                # Feet stop this far below the top, so your head doesn't poke above it.
const STICK_THRESHOLD := 0.3;
const FROM_TOP_TOLERANCE := 0.3;        # Feet this close to (or above) a ladder's top means we're getting on from above.

var _climbable: Climbable;
var _height := 0.0;      # Feet height on the climbable.
var _rope_angle := 0.0;  # Where round the rope we are (radians).
var _ignored_direction := 0.0; # +1 ignores up, -1 ignores down, 0 ignores nothing.

# The ease onto the climbable: a path of points walked through over _mount_duration.
var _mount_path: Array[Vector3] = [];
var _mount_duration := 0.0;

#region STATE ======================================================================================
func enter(_previous: Enums.PLAYER_STATES) -> void:
  _climbable = player.env.grabbed_climbable;
  player.velocity = Vector3.ZERO;
  player.can_flap = true;
  player.carried_speed = 0.0;

  var start := player.global_position;
  var from_top := _climbable.kind == Climbable.KINDS.LADDER && start.y >= _climbable.get_top_height() - FROM_TOP_TOLERANCE;
  _height = _get_top_limit() if from_top else clampf(start.y, _climbable.get_bottom_height(), _get_top_limit());
  var offset := start - _climbable.get_axis_point(start.y);
  _rope_angle = atan2(offset.x, offset.z);

  var target := _get_climb_position();
  if from_top:
    _mount_path = [start, Vector3(target.x, start.y, target.z), target];
    _mount_duration = CharStats.LEDGE_CLIMB_TIME;
    _ignored_direction = 1.0;
  else:
    _mount_path = [start, target];
    _mount_duration = CharStats.CLIMB_MOUNT_TIME;
    _ignored_direction = -1.0;
  #/if
  player.face_direction(-_get_away_direction());
#/enter

func exit(_next: Enums.PLAYER_STATES) -> void:
  player.env.time_since_climb_exit = 0.0;
#/exit

func physics_update(delta: float) -> void:
  player.velocity = Vector3.ZERO;
  if time_in_state < _mount_duration:
    _follow_mount_path(time_in_state / _mount_duration);
    return;
  #/if

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

  _height += _get_filtered_climb_input() * CharStats.CLIMB_SPEED * delta;
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
  player.global_position = _get_climb_position();
  player.face_direction(-_get_away_direction());
#/physics_update
#endregion =========================================================================================

#region HELPERS ====================================================================================
# Up on the stick is positive. (Raw stick, so the camera angle doesn't matter.)
func _get_climb_input() -> float:
  return -player.move_input.y;
#/_get_climb_input

# The climb input, minus whichever direction is being ignored until the stick is centred.
func _get_filtered_climb_input() -> float:
  var climb_input := _get_climb_input();
  if _ignored_direction == 0.0: return climb_input;
  if climb_input * _ignored_direction < STICK_THRESHOLD:
    _ignored_direction = 0.0;
    return climb_input;
  #/if
  return 0.0;
#/_get_filtered_climb_input

# Walks the mount path with an ease in / ease out, splitting the time between the segments by length.
func _follow_mount_path(progress: float) -> void:
  var total := 0.0;
  for i in _mount_path.size() - 1: total += _mount_path[i].distance_to(_mount_path[i + 1]);
  if total < 0.001:
    player.global_position = _mount_path.back();
    return;
  #/if

  var distance := smoothstep(0.0, 1.0, progress) * total;
  for i in _mount_path.size() - 1:
    var length := _mount_path[i].distance_to(_mount_path[i + 1]);
    if distance <= length || i == _mount_path.size() - 2:
      player.global_position = _mount_path[i].lerp(_mount_path[i + 1], clampf(distance / maxf(length, 0.001), 0.0, 1.0));
      return;
    #/if
    distance -= length;
  #/for
#/_follow_mount_path

# Where the player hangs at the current height (and, on a rope, angle).
func _get_climb_position() -> Vector3:
  var offset := CharStats.LADDER_OFFSET if _climbable.kind == Climbable.KINDS.LADDER else CharStats.ROPE_OFFSET;
  return _climbable.get_axis_point(_height) + _get_away_direction() * offset;
#/_get_climb_position

# From the ladder or rope toward the climber.
func _get_away_direction() -> Vector3:
  if _climbable.kind == Climbable.KINDS.LADDER: return _climbable.get_front();
  return Vector3(sin(_rope_angle), 0.0, cos(_rope_angle));
#/_get_away_direction

func _get_top_limit() -> float:
  return _climbable.get_top_height() - TOP_MARGIN;
#/_get_top_limit

# The ledge pull-up, with the top of the ladder as the ledge.
func _climb_off_top() -> void:
  player.env.grabbed_ledge = {
    "top": _climbable.get_axis_point(_climbable.get_top_height()),
    "normal": _climbable.get_front(),
  };
  player.change_state(Enums.PLAYER_STATES.LEDGE_CLIMB);
#/_climb_off_top
#endregion =========================================================================================
