extends PlayerState
class_name PlayerDiveState

# Underwater. Hold jump to swim up, hold roll to swim down; let go of both and you bob back up.
# Air runs out over AIR_MAX seconds, then you lose a health every DROWN_DAMAGE_INTERVAL.
# Back at the surface you're floating again (PlayerSwimState), and air refills.

var _time_without_air := 0.0;

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.velocity.y = -CharStats.DIVE_START_SPEED;
  _time_without_air = 0.0;
#/enter

func physics_update(delta: float) -> void:
  if !player.env.is_in_water():
    player.return_to_neutral();
    return;
  #/if
  var floating_height := player.env.get_water_surface() - CharStats.SWIM_FLOAT_DEPTH;
  if player.global_position.y >= floating_height && player.velocity.y >= 0.0:
    player.change_state(Enums.PLAYER_STATES.SWIM);
    return;
  #/if

  player.move_horizontally(delta, CharStats.DIVE_SPEED, CharStats.SWIM_ACCELERATION, CharStats.SWIM_DECELERATION);
  player.turn_toward_input(delta);

  var vertical_target := CharStats.DIVE_BUOYANCY;
  if player.jump.held: vertical_target = CharStats.DIVE_VERTICAL_SPEED;
  if player.roll.held: vertical_target = -CharStats.DIVE_VERTICAL_SPEED;
  player.velocity.y = move_toward(player.velocity.y, vertical_target, CharStats.DIVE_VERTICAL_ACCELERATION * delta);

  player.env.use_air(delta);
  if player.env.air > 0.0: return;
  _time_without_air += delta;
  if _time_without_air >= CharStats.DROWN_DAMAGE_INTERVAL:
    _time_without_air = 0.0;
    player.drown();
  #/if
#/physics_update
