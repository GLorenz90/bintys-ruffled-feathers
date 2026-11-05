extends PlayerState
class_name PlayerGroundedState

# Standing or running. Speed follows how far the stick is pushed.
# Walk into a ladder or rope to grab it; keep walking into a block to start pushing it.

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.can_flap = true;
  player.carried_speed = 0.0;
#/enter

func physics_update(delta: float) -> void:
  if !player.is_on_floor():
    player.change_state(Enums.PLAYER_STATES.FALL);
    return;
  #/if
  if player.try_ground_actions(): return;
  if player.try_ground_grabs(delta): return;

  player.move_on_ground(delta);
  player.turn_toward_input(delta);
  player.apply_gravity(delta);
#/physics_update
