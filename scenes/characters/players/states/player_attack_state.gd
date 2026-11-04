extends PlayerState
class_name PlayerAttackState

# Placeholder melee until M3: alternates between two swings. Works on the ground and in the air.
# Once ATTACK_CHAIN_AFTER has passed, another attack, a jump or a roll can cut the swing short.

func enter(previous: Enums.PLAYER_STATES) -> void:
  if previous != Enums.PLAYER_STATES.ATTACK: player.attack_index = 0;
  player.snap_toward_input();
  player.spawn_swing(player.attack_index);
  player.attack_index += 1;
#/enter

func physics_update(delta: float) -> void:
  if time_in_state >= CharStats.ATTACK_CHAIN_AFTER:
    if player.attack.is_buffered():
      player.attack.consume();
      enter(Enums.PLAYER_STATES.ATTACK); # Next swing in the combo.
      time_in_state = 0.0;
      return;
    #/if
    if player.is_on_floor() && player.try_ground_actions(): return;
  #/if
  if time_in_state >= CharStats.ATTACK_TIME:
    player.return_to_neutral();
    return;
  #/if

  if player.is_on_floor():
    player.move_on_ground(delta, CharStats.ATTACK_MOVE_MULTIPLIER);
  else:
    player.move_in_air(delta);
  #/if
  var multiplier := CharStats.FALL_GRAVITY_MULTIPLIER if player.velocity.y <= 0.0 else 1.0;
  player.apply_gravity(delta, multiplier);
#/physics_update
