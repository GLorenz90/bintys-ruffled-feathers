extends PlayerState
class_name PlayerLedgeClimbState

# Pulling up onto a ledge: straight up until our feet clear the top, then forward onto it.
# Takes LEDGE_CLIMB_TIME and can't be interrupted.

const RISE_SHARE := 0.6; # Fraction of the climb spent rising; the rest steps forward.

var _start := Vector3.ZERO;
var _above := Vector3.ZERO;
var _end := Vector3.ZERO;

func enter(_previous: Enums.PLAYER_STATES) -> void:
  var ledge: Dictionary = player.env.grabbed_ledge;
  var radius: float = player.SHAPE_NORMAL.radius;
  _start = player.global_position;
  _above = Vector3(_start.x, ledge.top.y + 0.05, _start.z);
  _end = ledge.top - ledge.normal * (radius + 0.1) + Vector3.UP * 0.05;
#/enter

func physics_update(_delta: float) -> void:
  player.velocity = Vector3.ZERO;
  var progress := clampf(time_in_state / CharStats.LEDGE_CLIMB_TIME, 0.0, 1.0);
  if progress < RISE_SHARE:
    player.global_position = _start.lerp(_above, smoothstep(0.0, 1.0, progress / RISE_SHARE));
  else:
    player.global_position = _above.lerp(_end, smoothstep(0.0, 1.0, (progress - RISE_SHARE) / (1.0 - RISE_SHARE)));
  #/if
  if progress >= 1.0: player.change_state(Enums.PLAYER_STATES.GROUNDED);
#/physics_update
