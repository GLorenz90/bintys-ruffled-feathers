extends PlayerState
class_name PlayerDiveState

# Underwater. A dive first carries you fully under (DIVE_SUBMERGE_DEPTH). After that, hold roll (crouch)
# to swim down, hold jump to swim up, and let go of both to hold your depth.
# Swimming up to floating height puts you back on the surface.
# Air runs out over AIR_MAX seconds, then you lose a health every DROWN_DAMAGE_INTERVAL.
# Back at the surface you're floating again (PlayerSwimState), and air refills.

var _time_without_air := 0.0;
var _submerging := false; # Still on the way down from the surface.

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.velocity.y = -CharStats.DIVE_VERTICAL_SPEED;
  _time_without_air = 0.0;
  _submerging = true;
#/enter

func physics_update(delta: float) -> void:
  if !player.env.is_in_water():
    player.return_to_neutral();
    return;
  #/if
  var floating_height := player.env.get_water_surface() - CharStats.SWIM_FLOAT_DEPTH;
  if !_submerging && player.global_position.y >= floating_height && player.velocity.y >= 0.0:
    player.change_state(Enums.PLAYER_STATES.SWIM);
    return;
  #/if

  player.move_horizontally(delta, CharStats.DIVE_SPEED, CharStats.SWIM_ACCELERATION, CharStats.SWIM_DECELERATION);
  player.turn_toward_input(delta);

  var surface := player.env.get_water_surface();
  if _submerging && (player.global_position.y <= surface - CharStats.DIVE_SUBMERGE_DEPTH || player.is_on_floor()):
    _submerging = false;
  #/if

  var vertical_target := 0.0;
  if _submerging || player.roll.held: vertical_target = -CharStats.DIVE_VERTICAL_SPEED;
  if !_submerging && player.jump.held: vertical_target = CharStats.DIVE_VERTICAL_SPEED;
  player.velocity.y = move_toward(player.velocity.y, vertical_target, CharStats.DIVE_VERTICAL_ACCELERATION * delta);

  player.env.use_air(delta);
  if player.env.air > 0.0: return;
  _time_without_air += delta;
  if _time_without_air >= CharStats.DROWN_DAMAGE_INTERVAL:
    _time_without_air = 0.0;
    player.drown();
  #/if
#/physics_update
