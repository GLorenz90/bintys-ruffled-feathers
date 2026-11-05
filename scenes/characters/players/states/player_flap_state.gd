extends PlayerState
class_name PlayerFlapState

# Wing flap: slows your fall. Starts with a small pop upward, then settles into a slow, steady descent.
# Starts on its own if you're still holding jump at a jump's peak, or with a fresh jump press while falling.
# Ends on release, landing, or after FLAP_TIME. One flap per time in the air.

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.can_flap = false;
  player.velocity.y = maxf(player.velocity.y, 0.0) + CharStats.FLAP_BOOST;
#/enter

func physics_update(delta: float) -> void:
  if player.try_air_grabs(): return;
  if player.is_on_floor():
    player.change_state(Enums.PLAYER_STATES.GROUNDED);
    return;
  #/if
  if !player.jump.held || time_in_state >= CharStats.FLAP_TIME:
    player.change_state(Enums.PLAYER_STATES.FALL);
    return;
  #/if

  player.move_in_air(delta);
  player.turn_toward_input(delta);
  player.velocity.y = move_toward(player.velocity.y, -CharStats.FLAP_FALL_SPEED, CharStats.FLAP_SETTLE_RATE * delta);
#/physics_update
