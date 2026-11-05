extends RigidBody3D
class_name Pickup;

# Something a living player collects by touching it. Ghosts can't collect anything.
#   money_value   added to GameState.money
#   health_value  heals the player who picked it up
#   life_value    extra lives. In Death Counter mode lives don't matter, so it gives
#                 CharStats.DEATH_COUNTER_BONUS_MONEY per life instead (placeholder until that reward is decided).

@export var money_value := 0;
@export var health_value := 0;
@export var life_value := 0;

func _on_pickup_range_body_entered(body: Node3D) -> void:
  if !(body is PlayerCharacter) || !body.is_alive(): return;

  if money_value > 0: GameState.add_money(money_value);
  if health_value > 0: body.heal(health_value);
  for i in life_value:
    if GameState.death_counter_mode:
      GameState.add_money(CharStats.DEATH_COUNTER_BONUS_MONEY);
    else:
      GameState.add_life();
    #/if
  #/for
  #TODO: Glitter effect
  queue_free();
#/_on_pickup_range_body_entered
