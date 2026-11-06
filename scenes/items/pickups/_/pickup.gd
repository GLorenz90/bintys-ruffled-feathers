extends RigidBody3D
class_name Pickup;

# Something a living player collects by touching it. Ghosts can't collect anything.
#   money_value   added to GameState.money
#   health_value  heals the player who picked it up
#   full_heal     heals them all the way instead
#   life_value    extra lives. In Death Counter mode lives don't matter, so it gives
#                 CharStats.DEATH_COUNTER_BONUS_MONEY per life instead (placeholder until that reward is decided).

@export var money_value := 0;
@export var health_value := 0;
@export var life_value := 0;
@export var full_heal := false;

@onready var _range: Area3D = $PickupRange;
var _collected := false;

# Checked every frame rather than only on touch, so standing on bread at full health and then
# getting hurt still lets you eat it.
func _physics_process(_delta: float) -> void:
  for body in _range.get_overlapping_bodies(): _try_collect(body);
#/_physics_process

func _on_pickup_range_body_entered(body: Node3D) -> void:
  _try_collect(body);
#/_on_pickup_range_body_entered

func _try_collect(body: Node3D) -> void:
  if _collected || !(body is PlayerCharacter) || !body.is_alive(): return;
  if _is_only_healing() && body.get_health() >= body.get_max_health(): return; # Leave it for later (or for your partner).

  if money_value > 0: GameState.add_money(money_value);
  if full_heal:
    body.heal(body.get_max_health());
  elif health_value > 0:
    body.heal(health_value);
  #/if
  for i in life_value:
    if GameState.death_counter_mode:
      GameState.add_money(CharStats.DEATH_COUNTER_BONUS_MONEY);
    else:
      GameState.add_life();
    #/if
  #/for
  #TODO: Glitter effect
  _collected = true;
  queue_free();
#/_try_collect

func _is_only_healing() -> bool:
  return (health_value > 0 || full_heal) && money_value == 0 && life_value == 0;
#/_is_only_healing
