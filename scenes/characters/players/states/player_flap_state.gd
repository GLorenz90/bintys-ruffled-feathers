extends PlayerState
class_name PlayerFlapState

# Wing flap: hold jump in the air to slow your fall. Starts with a small pop upward,
# then settles into a slow, steady descent. Ends on release, landing, or after FLAP_TIME.

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.can_flap = false;
  player.velocity.y = maxf(player.velocity.y, 0.0) + CharStats.FLAP_BOOST;
#/enter

func physics_update(delta: float) -> void:
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
