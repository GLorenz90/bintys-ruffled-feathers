extends PlayerState
class_name PlayerAttackState

# The three-hit combo (CharStats.ATTACK_COMBO). Works on the ground and in the air.
# Press attack again once chain_after has passed to go to the next swing; the third is the finisher
# and the combo starts over after it. A jump or roll can also cut a swing short at that point.

func enter(previous: Enums.PLAYER_STATES) -> void:
  if previous != Enums.PLAYER_STATES.ATTACK: player.attack_index = 0;
  _start_swing();
#/enter

func physics_update(delta: float) -> void:
  var swing: Dictionary = CharStats.ATTACK_COMBO[player.attack_index];
  if time_in_state >= swing.chain_after:
    if player.attack.is_buffered() && player.attack_index < CharStats.ATTACK_COMBO.size() - 1:
      player.attack.consume();
      player.attack_index += 1;
      _start_swing();
      return;
    #/if
    if player.is_on_floor() && player.try_ground_actions(): return;
  #/if
  if time_in_state >= swing.time:
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

func _start_swing() -> void:
  time_in_state = 0.0;
  player.snap_toward_input();
  player.spawn_swing(player.attack_index);
#/_start_swing
