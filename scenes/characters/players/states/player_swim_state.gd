extends PlayerState
class_name PlayerSwimState

# Floating at the surface. Binty's a rubber duck: she bobs on top of the water.
#   Jump: leap out.   Roll: dive under (see PlayerDiveState).
# Walking out into shallow water ends it.

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.velocity.y *= 0.3; # Splash down softly.
  player.can_flap = true;
  player.carried_speed = 0.0;
#/enter

func physics_update(delta: float) -> void:
  if !player.env.is_in_water() || (player.is_on_floor() && player.env.get_depth() < CharStats.SWIM_ENTER_DEPTH * 0.5):
    player.return_to_neutral();
    return;
  #/if
  if player.jump.is_buffered():
    player.jump.consume();
    player.change_state(Enums.PLAYER_STATES.JUMP);
    return;
  #/if
  if player.roll.is_buffered():
    player.roll.consume();
    player.change_state(Enums.PLAYER_STATES.DIVE);
    return;
  #/if

  player.move_horizontally(delta, CharStats.SWIM_SPEED, CharStats.SWIM_ACCELERATION, CharStats.SWIM_DECELERATION);
  player.turn_toward_input(delta);
  var floating_height := player.env.get_water_surface() - CharStats.SWIM_FLOAT_DEPTH;
  player.velocity.y = (floating_height - player.global_position.y) * CharStats.SWIM_BOB_SHARPNESS;
#/physics_update
